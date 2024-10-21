import 'package:flutter/material.dart'; // Ensure this import is added for Color

class WeeklyActivitySeries {
  String type;
  String day;
  int count;
  int target;
  final Color barColor;

  WeeklyActivitySeries({
    required this.day,
    required this.type,
    required this.count,
    required this.target,
    required this.barColor,
  });
}