import 'package:flutter/material.dart';

class ScoreBar extends StatelessWidget {
  final int score;
  final int maxScore;
  const ScoreBar({super.key, required this.score, required this.maxScore});

  @override
  Widget build(BuildContext context) {
    final ratio = (score / maxScore).clamp(0.0, 1.0);
    Color color;
    if (ratio >= 0.7) {
      color = Colors.green;
    } else if (ratio >= 0.5) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: ratio,
        minHeight: 10,
        color: color,
        backgroundColor: Colors.black12,
      ),
    );
  }
}

