import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:thesis_application/pages/daily_activity_time_series.dart';

class DailyActivityTimeSeriesChart extends StatelessWidget {
  final List<ActivityTimeSeries> data;

  const DailyActivityTimeSeriesChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    List<FlSpot> spots = data
        .map((activity) => FlSpot(
            activity.seq.toDouble(), int.parse(activity.type).toDouble()))
        .toList();

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
                    "TODAY'S TIME SERIES",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              Expanded(
                child: LineChart(
                  LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: Colors.blueAccent,
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
                    titlesData: FlTitlesData(
                      leftTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: true)),
                      bottomTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: true)),
                    ),
                    borderData: FlBorderData(show: true),
                    gridData: FlGridData(show: true),
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
