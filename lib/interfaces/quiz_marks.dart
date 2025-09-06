import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config/api.dart'; // <-- Import your Api class

class QuizMarksPage extends StatefulWidget {
  final int memberId;
  const QuizMarksPage({super.key, required this.memberId});

  @override
  State<QuizMarksPage> createState() => _QuizMarksPageState();
}

class _QuizMarksPageState extends State<QuizMarksPage> {
  bool isLoading = true;
  bool hasError = false;
  List<dynamic> progressData = [];

  @override
  void initState() {
    super.initState();
    fetchQuizMarks();
  }

  Future<void> fetchQuizMarks() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final url = Uri.parse("${Api.quizMarks}/attempts?m_id=${widget.memberId}");
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        // Group attempts by date
        final Map<String, List<dynamic>> grouped = {};
        for (var item in data) {
          final date = item['date'] ?? '';
          if (!grouped.containsKey(date)) grouped[date] = [];
          grouped[date]!.add(item);
        }

        final List<dynamic> transformed = [];

        grouped.forEach((date, attempts) {
          // Map to keep latest attempt per quiz for median
          final Map<String, dynamic> latestPerQuiz = {};
          for (var a in attempts) {
            final title = a['quiz_title'] ?? 'Untitled Quiz';
            final aTime = a['time'] ?? '';
            final existing = latestPerQuiz[title];
            if (existing == null) {
              latestPerQuiz[title] = a;
            } else {
              final existingTime = existing['time'] ?? '';
              if (aTime.isNotEmpty &&
                  existingTime.isNotEmpty &&
                  DateTime.tryParse(aTime)
                          ?.isAfter(DateTime.tryParse(existingTime) ?? DateTime(0)) ==
                      true) {
                latestPerQuiz[title] = a;
              }
            }
          }

          // Median calculation using latest attempt per quiz
          final percentages = latestPerQuiz.values.map<double>((a) {
            final marks = (a['marks'] ?? 0) as int;
            final total = (a['total_questions'] ?? 1) as int;
            return total > 0 ? (marks / total) * 100.0 : 0.0;
          }).toList()
            ..sort();

          double median;
          final n = percentages.length;
          if (n == 0) {
            median = 0.0;
          } else if (n.isOdd) {
            median = percentages[n ~/ 2];
          } else {
            median = (percentages[n ~/ 2 - 1] + percentages[n ~/ 2]) / 2.0;
          }

          // Sort attempts by time ascending
          attempts.sort((a, b) {
            final aTime = a['time'] ?? '';
            final bTime = b['time'] ?? '';
            final aDateTime = DateTime.tryParse(aTime) ?? DateTime(0);
            final bDateTime = DateTime.tryParse(bTime) ?? DateTime(0);
            return aDateTime.compareTo(bDateTime);
          });

          transformed.add({
            'date': date,
            'median_marks': median,
            'attempts': attempts,
          });
        });

        // Sort by date ascending for chart
        transformed.sort((a, b) =>
            DateTime.tryParse(a['date'] ?? '')
                ?.compareTo(DateTime.tryParse(b['date'] ?? '') ?? DateTime(0)) ??
            0);

        if (!mounted) return;
        setState(() {
          progressData = transformed;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load quiz attempts');
      }
    } catch (e) {
      debugPrint("Error fetching quiz marks: $e");
      if (!mounted) return;
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  Widget buildChart() {
    if (progressData.isEmpty) {
      return const Center(child: Text("No quiz data available"));
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < progressData.length; i++) {
      spots.add(FlSpot(
          i.toDouble(), (progressData[i]["median_marks"] as num).toDouble()));
    }

    return SizedBox(
      height: 260,
      child: InteractiveViewer(
        panEnabled: true,
        scaleEnabled: true,
        minScale: 0.8,
        maxScale: 3.0,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: 100,
            gridData: FlGridData(show: true, horizontalInterval: 20),
            borderData: FlBorderData(
              border: const Border(
                  bottom: BorderSide(), left: BorderSide(), right: BorderSide()),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: 20,
                  getTitlesWidget: (value, _) =>
                      Text('${value.toInt()}%', style: const TextStyle(fontSize: 12)),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (val, _) {
                    final index = val.toInt();
                    if (index < 0 || index >= progressData.length) return const SizedBox.shrink();
                    final date = progressData[index]['date'] ?? '';
                    if (date.isEmpty) return const SizedBox.shrink();
                    return Text(
                      DateFormat('MM/dd').format(DateTime.parse(date)),
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Colors.blue.shade900,
                barWidth: 3,
                dotData: FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.blue.shade900.withOpacity(0.15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDailyAttempts() {
    if (progressData.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text("No quiz attempts found", textAlign: TextAlign.center),
      );
    }

    final reversedData = progressData.reversed.toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      itemCount: reversedData.length,
      itemBuilder: (context, i) {
        final day = reversedData[i];

        final Map<String, List<dynamic>> quizMap = {};
        for (var attempt in day['attempts']) {
          final title = attempt['quiz_title'] ?? 'Untitled Quiz';
          quizMap.putIfAbsent(title, () => []).add(attempt);
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            title: Text(
              DateFormat("MMM d, yyyy").format(
                  DateTime.tryParse(day['date'] ?? '') ?? DateTime.now()),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
            ),
            subtitle: Text(
              "Median: ${day['median_marks'].toStringAsFixed(1)}%",
              style: TextStyle(color: Colors.blue.shade900),
            ),
            children: quizMap.entries.expand<Widget>((entry) {
              return entry.value.map<Widget>((a) {
                final time = a['time'] != null && a['time'].toString().isNotEmpty
                    ? DateFormat('HH:mm').format(DateTime.parse(a['time']))
                    : '';
                return ListTile(
                  leading: Icon(Icons.quiz, color: Colors.blue.shade900),
                  title: Text("${a['quiz_title'] ?? 'Untitled Quiz'}${time.isNotEmpty ? ' ($time)' : ''}"),
                  trailing: Text(
                    "${a['marks'] ?? 0}/${a['total_questions'] ?? 0}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                );
              });
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Quiz Progress",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.normal),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.blue.shade900,
        elevation: 2,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "Failed to load quiz marks.\nPull down to retry.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      flex: 1,
                      child: RefreshIndicator(
                        onRefresh: fetchQuizMarks,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: buildDailyAttempts(),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: buildChart(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
