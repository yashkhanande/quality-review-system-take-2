// import 'package:flutter/material.dart';

// class Project {
//   Project({
//     required this.title,
//     import 'package:flutter/material.dart';

//     class Project {
//       Project({
//         required this.title,
//         required this.started,
//         required this.priority,
//         required this.status,
//         this.executor,
//       });

//       String title;
//       DateTime started;
//       String priority; // High, Medium, Low
//       String status; // In Progress, Completed, Not Started
//       String? executor;
//     }

//     class ProjectsPage extends StatefulWidget {
//       const ProjectsPage({super.key});
// import 'package:flutter/material.dart';

// class Project {
//   Project({
//     required this.title,
//     required this.started,
//     required this.priority,
//     required this.status,
//     this.executor,
//   });

//   String title;
//   DateTime started;
//   String priority; // High, Medium, Low
//   String status; // In Progress, Completed, Not Started
//   String? executor;
// }

// class ProjectsPage extends StatefulWidget {
//   const ProjectsPage({super.key});

//   @override
//   State<ProjectsPage> createState() => _ProjectsPageState();
// }

// class _ProjectsPageState extends State<ProjectsPage> {
//   final List<Project> _projects = [];

//   @override
//   void initState() {
//     super.initState();
//     _projects.addAll([
//       Project(title: 'Implement New CRM System', started: DateTime(2024, 6, 1), priority: 'High', status: 'In Progress', executor: 'Emily Carter'),
//       Project(title: 'Develop Marketing Strategy', started: DateTime(2024, 5, 20), priority: 'Medium', status: 'Completed', executor: 'David Lee'),
//       Project(title: 'Conduct Market Research', started: DateTime(2024, 6, 10), priority: 'Low', status: 'Not Started', executor: null),
//       Project(title: 'Prepare Quarterly Report', started: DateTime(2024, 6, 25), priority: 'High', status: 'In Progress', executor: 'Michael Brown'),
//       Project(title: 'Organize Team Building Event', started: DateTime(2024, 5, 30), priority: 'Medium', status: 'Completed', executor: 'Olivia Green'),
//       Project(title: 'Update Website Content', started: DateTime(2024, 6, 12), priority: 'Low', status: 'Not Started', executor: null),
//       Project(title: 'Manage Social Media Campaigns', started: DateTime(2024, 6, 4), priority: 'High', status: 'In Progress', executor: 'Ava Taylor'),
//       Project(title: 'Coordinate Product Launch', started: DateTime(2024, 5, 18), priority: 'Medium', status: 'Completed', executor: 'Noah Harris'),
//       Project(title: 'Improve SEO Rankings', started: DateTime(2024, 4, 20), priority: 'Low', status: 'Not Started', executor: null),
//       Project(title: 'Build Analytics Dashboard', started: DateTime(2024, 5, 5), priority: 'High', status: 'In Progress', executor: 'Sophia Clark'),
//       Project(title: 'Customer Feedback Program', started: DateTime(2024, 6, 2), priority: 'Medium', status: 'Not Started', executor: null),
//       Project(title: 'Vendor Contract Renewal', started: DateTime(2024, 4, 28), priority: 'Low', status: 'Completed', executor: 'Ethan White'),
//     ]);
//   }

//   List<String> _teamNames() {
//     return const [
//       'Emma Carter',
//       'Liam Walker',
//       'Olivia Harris',
//       'Noah Clark',
//       'Ava Lewis',
//       'William Hall',
//       'Sophia Young',
//       'James Wright',
//       'Isabella King'
//     ];
//   }

//   Widget _priorityChip(String p) {
//     Color bg = const Color(0xFFEFF3F7);
//     if (p == 'High') bg = const Color(0xFFFBEFEF);
//     if (p == 'Low') bg = const Color(0xFFF5F7FA);
//     return Chip(label: Text(p, style: const TextStyle(fontSize: 12)), backgroundColor: bg);
//   }

//   Widget _statusWidget(Project p) {
//     return Text(p.status);
//   }

//   Future<void> _showCreateDialog() async {
//     final formKey = GlobalKey<FormState>();
//     String title = '';
//     DateTime started = DateTime.now();
//     String priority = 'Medium';
//     String status = 'Not Started';
//     String? executor;
//     final startedController = TextEditingController(text: '${started.year}-${started.month.toString().padLeft(2, '0')}-${started.day.toString().padLeft(2, '0')}');

//     await showDialog<void>(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text('Create Project'),
//           content: Form(
//             key: formKey,
//             child: SingleChildScrollView(
//               child: Column(
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/projects_controller.dart';
import '../models/project.dart';

class ProjectsPage extends StatefulWidget {
	const ProjectsPage({super.key});

	@override
	State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
	late final ProjectsController _ctrl;

	@override
	void initState() {
		super.initState();
		_ctrl = Get.put(ProjectsController());

		// Load some sample initial data if empty.
		if (_ctrl.projects.isEmpty) {
			_ctrl.loadInitial([
				Project(id: 'p1', title: 'Implement New CRM System', started: DateTime(2024, 6, 1), priority: 'High', status: 'In Progress', executor: 'Emily Carter'),
				Project(id: 'p2', title: 'Develop Marketing Strategy', started: DateTime(2024, 5, 20), priority: 'Medium', status: 'Completed', executor: 'David Lee'),
				Project(id: 'p3', title: 'Conduct Market Research', started: DateTime(2024, 6, 10), priority: 'Low', status: 'Not Started', executor: null),
				Project(id: 'p4', title: 'Build Analytics Dashboard', started: DateTime(2024, 5, 5), priority: 'High', status: 'In Progress', executor: 'Sophia Clark'),
			]);
		}
	}

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

	String _formatDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

	Widget _priorityChip(String p) {
		Color bg = const Color(0xFFEFF3F7);
		if (p == 'High') bg = const Color(0xFFFBEFEF);
		if (p == 'Low') bg = const Color(0xFFF5F7FA);
		return Chip(label: Text(p, style: const TextStyle(fontSize: 12)), backgroundColor: bg);
	}

	Future<void> _showCreateDialog() async {
		final formKey = GlobalKey<FormState>();
		String title = '';
		DateTime started = DateTime.now();
		String priority = 'Medium';
		String status = 'Not Started';
		String? executor;
		final startedController = TextEditingController(text: _formatDate(started));

		await showDialog<void>(
			context: context,
			builder: (context) {
				return AlertDialog(
					title: const Text('Create Project'),
					content: Form(
						key: formKey,
						child: SingleChildScrollView(
							child: Column(
								mainAxisSize: MainAxisSize.min,
								children: [
									TextFormField(
										decoration: const InputDecoration(labelText: 'Project Title *'),
										validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter title' : null,
										onSaved: (v) => title = v!.trim(),
									),
									TextFormField(
										readOnly: true,
										controller: startedController,
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
												startedController.text = _formatDate(started);
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
									final newProject = Project(
										id: DateTime.now().millisecondsSinceEpoch.toString(),
										title: title,
										started: started,
										priority: priority,
										status: status,
										executor: (executor == null || executor?.isEmpty == true) ? null : executor,
									);
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

	Future<void> _showEditDialog(Project project) async {
		final formKey = GlobalKey<FormState>();
		String title = project.title;
		DateTime started = project.started;
		String priority = project.priority;
		String status = project.status;
		String? executor = project.executor;
		final startedController = TextEditingController(text: _formatDate(started));

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
										controller: startedController,
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
												startedController.text = _formatDate(started);
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
										executor: (executor == null || executor?.isEmpty == true) ? null : executor,
									);
									_ctrl.updateProject(project.id, updated);
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
		}
	}

	@override
	Widget build(BuildContext context) {
		return Padding(
			padding: const EdgeInsets.all(24.0),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Row(
						mainAxisAlignment: MainAxisAlignment.spaceBetween,
						children: [
							Text('Projects', style: Theme.of(context).textTheme.headlineMedium),
							ElevatedButton.icon(
								onPressed: _showCreateDialog,
								icon: const Icon(Icons.add),
								label: const Text('Create New Project'),
								style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
							)
						],
					),
					const SizedBox(height: 16),
					FractionallySizedBox(
						widthFactor: 0.8,
						child: Card(
							elevation: 0,
							shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
							child: Padding(
								padding: const EdgeInsets.all(8.0),
								child: SingleChildScrollView(
									scrollDirection: Axis.horizontal,
									child: Obx(() {
										final projects = _ctrl.projects;
										return DataTable(
											columnSpacing: 24,
											columns: const [
												DataColumn(label: Text('Project Title')),
												DataColumn(label: Text('Started Date')),
												DataColumn(label: Text('Priority')),
												DataColumn(label: Text('Status')),
												DataColumn(label: Text('Executor')),
												DataColumn(label: Text('Actions')),
											],
											rows: projects.map((proj) {
												final executor = (proj.status == 'In Progress' || proj.status == 'Completed') ? (proj.executor ?? '--') : '--';
												return DataRow(cells: [
													DataCell(Container(constraints: const BoxConstraints(maxWidth: 300), child: Text(proj.title))),
													DataCell(Text(_formatDate(proj.started))),
													DataCell(_priorityChip(proj.priority)),
													DataCell(Text(proj.status)),
													DataCell(Text(executor)),
													DataCell(Row(children: [
														IconButton(onPressed: () => _showEditDialog(proj), icon: const Icon(Icons.edit, size: 20)),
														IconButton(onPressed: () => _confirmDelete(proj), icon: const Icon(Icons.delete_outline, size: 20)),
													])),
												]);
											}).toList(),
										);
									}),
								),
							),
						),
					),
				],
			),
		);
	}
}
