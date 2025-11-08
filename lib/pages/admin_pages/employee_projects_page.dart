import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/projects_controller.dart';
import '../../models/team_member.dart';
import '../../models/project.dart';

class EmployeeProjectsPage extends StatelessWidget {
  final TeamMember member;
  const EmployeeProjectsPage({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    final projectsCtrl = Get.find<ProjectsController>();
    // Gather projects by executor and assignee
    final executorProjects = projectsCtrl.byExecutor(member.name);
    final assignedProjects = projectsCtrl.byAssigneeId(member.id);

    bool isCompleted(Project p) => p.status.toLowerCase() == 'completed';
    var current = <Project>{
      ...executorProjects.where((p) => !isCompleted(p)),
      ...assignedProjects.where((p) => !isCompleted(p)),
    }.toList();
    var completed = <Project>{
      ...executorProjects.where(isCompleted),
      ...assignedProjects.where(isCompleted),
    }.toList();

    // Add dummy projects for now if none exist for this member
    if (current.isEmpty && completed.isEmpty) {
      current = _dummyProjects(member, count: 3, status: 'In Progress');
      completed = _dummyProjects(member, count: 2, status: 'Completed');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(member.name),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Get.back()),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final content = isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _ProjectListSection(
                        title: 'Current Projects',
                        projects: current,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _ProjectListSection(
                        title: 'Completed Projects',
                        projects: completed,
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProjectListSection(title: 'Current Projects', projects: current),
                    const SizedBox(height: 24),
                    _ProjectListSection(title: 'Completed Projects', projects: completed),
                  ],
                );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Projects for ${member.name}', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 24),
                content,
              ],
            ),
          );
        },
      ),
    );
  }

  List<Project> _dummyProjects(TeamMember m, {required int count, required String status}) {
    final now = DateTime.now();
    return List.generate(count, (i) {
      return Project(
  id: 'd_${m.id}_$status$i',
        title: status == 'Completed'
            ? 'Completed Task ${i + 1}'
            : 'Ongoing Task ${i + 1}',
        description: 'Auto-generated $status project for ${m.name}.',
        started: now.subtract(Duration(days: 10 * (i + 1))),
        priority: (i % 3 == 0) ? 'High' : (i % 3 == 1) ? 'Medium' : 'Low',
        status: status,
        executor: m.name,
        assignedEmployees: [m.id],
      );
    });
  }
}

class _ProjectListSection extends StatelessWidget {
  final String title;
  final List<Project> projects;
  const _ProjectListSection({required this.title, required this.projects});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${projects.length}', style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (projects.isEmpty)
              const Text('None')
            else
              Column(
                children: [
                  for (final p in projects) _ProjectTile(project: p),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  final Project project;
  const _ProjectTile({required this.project});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(project.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  project.status,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey.shade600),
        ],
      ),
    );
  }
}
