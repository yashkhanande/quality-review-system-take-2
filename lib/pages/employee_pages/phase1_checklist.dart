import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'checklist_controller.dart';
import '../../controllers/auth_controller.dart';

enum UploadStatus { pending, uploading, success, failed }

class ImageUploadState {
  UploadStatus status;
  double progress;
  Object? cancelToken; // keep flexible to avoid hard dependency
  ImageUploadState({
    this.status = UploadStatus.pending,
    this.progress = 0.0,
    this.cancelToken,
  });
}

class Question {
  final String mainQuestion;
  final List<String> subQuestions;
  Question({required this.mainQuestion, required this.subQuestions});
}

class QuestionsScreen extends StatefulWidget {
  final String projectId;
  final String projectTitle;
  final List<String> leaders;
  final List<String> reviewers;
  final List<String> executors;

  const QuestionsScreen({
    super.key,
    required this.projectId,
    required this.projectTitle,
    required this.leaders,
    required this.reviewers,
    required this.executors,
  });

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  final Map<String, Map<String, dynamic>> executorAnswers = {};
  final Map<String, Map<String, dynamic>> reviewerAnswers = {};
  final Set<int> executorExpanded = {};
  final Set<int> reviewerExpanded = {};
  late final ChecklistController checklistCtrl;
  bool _isLoadingData = true;

  final List<Question> checklist = [
    Question(
      mainQuestion: "Verification",
      subQuestions: [
        "Original BDF available?",
        "Revised input file checked?",
        "Description correct?",
      ],
    ),
    Question(
      mainQuestion: "Geometry Preparation",
      subQuestions: [
        "Is imported geometry correct (units/required data)?",
        "Required splits for pre- and post-processing?",
        "Required splits for bolted joint procedure?",
        "Geometry correctly defeatured?",
      ],
    ),
    Question(
      mainQuestion: "Coordinate Systems",
      subQuestions: ["Is correct coordinate system created and assigned?"],
    ),
    Question(
      mainQuestion: "FE Mesh",
      subQuestions: [
        "Is BDF exported with comments?",
        "Are Components, Properties, LBC, Materials renamed appropriately?",
        "Visual check of FE model (critical locations, transitions)?",
        "Nastran Model Checker run?",
        "Element quality report available?",
      ],
    ),
    Question(
      mainQuestion: "Solid Mesh",
      subQuestions: [
        "Correct element type and properties?",
        "Face of solid elements checked (for internal crack)?",
      ],
    ),
    Question(
      mainQuestion: "Shell Mesh",
      subQuestions: [
        "Free edges handled?",
        "Correct element type and properties?",
        "Shell normals correct?",
        "Shell thickness defined?",
        "Weld thickness/material correctly assigned?",
      ],
    ),
    Question(
      mainQuestion: "Beam Elements",
      subQuestions: [
        "Is the orientation and cross-section correct?",
        "Are correct nodes used to create beam elements?",
        "Number of beam elements appropriate?",
      ],
    ),
    Question(
      mainQuestion: "Rigids (RBE2/RBE3)",
      subQuestions: ["Rigid elements defined correctly?"],
    ),
    Question(
      mainQuestion: "Joints",
      subQuestions: [
        "Bolted joints defined?",
        "Welds defined?",
        "Shrink fit applied?",
        "Merged regions correct?",
      ],
    ),
    Question(
      mainQuestion: "Mass & Weight",
      subQuestions: [
        "Total weight cross-checked with model units?",
        "Point masses defined?",
        "COG location correct?",
        "Connection to model verified?",
      ],
    ),
    Question(
      mainQuestion: "Material Properties",
      subQuestions: [
        "E modulus verified?",
        "Poisson coefficient verified?",
        "Shear modulus verified?",
        "Density verified?",
      ],
    ),
    Question(
      mainQuestion: "Boundary Conditions",
      subQuestions: [
        "Correct DOFs assigned?",
        "Correct coordinate system assigned?",
      ],
    ),
    Question(
      mainQuestion: "Loading",
      subQuestions: [
        "Pressure load applied correctly?",
        "End loads/Total load defined?",
        "Gravity load applied?",
        "Force (point load) applied?",
        "Temperature load applied?",
        "Subcases defined (operating, lifting, wind, seismic, etc.)?",
      ],
    ),
    Question(
      mainQuestion: "Subcases",
      subQuestions: [
        "Subcase I: Definition, load, SPC ID, output request?",
        "Subcase II: Definition, load, SPC ID, output request?",
        "Subcase III: Definition, load, SPC ID, output request?",
        "Subcase IV: Definition, load, SPC ID, output request?",
      ],
    ),
    Question(
      mainQuestion: "Parameters",
      subQuestions: [
        "Param,post,-1 (op2 output)?",
        "Param,prgpst,no?",
        "Param,Ogeom,no?",
        "NASTRAN BUFFSIZE set for large models?",
        "Nastran system(151)=1 for large models?",
      ],
    ),
    Question(
      mainQuestion: "Oloads",
      subQuestions: [
        "Oload verification for Subcase I?",
        "Oload verification for Subcase II?",
        "Oload verification for Subcase III?",
        "Oload verification for Subcase IV?",
      ],
    ),
    Question(
      mainQuestion: "SPC",
      subQuestions: [
        "SPC resultant verified for Subcase I?",
        "SPC resultant verified for Subcase II?",
        "SPC resultant verified for Subcase III?",
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    print('🔷 QuestionsScreen.initState() for project: ${widget.projectId}');
    checklistCtrl = Get.isRegistered<ChecklistController>()
        ? Get.find<ChecklistController>()
        : Get.put(ChecklistController());

    print('✓ ChecklistController obtained: ${checklistCtrl.runtimeType}');

    // Load existing answers from backend for both executor and reviewer
    _loadChecklistData();
  }

  Future<void> _loadChecklistData() async {
    setState(() {
      _isLoadingData = true;
    });

    const phase = 1; // Phase 1
    print('🔄 Loading checklist data for project: ${widget.projectId}');

    // Clear cache to force fresh load from backend
    checklistCtrl.clearProjectCache(widget.projectId);

    await Future.wait([
      checklistCtrl.loadAnswers(widget.projectId, phase, 'executor'),
      checklistCtrl.loadAnswers(widget.projectId, phase, 'reviewer'),
    ]);

    // Populate UI with loaded answers
    final executorSheet = checklistCtrl.getRoleSheet(
      widget.projectId,
      phase,
      'executor',
    );
    final reviewerSheet = checklistCtrl.getRoleSheet(
      widget.projectId,
      phase,
      'reviewer',
    );

    print('✓ Loaded ${executorSheet.length} executor answers');
    print('✓ Loaded ${reviewerSheet.length} reviewer answers');

    setState(() {
      executorAnswers.clear();
      executorAnswers.addAll(executorSheet);

      reviewerAnswers.clear();
      reviewerAnswers.addAll(reviewerSheet);

      _isLoadingData = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine current user role permissions from provided lists
    String? currentUserName;
    if (Get.isRegistered<AuthController>()) {
      final auth = Get.find<AuthController>();
      currentUserName = auth.currentUser.value?.name;
    }
    final canEditExecutor =
        currentUserName != null &&
        widget.executors
            .map((e) => e.trim().toLowerCase())
            .contains(currentUserName.trim().toLowerCase());
    final canEditReviewer =
        currentUserName != null &&
        widget.reviewers
            .map((e) => e.trim().toLowerCase())
            .contains(currentUserName.trim().toLowerCase());
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Checklist - ${widget.projectTitle}",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Reload checklist data',
            onPressed: _isLoadingData
                ? null
                : () {
                    print('🔄 Manual refresh triggered');
                    // Clear cache and reload
                    checklistCtrl.clearProjectCache(widget.projectId);
                    _loadChecklistData();
                  },
          ),
        ],
      ),
      body: _isLoadingData
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading checklist data...'),
                ],
              ),
            )
          : SafeArea(
              child: Row(
                children: [
                  // Executor Column
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          color: Colors.blue.shade100,
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Executor Section",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (!canEditExecutor)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black12,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'View only',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        _SubmitBar(
                          role: 'executor',
                          projectId: widget.projectId,
                          phase: 1,
                          onSubmit: () async {
                            if (!canEditExecutor) return;
                            final success = await checklistCtrl.submitChecklist(
                              widget.projectId,
                              1, // Phase 1
                              'executor',
                            );
                            if (success) {
                              setState(() {});
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Executor checklist submitted successfully',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          submissionInfo: checklistCtrl.submissionInfo(
                            widget.projectId,
                            1, // Phase 1
                            'executor',
                          ),
                          canEdit: canEditExecutor,
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: checklist.length,
                            itemBuilder: (context, index) {
                              final question = checklist[index];
                              final isExpanded = executorExpanded.contains(
                                index,
                              );
                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: const BorderSide(color: Colors.blue),
                                ),
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: Column(
                                  children: [
                                    ListTile(
                                      title: Text(
                                        question.mainQuestion,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      trailing: Icon(
                                        isExpanded
                                            ? Icons.keyboard_arrow_up
                                            : Icons.keyboard_arrow_down,
                                      ),
                                      onTap: () {
                                        setState(() {
                                          if (isExpanded) {
                                            executorExpanded.remove(index);
                                          } else {
                                            executorExpanded.add(index);
                                          }
                                        });
                                      },
                                    ),
                                    if (isExpanded)
                                      Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: question.subQuestions.map((
                                            subQ,
                                          ) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 10,
                                              ),
                                              child: SubQuestionCard(
                                                key: ValueKey("executor_$subQ"),
                                                subQuestion: subQ,
                                                editable: canEditExecutor,
                                                initialData:
                                                    executorAnswers[subQ] ??
                                                    checklistCtrl.getAnswers(
                                                      widget.projectId,
                                                      1, // Phase 1
                                                      'executor',
                                                      subQ,
                                                    ),
                                                onAnswer: (ans) {
                                                  if (!canEditExecutor) return;
                                                  setState(() {
                                                    executorAnswers[subQ] = ans;
                                                  });
                                                  checklistCtrl.setAnswer(
                                                    widget.projectId,
                                                    1, // Phase 1
                                                    'executor',
                                                    subQ,
                                                    ans,
                                                  );
                                                },
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Reviewer Column
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          color: Colors.green.shade100,
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Reviewer Section",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (!canEditReviewer)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black12,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'View only',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        _SubmitBar(
                          role: 'reviewer',
                          projectId: widget.projectId,
                          phase: 1,
                          onSubmit: () async {
                            if (!canEditReviewer) return;
                            final success = await checklistCtrl.submitChecklist(
                              widget.projectId,
                              1, // Phase 1
                              'reviewer',
                            );
                            if (success) {
                              setState(() {});
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Reviewer checklist submitted successfully',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          submissionInfo: checklistCtrl.submissionInfo(
                            widget.projectId,
                            1, // Phase 1
                            'reviewer',
                          ),
                          canEdit: canEditReviewer,
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: checklist.length,
                            itemBuilder: (context, index) {
                              final question = checklist[index];
                              final isExpanded = reviewerExpanded.contains(
                                index,
                              );
                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: const BorderSide(color: Colors.green),
                                ),
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: Column(
                                  children: [
                                    ListTile(
                                      title: Text(
                                        question.mainQuestion,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      trailing: Icon(
                                        isExpanded
                                            ? Icons.keyboard_arrow_up
                                            : Icons.keyboard_arrow_down,
                                      ),
                                      onTap: () {
                                        setState(() {
                                          if (isExpanded) {
                                            reviewerExpanded.remove(index);
                                          } else {
                                            reviewerExpanded.add(index);
                                          }
                                        });
                                      },
                                    ),
                                    if (isExpanded)
                                      Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: question.subQuestions.map((
                                            subQ,
                                          ) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 10,
                                              ),
                                              child: SubQuestionCard(
                                                key: ValueKey("reviewer_$subQ"),
                                                subQuestion: subQ,
                                                editable: canEditReviewer,
                                                initialData:
                                                    reviewerAnswers[subQ] ??
                                                    checklistCtrl.getAnswers(
                                                      widget.projectId,
                                                      1, // Phase 1
                                                      'reviewer',
                                                      subQ,
                                                    ),
                                                onAnswer: (ans) {
                                                  if (!canEditReviewer) return;
                                                  setState(() {
                                                    reviewerAnswers[subQ] = ans;
                                                  });
                                                  checklistCtrl.setAnswer(
                                                    widget.projectId,
                                                    1, // Phase 1
                                                    'reviewer',
                                                    subQ,
                                                    ans,
                                                  );
                                                },
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// Simple submit bar widget
class _SubmitBar extends StatelessWidget {
  final String role;
  final String projectId;
  final int phase;
  final Future<void> Function() onSubmit;
  final Map<String, dynamic>? submissionInfo;
  final bool canEdit;

  const _SubmitBar({
    required this.role,
    required this.projectId,
    required this.phase,
    required this.onSubmit,
    required this.submissionInfo,
    this.canEdit = true,
  });

  @override
  Widget build(BuildContext context) {
    final submitted = submissionInfo?['is_submitted'] == true;
    final submittedAt = submissionInfo?['submitted_at'];
    final when = submittedAt != null
        ? (submittedAt is DateTime
              ? submittedAt.toString().split('.')[0]
              : submittedAt.toString())
        : null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          if (submitted)
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Submitted${when != null ? ' • $when' : ''}',
                  style: const TextStyle(color: Colors.green),
                ),
              ],
            )
          else
            ElevatedButton.icon(
              onPressed: canEdit ? onSubmit : null,
              icon: const Icon(Icons.send),
              label: Text(
                'Submit ${role[0].toUpperCase()}${role.substring(1)} Checklist',
              ),
            ),
          const Spacer(),
          Text(role.toUpperCase(), style: TextStyle(color: Colors.grey[700])),
        ],
      ),
    );
  }
}

// --- SubQuestionCard ---
class SubQuestionCard extends StatefulWidget {
  final String subQuestion;
  final Map<String, dynamic>? initialData;
  final Function(Map<String, dynamic>) onAnswer;
  final bool editable;

  const SubQuestionCard({
    super.key,
    required this.subQuestion,
    this.initialData,
    required this.onAnswer,
    this.editable = true,
  });

  @override
  State<SubQuestionCard> createState() => _SubQuestionCardState();
}

class _SubQuestionCardState extends State<SubQuestionCard> {
  String? selectedOption;
  final TextEditingController remarkController = TextEditingController();
  List<Map<String, dynamic>> _images = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    if (widget.initialData != null) {
      selectedOption = widget.initialData!['answer'];
      remarkController.text = widget.initialData!['remark'] ?? '';
      final imgs = widget.initialData!['images'];
      if (imgs is List) {
        _images = List<Map<String, dynamic>>.from(imgs);
      }
    }
  }

  @override
  void didUpdateWidget(SubQuestionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If initialData changed, update the state
    if (widget.initialData != oldWidget.initialData) {
      setState(() {
        _initializeData();
      });
    }
  }

  void _updateAnswer() {
    widget.onAnswer({
      "answer": selectedOption,
      "remark": remarkController.text,
      "images": _images,
    });
  }

  Future<void> _pickImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.image,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _images = result.files
              .where((f) => f.bytes != null)
              .map((f) => {'bytes': f.bytes!, 'name': f.name})
              .toList();
        });
        _updateAnswer();
      }
    } catch (e) {
      debugPrint('pick images error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.subQuestion,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        RadioListTile<String>(
          title: const Text("Yes"),
          value: "Yes",
          groupValue: selectedOption,
          onChanged: widget.editable
              ? (val) {
                  setState(() => selectedOption = val);
                  _updateAnswer();
                }
              : null,
        ),
        RadioListTile<String>(
          title: const Text("No"),
          value: "No",
          groupValue: selectedOption,
          onChanged: widget.editable
              ? (val) {
                  setState(() => selectedOption = val);
                  _updateAnswer();
                }
              : null,
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: remarkController,
                onChanged: widget.editable ? (val) => _updateAnswer() : null,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  hintText: "Remark",
                  border: const OutlineInputBorder(borderSide: BorderSide.none),
                ),
                enabled: widget.editable,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_a_photo_outlined),
              onPressed: widget.editable ? _pickImages : null,
            ),
          ],
        ),
        if (_images.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _images.length,
              itemBuilder: (context, i) {
                final img = _images[i];
                final rawBytes = img['bytes'];
                final bytes = rawBytes is Uint8List ? rawBytes : null;
                final name = img['name'] is String
                    ? img['name'] as String
                    : null;
                if (bytes == null) {
                  return const SizedBox(width: 0, height: 0);
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.memory(
                          bytes,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _images.removeAt(i));
                            _updateAnswer();
                          },
                          child: const CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.black54,
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                      if (name != null)
                        Positioned(
                          bottom: 4,
                          left: 4,
                          right: 4,
                          child: Container(
                            color: Colors.black45,
                            padding: const EdgeInsets.all(2),
                            child: Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
