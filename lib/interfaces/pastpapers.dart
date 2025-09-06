import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../models/paper.dart';
import '../config/api.dart'; // Import the Api class
import 'activity.dart';
import 'home.dart';
import 'profile.dart';

class PastPapersPage extends StatefulWidget {
  final int memberId;

  const PastPapersPage({super.key, required this.memberId});

  @override
  State<PastPapersPage> createState() => _PastPapersPageState();
}

class _PastPapersPageState extends State<PastPapersPage> {
  int selectedIndex = 1;
  bool isLoading = false;
  Map<int, Map<String, List<Paper>>> groupedPapers = {};
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchPapers();
  }

  Future<void> fetchPapers({
    int? grade,
    String? subject,
    int? year,
    int page = 1,
    int limit = 50,
  }) async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final Map<String, String> queryParameters = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (grade != null) queryParameters['grade'] = grade.toString();
      if (subject != null && subject.isNotEmpty) queryParameters['subject'] = subject;
      if (year != null) queryParameters['year'] = year.toString();

      final uri = Uri.parse(Api.pastPapers).replace(queryParameters: queryParameters);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          final Map<String, dynamic> data = body['data'] ?? {};
          groupedPapers.clear();

          data.forEach((gradeKey, subjects) {
            final int gradeInt = int.tryParse(gradeKey) ?? 0;
            if (gradeInt == 0) return;

            groupedPapers.putIfAbsent(gradeInt, () => {});

            if (subjects is Map<String, dynamic>) {
              subjects.forEach((subjectKey, papersList) {
                if (papersList is List) {
                  groupedPapers[gradeInt]!.putIfAbsent(subjectKey, () => []);
                  for (var p in papersList) {
                    try {
                      groupedPapers[gradeInt]![subjectKey]!.add(Paper.fromJson(p));
                    } catch (e) {
                      debugPrint('Error parsing paper: $e');
                    }
                  }
                }
              });
            }
          });

          if (mounted) setState(() {});
        } else {
          if (mounted) {
            setState(() {
              errorMessage = body['error'] ?? 'Failed to fetch papers';
            });
          }
        }
      } else {
        try {
          final errorResponse = json.decode(response.body);
          final errorDetail = errorResponse['error'] ?? 'Unknown error (${response.statusCode})';
          if (mounted) setState(() => errorMessage = 'Server error: $errorDetail');
        } catch (e) {
          if (mounted) setState(() => errorMessage = 'HTTP error: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (mounted) setState(() => errorMessage = 'Network error: ${e.toString()}');
      debugPrint('❌ Error fetching papers: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _downloadPaper(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw "Could not open file";
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Download failed: ${e.toString()}")),
        );
      }
    }
  }

  void onItemTapped(int index) {
    if (index == selectedIndex) return;
    if (!mounted) return;
    setState(() => selectedIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen(memberId: widget.memberId)),
        );
        break;
      case 1:
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ActivityPage(memberId: widget.memberId)),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ProfileScreen(memberId: widget.memberId)),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📚 Past Papers"),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh papers",
            onPressed: () => fetchPapers(),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: () => fetchPapers(),
                  child: groupedPapers.isEmpty
                      ? _buildEmptyState()
                      : ListView(
                          padding: const EdgeInsets.all(12),
                          children: groupedPapers.keys.map((grade) {
                            final subjects = groupedPapers[grade]!;
                            return Card(
                              elevation: 4,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ExpansionTile(
                                iconColor: Colors.indigo,
                                collapsedIconColor: Colors.indigo,
                                title: Text(
                                  "🎓 Grade $grade",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                children: subjects.entries.map((subjectEntry) {
                                  final subject = subjectEntry.key;
                                  final subjectPapers = subjectEntry.value;

                                  return Padding(
                                    padding: const EdgeInsets.only(left: 16.0),
                                    child: ExpansionTile(
                                      iconColor: Colors.deepPurple,
                                      collapsedIconColor: Colors.deepPurple,
                                      title: Text(
                                        subject,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      children: subjectPapers.map((paper) {
                                        return Card(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: ListTile(
                                            leading: Icon(
                                              paper.isPdf
                                                  ? Icons.picture_as_pdf
                                                  : Icons.insert_drive_file,
                                              color: paper.isPdf ? Colors.red : Colors.indigo,
                                              size: 32,
                                            ),
                                            title: Text(
                                              paper.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            subtitle: Text(
                                              "${paper.year} • ${paper.formattedFileSize}",
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 13,
                                              ),
                                            ),
                                            trailing: IconButton(
                                              icon: const Icon(Icons.download),
                                              color: Colors.indigo,
                                              onPressed: () =>
                                                  _downloadPaper(paper.downloadUrl),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          }).toList(),
                        ),
                ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.indigo.shade700,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.indigo.shade200,
        currentIndex: selectedIndex,
        onTap: onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Past Papers'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Activities'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 64),
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            onPressed: () => fetchPapers(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "No papers available",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
