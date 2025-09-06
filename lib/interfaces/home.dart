// 📁 lib/interfaces/home.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config/api.dart'; // ✅ Import Api class
import 'profile.dart';
import 'grade_screen.dart';
import 'activity.dart';
import 'pastpapers.dart';

class HomeScreen extends StatefulWidget {
  final int memberId; // <-- memberId passed from login
  const HomeScreen({super.key, required this.memberId});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> allCourses = [];
  List<Map<String, dynamic>> filteredCourses = [];

  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchCourses();
  }

  Future<void> fetchCourses() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(Uri.parse(Api.courses)); // ✅ Use Api class

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        final parsed = data.map<Map<String, dynamic>>((item) {
          return {
            'id': item['id'],
            'title': item['title'],
            'imagePath': _getImagePathForGrade(item['title']),
          };
        }).toList();

        setState(() {
          allCourses = parsed;
          filteredCourses = List.from(parsed);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load courses from server.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network error. Please try again.';
        isLoading = false;
      });
    }
  }

  String _getImagePathForGrade(String title) {
    final match = RegExp(r'Grade\s*(\d+)').firstMatch(title);
    if (match != null) {
      final gradeNumber = match.group(1);
      return 'assets/grades/$gradeNumber.png';
    }
    return 'assets/grades/default.png';
  }

  void _navigateToGradeScreen(int courseId, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GradeScreen(
          courseId: courseId,
          gradeTitle: title,
          memberId: widget.memberId, // Pass memberId
        ),
      ),
    );
  }

  void _onBottomNavTap(int index) {
    if (index == selectedIndex) return;
    setState(() => selectedIndex = index);

    switch (index) {
      case 0:
        // Already on Home
        break;
      case 1:
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => PastPapersPage(memberId: widget.memberId)));
        break;
      case 2:
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => ActivityPage(memberId: widget.memberId)));
        break;
      case 3:
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => ProfileScreen(memberId: widget.memberId)));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double titleFontSize = screenWidth > 600 ? 28 : 20;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(screenWidth, titleFontSize),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Text(errorMessage,
                      style: const TextStyle(color: Colors.red)),
                )
              : RefreshIndicator(
                  onRefresh: fetchCourses,
                  child: _buildCourseList(),
                ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  AppBar _buildAppBar(double screenWidth, double titleFontSize) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: Text(
        'My Courses',
        style: TextStyle(
          fontSize: titleFontSize,
          fontWeight: FontWeight.bold,
          color: Colors.indigo.shade900,
          fontFamily: 'Poppins',
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: TextField(
            controller: searchController,
            onChanged: (text) {
              setState(() {
                filteredCourses = allCourses
                    .where((course) => course['title']
                        .toLowerCase()
                        .contains(text.toLowerCase()))
                    .toList();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search for courses...',
              hintStyle: TextStyle(color: Colors.indigo.shade400),
              prefixIcon: Icon(Icons.search, color: Colors.indigo.shade400),
              filled: true,
              fillColor: Colors.indigo.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Colors.indigo.shade900),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: filteredCourses.length,
      itemBuilder: (context, index) {
        final course = filteredCourses[index];
        return GestureDetector(
          onTap: () => _navigateToGradeScreen(course['id'], course['title']),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 4,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Image.asset(
                  course['imagePath'],
                  width: 70,
                  height: 70,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.broken_image, size: 48),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    course['title'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.indigo.shade900,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  BottomNavigationBar _buildBottomNavBar() {
    return BottomNavigationBar(
      backgroundColor: Colors.indigo.shade700,
      elevation: 10,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.indigo.shade200,
      currentIndex: selectedIndex,
      onTap: _onBottomNavTap,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Past Papers'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Activities'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
