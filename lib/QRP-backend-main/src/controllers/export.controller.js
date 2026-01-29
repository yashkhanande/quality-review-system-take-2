import ExcelJS from "exceljs";
import mongoose from "mongoose";
import { User } from "../models/user.models.js";
import Project from "../models/project.models.js";
import Stage from "../models/stage.models.js";
import { Role } from "../models/roles.models.js";
import ProjectMembership from "../models/projectMembership.models.js";
import Checkpoint from "../models/checkpoint.models.js";
import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiError } from "../utils/ApiError.js";

/**
 * MASTER EXCEL EXPORT CONTROLLER
 * Generates a comprehensive multi-sheet Excel file for PowerBI analysis
 * Contains all project data, stages, roles, members, checkpoints, and derived defects
 */

// Helper: Safe value extraction (avoid undefined, use null/"")
const safeValue = (val, defaultVal = "") => {
  if (val === null || val === undefined) return defaultVal;
  if (typeof val === "boolean") return val;
  return val;
};

// Helper: Add sheet with headers
const addSheetWithHeaders = (workbook, sheetName, columns) => {
  const sheet = workbook.addWorksheet(sheetName);
  const headerRow = sheet.addRow(columns);

  // Style headers
  headerRow.eachCell((cell) => {
    cell.font = { bold: true, color: { argb: "FFFFFFFF" } };
    cell.fill = {
      type: "pattern",
      pattern: "solid",
      fgColor: { argb: "FF366092" },
    };
    cell.alignment = {
      horizontal: "center",
      vertical: "center",
      wrapText: true,
    };
  });

  // Auto-fit columns
  sheet.columns.forEach((col) => {
    let maxLength = 15;
    col.eachCell({ includeEmpty: true }, (cell) => {
      if (cell.value) {
        const cellLength = cell.value.toString().length;
        if (cellLength > maxLength) maxLength = cellLength;
      }
    });
    col.width = Math.min(maxLength + 2, 50);
  });

  return sheet;
};

/**
 * GET /admin/export/master-excel
 * Main export endpoint - generates master Excel file with all data
 */
export const exportMasterExcel = asyncHandler(async (req, res) => {
  try {
    console.log("📊 Starting Master Excel export...");

    // Fetch all data in parallel
    const [
      users,
      projects,
      stages,
      roles,
      memberships,
      checklists,
      checkpoints,
    ] = await Promise.all([
      User.find().lean(),
      Project.find().populate("created_by", "name email").lean(),
      Stage.find().lean(),
      Role.find().lean(),
      ProjectMembership.find().populate(["user_id", "role"]).lean(),
      mongoose
        .model("Checklist")
        .find()
        .populate("created_by", "name email")
        .lean(),
      Checkpoint.find().populate("checklistId").lean(),
    ]);

    console.log(
      `✓ Fetched ${users.length} users, ${projects.length} projects, ${stages.length} stages, ${checklists.length} checklists, ${checkpoints.length} checkpoints`,
    );

    // Create lookup maps for faster access
    const userMap = new Map(users.map((u) => [u._id?.toString(), u]));
    const projectMap = new Map(projects.map((p) => [p._id?.toString(), p]));
    const stageMap = new Map(stages.map((s) => [s._id?.toString(), s]));
    const checklistMap = new Map(checklists.map((c) => [c._id?.toString(), c]));

    // Create role-based user maps for each project
    const projectExecutorMap = new Map(); // project_id -> user_name
    const projectReviewerMap = new Map(); // project_id -> user_name
    const projectSDHMap = new Map(); // project_id -> user_name

    memberships.forEach((membership) => {
      const projectId = membership.project_id?.toString();
      const userName = membership.user_id?.name || "";
      const roleName = membership.role?.role_name?.toLowerCase() || "";

      if (roleName.includes("executor")) {
        projectExecutorMap.set(projectId, userName);
      } else if (roleName.includes("reviewer")) {
        projectReviewerMap.set(projectId, userName);
      } else if (roleName.includes("sdh")) {
        projectSDHMap.set(projectId, userName);
      }
    });

    // Create workbook with SINGLE SHEET ONLY
    const workbook = new ExcelJS.Workbook();

    // Main Sheet: Comprehensive Project Data with Dynamic Phases
    const mainSheet = workbook.addWorksheet("Project Checklist Data");

    // Build dynamic headers based on maximum number of phases
    const maxPhases = Math.max(
      ...projects.map((p) => {
        const projectStages = stages.filter(
          (s) => s.project_id?.toString() === p._id?.toString(),
        );
        return projectStages.length;
      }),
      1,
    );

    const baseHeaders = [
      "Year",
      "Task",
      "SDH",
      "CreatedDate",
      "SubjectOrTitle",
      "Executor",
      "Reviewer",
    ];

    const phaseHeaders = [];
    for (let i = 1; i <= maxPhases; i++) {
      phaseHeaders.push(
        `Phase ${i} - Defect Category`,
        `Phase ${i} - C/NC`,
        `Remark - Phase ${i}`,
      );
    }

    const endHeaders = ["Created By", "Project Status"];
    const allHeaders = [...baseHeaders, ...phaseHeaders, ...endHeaders];

    // Add headers with styling
    const headerRow = mainSheet.addRow(allHeaders);
    headerRow.eachCell((cell) => {
      cell.font = { bold: true, color: { argb: "FFFFFFFF" } };
      cell.fill = {
        type: "pattern",
        pattern: "solid",
        fgColor: { argb: "FF366092" },
      };
      cell.alignment = {
        horizontal: "center",
        vertical: "center",
        wrapText: true,
      };
    });

    // Set column widths
    mainSheet.columns.forEach((col, idx) => {
      if (idx < 2)
        col.width = 12; // Year, Task
      else if (idx < baseHeaders.length)
        col.width = 18; // SDH, Date, Subject, Executor, Reviewer
      else if (idx >= baseHeaders.length + phaseHeaders.length)
        col.width = 18; // Created By, Status
      else col.width = 22; // Phase columns
    });

    // Process each project and its checkpoints
    for (const project of projects) {
      const projectId = project._id?.toString();
      const projectStages = stages
        .filter((s) => s.project_id?.toString() === projectId)
        .sort((a, b) => {
          const aNum = parseInt(a.stage_name?.match(/\d+/)?.[0] || "0");
          const bNum = parseInt(b.stage_name?.match(/\d+/)?.[0] || "0");
          return aNum - bNum;
        });

      const projectChecklists = checklists.filter((c) => {
        const stageId = c.stage_id?.toString();
        return projectStages.some((s) => s._id?.toString() === stageId);
      });

      const projectCheckpoints = checkpoints.filter((cp) => {
        const checklistId =
          cp.checklistId?._id?.toString() || cp.checklistId?.toString();
        return projectChecklists.some((c) => c._id?.toString() === checklistId);
      });

      console.log(
        `Project ${project.project_name}: ${projectCheckpoints.length} checkpoints, ${projectStages.length} stages`,
      );

      // If no checkpoints, add at least one row for the project
      if (projectCheckpoints.length === 0) {
        const rowData = [
          safeValue(new Date(project.createdAt).getFullYear()),
          safeValue(project.project_name),
          safeValue(projectSDHMap.get(projectId)),
          safeValue(
            project.createdAt
              ? new Date(project.createdAt).toISOString().split("T")[0]
              : "",
          ),
          safeValue(project.description || project.project_name),
          safeValue(projectExecutorMap.get(projectId)),
          safeValue(projectReviewerMap.get(projectId)),
        ];

        // Add empty phase data
        for (let i = 0; i < maxPhases; i++) {
          rowData.push("", "", "");
        }

        rowData.push(
          safeValue(project.created_by?.name || project.created_by?.email),
          safeValue(project.status),
        );

        mainSheet.addRow(rowData);
      } else {
        // Add a row for each checkpoint
        for (const checkpoint of projectCheckpoints) {
          const checklistId =
            checkpoint.checklistId?._id?.toString() ||
            checkpoint.checklistId?.toString();
          const checklist = checklistMap.get(checklistId);
          const stageId = checklist?.stage_id?.toString();
          const stage = stages.find((s) => s._id?.toString() === stageId);

          // Determine phase number from stage
          const phaseMatch = stage?.stage_name?.match(/\d+/);
          const phaseNumber = phaseMatch ? parseInt(phaseMatch[0]) : 0;

          // DEBUG: Log checkpoint data structure
          console.log(
            `  Checkpoint: ${checkpoint.question?.substring(0, 30)}... Phase: ${phaseNumber}, Stage: ${stage?.stage_name}`,
          );
          console.log(`    categoryId: ${checkpoint.categoryId}`);
          console.log(
            `    defect.categoryId: ${checkpoint.defect?.categoryId}`,
          );
          console.log(`    defect.severity: ${checkpoint.defect?.severity}`);
          console.log(
            `    defect.isDetected: ${checkpoint.defect?.isDetected}`,
          );
          console.log(
            `    executorResponse.answer: ${checkpoint.executorResponse?.answer}`,
          );
          console.log(
            `    executorResponse.remark: ${checkpoint.executorResponse?.remark}`,
          );
          console.log(
            `    reviewerResponse.answer: ${checkpoint.reviewerResponse?.answer}`,
          );
          console.log(
            `    reviewerResponse.remark: ${checkpoint.reviewerResponse?.remark}`,
          );

          const rowData = [
            safeValue(new Date(project.createdAt).getFullYear()),
            safeValue(checkpoint.question || "N/A"),
            safeValue(projectSDHMap.get(projectId)),
            safeValue(
              checkpoint.createdAt
                ? new Date(checkpoint.createdAt).toISOString().split("T")[0]
                : "",
            ),
            safeValue(project.project_name),
            safeValue(projectExecutorMap.get(projectId)),
            safeValue(projectReviewerMap.get(projectId)),
          ];

          // Add phase data - fill all phases
          for (let i = 1; i <= maxPhases; i++) {
            if (i === phaseNumber && phaseNumber > 0) {
              // This is the current phase for this checkpoint
              const defectCategory =
                checkpoint.defect?.categoryId || checkpoint.categoryId || "";

              // Determine C/NC based on defect or executor response
              let cOrNC = "";
              if (checkpoint.defect?.isDetected) {
                cOrNC = checkpoint.defect?.severity || "Non-Critical";
              } else if (checkpoint.executorResponse?.answer === true) {
                cOrNC = "C";
              } else if (checkpoint.executorResponse?.answer === false) {
                cOrNC = "NC";
              } else if (checkpoint.reviewerResponse?.answer === true) {
                cOrNC = "C";
              } else if (checkpoint.reviewerResponse?.answer === false) {
                cOrNC = "NC";
              }

              const remark =
                checkpoint.executorResponse?.remark ||
                checkpoint.reviewerResponse?.remark ||
                "";

              console.log(
                `    Phase ${i} data: Category="${defectCategory}", C/NC="${cOrNC}", Remark="${remark?.substring(0, 20)}"`,
              );

              rowData.push(
                safeValue(defectCategory),
                safeValue(cOrNC),
                safeValue(remark),
              );
            } else {
              rowData.push("", "", "");
            }
          }

          rowData.push(
            safeValue(
              checklist?.created_by?.name ||
                checklist?.created_by?.email ||
                project.created_by?.name,
            ),
            safeValue(project.status),
          );

          mainSheet.addRow(rowData);
        }
      }
    }

    // Write to buffer
    const buffer = await workbook.xlsx.writeBuffer();

    // Set response headers for download
    res.setHeader(
      "Content-Type",
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    );
    res.setHeader(
      "Content-Disposition",
      `attachment; filename="master_export_${new Date().toISOString().split("T")[0]}_${Date.now()}.xlsx"`,
    );
    res.setHeader("Content-Length", buffer.length);

    console.log(
      `✓ Master Excel export completed. File size: ${buffer.length} bytes`,
    );
    res.send(buffer);
  } catch (error) {
    console.error("❌ Export error:", error);
    throw error;
  }
});
