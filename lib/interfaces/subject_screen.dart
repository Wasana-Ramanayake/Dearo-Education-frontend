import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'quiz.dart';
import '../config/api.dart'; // <-- Import your Api class

class SubjectScreen extends StatefulWidget {
  final int courseId;
  final int moduleId;
  final String subjectName;
  final int memberId;

  const SubjectScreen({
    super.key,
    required this.courseId,
    required this.moduleId,
    required this.subjectName,
    required this.memberId,
  });

  @override
  State<SubjectScreen> createState() => _SubjectScreenState();
}

class _SubjectScreenState extends State<SubjectScreen> {
  List<Map<String, dynamic>> topics = [];
  bool isLoading = true;
  bool hasError = false;
  int selectedUnit = 1;

  @override
  void initState() {
    super.initState();
    fetchTopics();
  }

  Future<void> fetchTopics() async {
    final String apiUrl =
        '${Api.courseSubModules}?courseId=${widget.courseId}&moduleId=${widget.moduleId}';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        final processed = data.map((item) => {
              'title': item['title'] ?? 'No Title',
              'description': item['description'] ?? '',
              'youtube_link': item['youtube_link'] ?? '',
              'unit': item['unit'] ?? 1,
            }).toList();

        setState(() {
          topics = processed.cast<Map<String, dynamic>>();
          isLoading = false;
          hasError = false;
        });
      } else {
        throw Exception("Failed to load data");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  List<Map<String, dynamic>> get topicsForSelectedUnit {
    return topics.where((topic) => topic['unit'] == selectedUnit).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.indigo.shade900,
        centerTitle: true,
        title: Text(
          widget.subjectName,
          style: TextStyle(
            color: Colors.white,
            fontSize: isTablet ? 28 : 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white, // <-- Back arrow color
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : hasError
                ? Center(
                    child: Text(
                      "Failed to load topics. Please try again later.",
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: isTablet ? 18 : 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : Padding(
                    padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ...List.generate(10, (index) {
                                final unit = index + 1;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                  child: ElevatedButton(
                                    onPressed: () => setState(() => selectedUnit = unit),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: selectedUnit == unit
                                          ? Colors.indigo.shade900
                                          : Colors.grey.shade400,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isTablet ? 20 : 10,
                                        vertical: isTablet ? 14 : 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    child: Text(
                                      'Unit $unit',
                                      style: TextStyle(
                                        fontSize: isTablet ? 18 : 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => QuizPage(
                                        subjectName: widget.subjectName,
                                        quizId: widget.moduleId,
                                        memberId: widget.memberId,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo.shade900,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isTablet ? 24 : 20,
                                    vertical: isTablet ? 14 : 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: Text(
                                  'Quizzes',
                                  style: TextStyle(
                                    fontSize: isTablet ? 18 : 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Unit $selectedUnit',
                          style: TextStyle(
                            color: Colors.indigo.shade900,
                            fontSize: isTablet ? 20 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: topicsForSelectedUnit.isEmpty
                              ? const Center(
                                  child: Text("No topics available."),
                                )
                              : ListView.separated(
                                  itemCount: topicsForSelectedUnit.length,
                                  separatorBuilder: (_, __) => const Divider(height: 16),
                                  itemBuilder: (context, index) {
                                    final topic = topicsForSelectedUnit[index];
                                    return ListTile(
                                      title: Text(
                                        topic['title'],
                                        style: TextStyle(
                                          fontSize: isTablet ? 18 : 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        topic['description'],
                                        style: TextStyle(
                                          fontSize: isTablet ? 16 : 14,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      onTap: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Clicked on "${topic['title']}"')),
                                        );
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
