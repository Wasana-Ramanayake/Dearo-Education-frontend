import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'home.dart';
import 'profile.dart';
import 'progress.dart';
import 'pastpapers.dart';
import '../config/api.dart'; // ✅ use Api class

class ActivityPage extends StatefulWidget {
  final int memberId;
  const ActivityPage({super.key, required this.memberId});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  final List<ActivityEntry> activities = [];
  final List<ActivityRecord> submittedActivities = [];
  final List<String> categories = ['Parent', 'Teacher'];
  String? selectedCategory;
  int selectedIndex = 2;

  String studentName = '';

  final Map<int, String> ratingLabels = const {
    1: 'Very Bad',
    2: 'Bad',
    3: 'Normal',
    4: 'Good',
    5: 'Very Good',
  };

  @override
  void initState() {
    super.initState();
    _fetchStudentName();
    _addActivity();
    _fetchActivities();
  }

  Future<void> _fetchStudentName() async {
    try {
      final response = await http.get(
        Uri.parse("${Api.activities}/student-name?m_id=${widget.memberId}"), // ✅
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return; 
        setState(() {
          studentName = data['name'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching student name: $e');
    }
  }

  void _addActivity() => setState(() => activities.add(ActivityEntry()));

  void _removeActivity(int index) {
    final removed = activities[index];
    setState(() => activities.removeAt(index));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Activity removed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => setState(() => activities.insert(index, removed)),
        ),
      ),
    );
  }

  Future<void> _submitSingleActivity(int index) async {
    final entry = activities[index];
    if (entry.controller.text.isEmpty ||
        entry.rating == 0 ||
        selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fill all fields: category, activity text, rating.'),
        ),
      );
      return;
    }

    final now = DateTime.now();

    final payload = {
      'm_id': widget.memberId,
      'student_name': studentName,
      'category': selectedCategory!,
      'activity_text': entry.controller.text,
      'rating': entry.rating,
      'raw_date': now.toIso8601String(),
    };

    try {
      final response = await http.post(
        Uri.parse(Api.activities), // ✅
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201) {
        entry.controller.clear();
        entry.rating = 0;
        await _fetchActivities();
      } else {
        debugPrint("❌ Failed to submit activity: ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ Error submitting activity: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error submitting activity.')),
      );
    }
  }

  Future<void> _fetchActivities() async {
    try {
      final response = await http.get(
        Uri.parse("${Api.activities}?m_id=${widget.memberId}"), // ✅
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as List;
        if (!mounted) return; 
        setState(() {
          submittedActivities
            ..clear()
            ..addAll(data.map((item) => ActivityRecord.fromJson(item)));
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching activities: $e');
    }
  }

  void _removeSubmittedRecord(int index) =>
      setState(() => submittedActivities.removeAt(index));

  void _onItemTapped(int index) {
    if (index == selectedIndex) return;
    setState(() => selectedIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => HomeScreen(memberId: widget.memberId)),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => PastPapersPage(memberId: widget.memberId)),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => ProfileScreen(memberId: widget.memberId)),
        );
        break;
    }
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.indigo.shade400),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.indigo.shade400),
        ),
      );

  Widget _buildRatingLegend() {
    return LayoutBuilder(builder: (context, constraints) {
      final imageWidth = constraints.maxWidth / 3;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: ratingLabels.entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    "${e.key} - ${e.value}",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.indigo.shade900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: SizedBox(
              width: imageWidth,
              height: ratingLabels.length * 25.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/activity.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final spacing = size.height * 0.012;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                  size.width * 0.06,
                  size.width * 0.06,
                  size.width * 0.06,
                  size.width * 0.01),
              child: Column(
                children: [
                  Center(
                    child: Text(
                      'Activities',
                      style: TextStyle(
                        fontSize: size.width * 0.075,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade900,
                      ),
                    ),
                  ),
                  SizedBox(height: spacing),
                  DropdownButtonFormField<String>(
                    decoration: _inputDecoration("Category"),
                    value: selectedCategory,
                    icon: const Icon(Icons.arrow_drop_down),
                    items: categories
                        .map((cat) =>
                            DropdownMenuItem(value: cat, child: Text(cat)))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => selectedCategory = value),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    size.width * 0.06, 0, size.width * 0.06, size.width * 0.06),
                child: Column(
                  children: [
                    SizedBox(height: spacing),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Activity List",
                          style: TextStyle(
                            fontSize: size.width * 0.05,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo.shade900,
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.indigo),
                          onPressed: _addActivity,
                        ),
                      ],
                    ),
                    SizedBox(height: spacing),
                    Column(
                      children: List.generate(
                        activities.length,
                        (index) =>
                            _buildActivityCard(index, activities[index]),
                      ),
                    ),
                    SizedBox(height: spacing),
                    _buildRatingLegend(),
                    if (submittedActivities.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        "Submitted Records",
                        style: TextStyle(
                          fontSize: size.width * 0.05,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ...List.generate(submittedActivities.length, (index) {
                        final record = submittedActivities[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text(record.text),
                            subtitle: Text(
                              "Rating: ${ratingLabels[record.rating] ?? ''}\nDate: ${record.date}",
                            ),
                            leading: const Icon(Icons.check_circle,
                                color: Colors.green),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle,
                                  color: Colors.redAccent),
                              onPressed: () => _removeSubmittedRecord(index),
                            ),
                          ),
                        );
                      }),
                    ],
                    const SizedBox(height: 90),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.4,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.bar_chart),
                    label: const Text("Progress"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade700,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ProgressPage(records: submittedActivities),
                        ),
                      ).then((_) => _fetchActivities());
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.indigo.shade700,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.indigo.shade200,
        currentIndex: selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.assignment), label: 'PastPapers'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: 'Activities'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildActivityCard(int index, ActivityEntry entry) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: entry.controller,
                    decoration: _inputDecoration("Activity ${index + 1}"),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => _removeActivity(index),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (i) {
                    final rating = i + 1;
                    return Radio<int>(
                      value: rating,
                      groupValue: entry.rating,
                      onChanged: (value) =>
                          setState(() => entry.rating = value!),
                      activeColor: Colors.indigo,
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (i) => Text('${i + 1}')),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade700,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _submitSingleActivity(index),
                child: const Text("Submit Activity"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ActivityEntry {
  final TextEditingController controller = TextEditingController();
  int rating = 0;
}

// ✅ Updated ActivityRecord with fromJson factory
class ActivityRecord {
  final String text;
  final int rating;
  final String date;
  final DateTime rawDate;

  ActivityRecord({
    required this.text,
    required this.rating,
    required this.date,
    required this.rawDate,
  });

  factory ActivityRecord.fromJson(Map<String, dynamic> json) {
    final rawDateString = json['raw_date'] ?? '';
    final parsedDate = DateTime.tryParse(rawDateString) ?? DateTime.now();
    return ActivityRecord(
      text: json['activity_text'] ?? '',
      rating: (json['rating'] ?? 0) as int,
      rawDate: parsedDate,
      date: DateFormat.yMMMMd().format(parsedDate),
    );
  }
}
