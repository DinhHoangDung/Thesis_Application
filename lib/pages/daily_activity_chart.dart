import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Thay thế import
import 'package:thesis_application/pages/daily_activity_series.dart';

class DailyActivityChart extends StatelessWidget {
  final List<ActivitySeries> data;

  const DailyActivityChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Chuyển đổi dữ liệu thành FlSpot
    List<BarChartGroupData> barGroups = data.map((activity) {
      return BarChartGroupData(
        x: data.indexOf(activity),
        barRods: [
          BarChartRodData(
            toY: activity.count.toDouble(), // Giá trị để hiển thị
            color: activity.barColor, // Màu sắc của thanh
          ),
        ],
      );
    }).toList();

    return Container(
      height: 300,
      padding: const EdgeInsets.all(1.0),
      child: Card(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(1.0),
          child: Column(
            children: <Widget>[
              Row(
                children: [
                  Text(
                    "TODAY'S ACTIVITY",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              Expanded(
                child: BarChart(
                  BarChartData(
                    barGroups: barGroups,
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 38,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              data[value.toInt()].type, // Hiển thị loại hoạt động
                              style: TextStyle(color: Colors.black),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: true),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.grey),
                    ),
                    gridData: FlGridData(show: true),
                    barTouchData: BarTouchData(enabled: true),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
