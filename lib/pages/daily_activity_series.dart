import 'package:flutter/material.dart'; // Thêm import Flutter material
// Thay đổi import cho fl_chart

class ActivitySeries {
  String type; // Loại hoạt động
  int count; // Số lượng hoạt động
  Color barColor; // Màu sắc thanh biểu đồ (thay vì charts.Color)

  ActivitySeries({
    required this.type,
    required this.count,
    required this.barColor, // Sử dụng Color từ Flutter
  });
}
