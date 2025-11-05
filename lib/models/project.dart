class Project {
  String id;
  String title;
  DateTime started;
  String priority; // Low, Medium, High
  String status; // Pending, In Progress, Completed
  String? executor;

  Project({
    required this.id,
    required this.title,
    required this.started,
    required this.priority,
    required this.status,
    this.executor,
  });

  Project copyWith({
    String? id,
    String? title,
    DateTime? started,
    String? priority,
    String? status,
    String? executor,
  }) {
    return Project(
      id: id ?? this.id,
      title: title ?? this.title,
      started: started ?? this.started,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      executor: executor ?? this.executor,
    );
  }
}
