import 'package:flutter/material.dart';

class TeamPage extends StatelessWidget {
  const TeamPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey("team"),
      child: Text(
        "👥 Team Page",
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}
