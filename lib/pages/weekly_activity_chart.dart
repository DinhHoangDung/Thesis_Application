import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';  // Thay thế import
import 'package:thesis_application/pages/weekly_activity_series.dart';

class WeeklyActivityChart extends StatelessWidget {
  final List<List<WeeklyActivitySeries>> data;

  const WeeklyActivityChart({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<String> activities = ["rest", "walk", "run", "stair"];
    List<BarChartGroupData> barGroups = [];
    bool _showLabel = false;

    for (int i = 0; i < activities.length; i++) {
      final List<FlSpot> spots = data[i].map((activity) {
        final double count = activity.count.toDouble();
        return FlSpot(i.toDouble(), count); // Tạo các điểm cho biểu đồ
      }).toList();

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: spots.isNotEmpty ? spots[0].y : 0, // Dữ liệu cho thanh
              color: Colors.blueAccent, // Màu sắc thanh
              width: 20,
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 100, // Giá trị tối đa nếu cần
                color: Colors.grey.shade300,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(5.0),
      child: Card(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Column(
            children: <Widget>[
              Row(
                children: [
                  Text(
                    "THIS WEEK'S ACTIVITY",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    color: Colors.grey,
                    onPressed: () {
                      _showLabel = !_showLabel;
                    },
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
                              activities[value.toInt()],
                              style: TextStyle(color: Colors.amber),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.amber),
                    ),
                    gridData: FlGridData(show: true),
                    barTouchData: BarTouchData(enabled: true),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
