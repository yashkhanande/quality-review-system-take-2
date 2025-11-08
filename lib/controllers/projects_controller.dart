import 'package:get/get.dart';
import '../models/project.dart';

class ProjectsController extends GetxController {
  final RxList<Project> projects = <Project>[].obs;

  List<Project> get all => projects;

  void loadInitial(List<Project> initial) {
    projects.assignAll(initial.map(_normalize));
  }

  void addProject(Project p) {
    projects.add(_normalize(p));
  }

  void updateProject(String id, Project updated) {
    final idx = projects.indexWhere((e) => e.id == id);
    if (idx != -1) projects[idx] = _normalize(updated);
  }

  void deleteProject(String id) {
    projects.removeWhere((e) => e.id == id);
  }

  // Ensure null-safety and consistent values
  Project _normalize(Project p) {
    String safe(String? s) => (s ?? '').trim();
    // Coerce allowed sets
    const priorities = {'Low', 'Medium', 'High'};
    const statuses = {'Not Started', 'In Progress', 'Completed'};

    final title = safe(p.title).isEmpty ? 'Untitled' : safe(p.title);
    final priority = priorities.contains(p.priority) ? p.priority : 'Medium';
    final status = statuses.contains(p.status) ? p.status : 'Not Started';
    final executor = safe(p.executor).isEmpty ? null : safe(p.executor);
    final description = safe(p.description);
    final assigned = (p.assignedEmployees == null)
        ? null
        : p.assignedEmployees!.where((e) => safe(e).isNotEmpty).toList();

    return p.copyWith(
      title: title,
      priority: priority,
      status: status,
      executor: executor,
      description: description.isEmpty ? null : description,
      assignedEmployees: assigned,
    );
  }
}
