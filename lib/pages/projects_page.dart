import 'package:flutter/material.dart';

class ProjectsPage extends StatelessWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey("projects"),
      child: Text(
        "📁 Projects Page",
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}
