import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'subject_screen.dart';
import '../config/api.dart'; // <-- Import your Api class

class GradeScreen extends StatefulWidget {
  final int courseId;
  final String gradeTitle;
  final int memberId; // <-- Added memberId

  const GradeScreen({
    super.key,
    required this.courseId,
    required this.gradeTitle,
    required this.memberId, // <-- Required
  });

  @override
  State<GradeScreen> createState() => _GradeScreenState();
}

class _GradeScreenState extends State<GradeScreen> {
  final String apiUrl = Api.courseModules; // <-- Updated to use Api class

  List<Map<String, dynamic>> subjects = [];
  bool isLoading = true;
  String? errorMessage;

  Future<void> fetchSubjects() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final filteredSubjects = data
            .where((item) => item['c_id'] == widget.courseId)
            .map<Map<String, dynamic>>((item) => {
                  'title': item['title'] ?? 'Subject',
                  'course_module_id': item['id'] ?? 0,
                })
            .toList();

        setState(() {
          subjects = filteredSubjects;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load subjects';
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching subjects: $e');
      setState(() {
        errorMessage = 'Network error. Please try again.';
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchSubjects();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo.shade900,
        title: Text('${widget.gradeTitle} Subjects',
            style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? Center(
                    child: Text(errorMessage!,
                        style: const TextStyle(color: Colors.red)))
                : subjects.isEmpty
                    ? const Center(child: Text('No subjects found.'))
                    : Stack(
                        children: [
                          ListView.builder(
                            padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.08, vertical: 24),
                            itemCount: subjects.length,
                            itemBuilder: (context, index) {
                              final subject = subjects[index];
                              return SubjectCard(
                                title: subject['title'],
                                screenWidth: screenWidth,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SubjectScreen(
                                        courseId: widget.courseId,
                                        moduleId: subject['course_module_id'],
                                        subjectName: subject['title'],
                                        memberId: widget.memberId, // <-- Pass memberId
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          Positioned(
                            bottom: 16,
                            right: 16,
                            child: Image.asset(
                              'assets/grades/${widget.courseId}.png',
                              width: screenWidth * 0.25,
                              height: screenWidth * 0.25,
                            ),
                          ),
                        ],
                      ),
      ),
    );
  }
}

class SubjectCard extends StatelessWidget {
  final String title;
  final double screenWidth;
  final VoidCallback onTap;

  const SubjectCard({
    super.key,
    required this.title,
    required this.screenWidth,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        width: screenWidth * 0.75,
        height: 55,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[300],
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: onTap,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.indigo.shade900,
            ),
          ),
        ),
      ),
    );
  }
}
