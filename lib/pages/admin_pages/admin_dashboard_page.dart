import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/project.dart';
import '../../controllers/projects_controller.dart';
import 'admin_project_details_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late final ProjectsController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(ProjectsController());

    if (_ctrl.projects.isEmpty) {
      _ctrl.loadInitial([
        Project(id: 'p1', title: 'Implement New CRM System', started: DateTime(2024, 6, 1), priority: 'High', status: 'In Progress', executor: 'Emily Carter'),
        Project(id: 'p2', title: 'Develop Marketing Strategy', started: DateTime(2024, 5, 20), priority: 'Medium', status: 'Completed', executor: 'David Lee'),
        Project(id: 'p3', title: 'Conduct Market Research', started: DateTime(2024, 6, 10), priority: 'Low', status: 'Not Started', executor: null),
        Project(id: 'p4', title: 'Build Analytics Dashboard', started: DateTime(2024, 5, 5), priority: 'High', status: 'In Progress', executor: 'Sophia Clark'),
      ]);
    }
  }

  Future<void> _showCreateDialog() async {
    final formKey = GlobalKey<FormState>();
    String title = '';
    DateTime started = DateTime.now();
    String priority = 'Medium';
    String status = 'Not Started';
    String? executor;
  String description = '';

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Project'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Project Title *'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter title' : null,
                  onSaved: (v) => title = v!.trim(),
                ),
                // Date picker field
                TextFormField(
                  readOnly: true,
                  controller: TextEditingController(text: '${started.year}-${started.month.toString().padLeft(2,'0')}-${started.day.toString().padLeft(2,'0')}'),
                  decoration: const InputDecoration(labelText: 'Started Date *'),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: started,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      started = picked;
                      // trigger a rebuild of the dialog content
                      (context as Element).markNeedsBuild();
                    }
                  },
                  validator: null,
                ),
                DropdownButtonFormField<String>(
                  initialValue: priority,
                  items: ['High', 'Medium', 'Low'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) => priority = v ?? priority,
                  decoration: const InputDecoration(labelText: 'Priority *'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  items: ['In Progress', 'Completed', 'Not Started'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) => status = v ?? status,
                  decoration: const InputDecoration(labelText: 'Status *'),
                ),
                // Executor dropdown populated from team members
                DropdownButtonFormField<String>(
                  initialValue: executor,
                  items: _teamNames().map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                  onChanged: (v) => executor = v,
                  decoration: const InputDecoration(labelText: 'Executor (optional)'),
                ),
                TextFormField(
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description *'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter description' : null,
                  onSaved: (v) => description = v!.trim(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  formKey.currentState?.save();
                  final newProject = Project(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: title,
                    started: started,
                    priority: priority,
                    status: status,
                    executor: (executor == null || executor?.isEmpty == true) ? null : executor,
                  );
                  // Store description separately via a side map (temporary, until model extended).
                  _descriptions[newProject.id] = description;
                  _ctrl.addProject(newProject);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  // Helper: read team names from team page initial data (light coupling)
  List<String> _teamNames() {
    return const [
      'Emma Carter',
      'Liam Walker',
      'Olivia Harris',
      'Noah Clark',
      'Ava Lewis',
      'William Hall',
      'Sophia Young',
      'James Wright',
      'Isabella King'
    ];
  }

  Widget _priorityChip(String p) {
    Color bg = const Color(0xFFEFF3F7);
    if (p == 'High') bg = const Color(0xFFFBEFEF);
    if (p == 'Low') bg = const Color(0xFFF5F7FA);
    return Chip(label: Text(p, style: const TextStyle(fontSize: 12)), backgroundColor: bg);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Welcome Back!', style: Theme.of(context).textTheme.headlineMedium),
                  ElevatedButton.icon(
                    onPressed: _showCreateDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Create New Project'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Tabular layout using ListView + Rows
              Obx(() {
                final projects = _ctrl.projects;
                return Column(
                  children: [
                    // Header row
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0,2))],
                      ),
                      child: Row(
                        children: const [
                          Expanded(flex: 3, child: Text('Project Title', style: TextStyle(fontWeight: FontWeight.w600))),
                          Expanded(flex: 2, child: Text('Started', style: TextStyle(fontWeight: FontWeight.w600))),
                          Expanded(flex: 1, child: Text('Priority', style: TextStyle(fontWeight: FontWeight.w600))),
                          Expanded(flex: 1, child: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
                          Expanded(flex: 2, child: Text('Executor', style: TextStyle(fontWeight: FontWeight.w600))),
                          Expanded(flex: 2, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: projects.length,
                      itemBuilder: (context, index) {
                        final proj = projects[index];
                        final executor = (proj.status == 'In Progress' || proj.status == 'Completed') ? (proj.executor ?? '--') : '--';
                        return GestureDetector(
                          onTap: () => Get.to(() => AdminProjectDetailsPage(project: proj, description: _descriptions[proj.id])),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.black12),
                            ),
                            child: Row(
                              children: [
                                Expanded(flex: 3, child: Text(proj.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
                                Expanded(flex: 2, child: Text('${proj.started.year}-${proj.started.month.toString().padLeft(2,'0')}-${proj.started.day.toString().padLeft(2,'0')}')),
                                Expanded(flex: 1, child: _priorityChip(proj.priority)),
                                Expanded(flex: 1, child: Text(proj.status)),
                                Expanded(flex: 2, child: Text(executor)),
                                Expanded(flex: 2, child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(icon: const Icon(Icons.edit), onPressed: () => _showEditDialog(proj)),
                                    IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _confirmDelete(proj)),
                                  ],
                                )),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditDialog(Project project) async {
    final formKey = GlobalKey<FormState>();
    String title = project.title;
    DateTime started = project.started;
    String priority = project.priority;
    String status = project.status;
    String? executor = project.executor;
    String description = _descriptions[project.id] ?? '';

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Project'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: title,
                    decoration: const InputDecoration(labelText: 'Project Title *'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter title' : null,
                    onSaved: (v) => title = v!.trim(),
                  ),
                  TextFormField(
                    readOnly: true,
                    controller: TextEditingController(text: '${started.year}-${started.month.toString().padLeft(2,'0')}-${started.day.toString().padLeft(2,'0')}'),
                    decoration: const InputDecoration(labelText: 'Started Date *'),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: started,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        started = picked;
                        (context as Element).markNeedsBuild();
                      }
                    },
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: priority,
                    items: ['High', 'Medium', 'Low'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (v) => priority = v ?? priority,
                    decoration: const InputDecoration(labelText: 'Priority *'),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    items: ['In Progress', 'Completed', 'Not Started'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (v) => status = v ?? status,
                    decoration: const InputDecoration(labelText: 'Status *'),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: executor,
                    items: _teamNames().map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                    onChanged: (v) => executor = v,
                    decoration: const InputDecoration(labelText: 'Executor (optional)'),
                  ),
                  TextFormField(
                    initialValue: description,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Description *'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter description' : null,
                    onSaved: (v) => description = v!.trim(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  formKey.currentState?.save();
                  final updated = project.copyWith(
                    title: title,
                    started: started,
                    priority: priority,
                    status: status,
                    executor: (executor == null || executor!.isEmpty) ? null : executor,
                  );
                  _ctrl.updateProject(project.id, updated);
                  _descriptions[project.id] = description;
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text('Are you sure you want to delete "${project.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      _ctrl.deleteProject(project.id);
      _descriptions.remove(project.id);
    }
  }

  // Temporary in-memory descriptions store (until Project model updated globally).
  final Map<String, String> _descriptions = {};
}