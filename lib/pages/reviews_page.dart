import 'package:flutter/material.dart';

class ReviewsPage extends StatelessWidget {
  const ReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey("reviews"),
      child: Text(
        "📝 Reviews Page",
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}
