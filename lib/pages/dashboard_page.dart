import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey("dashboard"),
      child: Text(
        "📊 Dashboard Overview",
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}
