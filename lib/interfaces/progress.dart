import 'dart:math';
import 'package:flutter/material.dart';
import 'activity.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ProgressPage extends StatefulWidget {
  final List<ActivityRecord> records; // ✅ accept records from ActivityPage

  const ProgressPage({super.key, required this.records});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  List<ActivityRecord> records = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    records = widget.records; // initialize with passed records
    isLoading = false;
  }

  // ✅ Calculate median
  double calculateMedian(List<int> ratings) {
    if (ratings.isEmpty) return 0;
    ratings.sort();
    int middle = ratings.length ~/ 2;
    if (ratings.length.isOdd) {
      return ratings[middle].toDouble();
    } else {
      return ((ratings[middle - 1] + ratings[middle]) / 2).toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // Filter only current month’s records
    final currentMonthRecords = records
        .where((r) => r.rawDate.month == now.month && r.rawDate.year == now.year)
        .toList();

    // Group by date
    final Map<String, List<ActivityRecord>> groupedByDate = {};
    for (var record in currentMonthRecords) {
      final dateKey = DateFormat('yyyy-MM-dd').format(record.rawDate);
      groupedByDate.putIfAbsent(dateKey, () => []).add(record);
    }

    // Calculate median per day
    final List<_DateRating> dailyMedians = groupedByDate.entries.map((entry) {
      final date = DateFormat('yyyy-MM-dd').parse(entry.key);
      final ratings = entry.value.map((e) => e.rating).toList();
      final median = calculateMedian(ratings);
      return _DateRating(date: date, medianRating: median);
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Progress percent
    final double progressPercent = dailyMedians.isEmpty
        ? 0.0
        : ((dailyMedians.fold<double>(
                    0.0, (sum, e) => (sum + e.medianRating).toDouble()) /
                (dailyMedians.length * 5.0)) *
            100.0);

    // Chart spots
    final List<FlSpot> spots = [];
    for (int i = 0; i < dailyMedians.length; i++) {
      spots.add(FlSpot(i.toDouble(), dailyMedians[i].medianRating.toDouble()));
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final circleSize = min(screenWidth, screenHeight * 0.25); // ✅ Reduced size

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Progress',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo.shade700,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: records.isEmpty
          ? const Center(child: Text('No activities submitted yet.'))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // ✅ Modern Circular Progress
                  SizedBox(
                    height: circleSize,
                    width: circleSize,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: circleSize,
                          width: circleSize,
                          child: CircularProgressIndicator(
                            value: progressPercent / 100,
                            strokeWidth: 14,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.indigo.shade400,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "${progressPercent.toStringAsFixed(1)}%",
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              "This Month",
                              style: TextStyle(
                                  fontSize: 14, color: Colors.black54),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  const Text(
                    'Daily Median Ratings',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // ✅ Modern Line Chart
                  Expanded(
                    child: LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: 5,
                        gridData: FlGridData(show: true),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              getTitlesWidget: (value, _) =>
                                  Text(value.toInt().toString()),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              getTitlesWidget: (value, _) {
                                final index = value.toInt();
                                if (index >= 0 && index < dailyMedians.length) {
                                  return Text(DateFormat.Md()
                                      .format(dailyMedians[index].date));
                                }
                                return const Text('');
                              },
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: Colors.indigo.shade400,
                            barWidth: 4,
                            dotData: FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.indigo.shade200.withOpacity(0.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _DateRating {
  final DateTime date;
  final double medianRating;

  _DateRating({required this.date, required this.medianRating});
}
