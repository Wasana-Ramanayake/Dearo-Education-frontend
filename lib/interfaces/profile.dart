import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'home.dart';
import 'pastpapers.dart';
import 'quiz_marks.dart';
import 'edit_profile.dart';
import 'progress.dart';
import 'activity.dart';
import 'login_screen.dart';
import '../config/api.dart'; // ✅ Import your centralized API file

class ProfileScreen extends StatefulWidget {
  final int memberId;

  const ProfileScreen({super.key, required this.memberId});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  int selectedIndex = 3;

  String fullName = '';
  String dob = '';
  String email = '';
  String phone = '';
  String gender = '';
  String profileImage = '';

  bool isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    fetchUserProfile(widget.memberId);
  }

  Future<void> fetchUserProfile(int memberId) async {
    if (!mounted) return;
    setState(() => isLoadingProfile = true);

    final url = Uri.parse("${Api.profile}/$memberId"); // ✅ Using Api.profile

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final first = (data['first_name'] ?? '').toString().trim();
        final last = (data['last_name'] ?? '').toString().trim();
        String fullNameLocal = [first, last].where((s) => s.isNotEmpty).join(' ');
        if (fullNameLocal.isEmpty) {
          fullNameLocal = (data['name_with_initials'] ?? '').toString();
        }

        String dobLocal = '';
        final rawDob = data['dob']?.toString();
        if (rawDob != null && rawDob.isNotEmpty) {
          try {
            final dt = DateTime.parse(rawDob);
            dobLocal = DateFormat('yyyy-MM-dd').format(dt);
          } catch (_) {
            dobLocal = rawDob;
          }
        }

        String genderLocal = '';
        final g = (data['gender'] ?? '').toString().toLowerCase();
        if (g == '1' || g == 'male') {
          genderLocal = 'Male';
        } else if (g == '2' || g == 'female') {
          genderLocal = 'Female';
        } else if (g == '3' || g == 'other') {
          genderLocal = 'Other';
        }

        String profileImageLocal = (data['profile_image'] ?? '').toString();
        if (profileImageLocal.isNotEmpty && profileImageLocal.startsWith('/')) {
          profileImageLocal =
              Api.uploads.replaceAll("/uploads", "") + profileImageLocal;
        }

        if (!mounted) return;
        setState(() {
          fullName = fullNameLocal;
          dob = dobLocal;
          email = (data['email'] ?? '').toString();
          phone = (data['phone'] ?? '').toString();
          gender = genderLocal;
          profileImage = profileImageLocal;
          isLoadingProfile = false;
        });
      } else {
        _showErrorDialog(
            'Failed to load profile data. (${response.statusCode})');
        setState(() => isLoadingProfile = false);
      }
    } catch (e) {
      _showErrorDialog('Error while fetching profile data.');
      setState(() => isLoadingProfile = false);
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'))
        ],
      ),
    );
  }

  void onItemTapped(int index) {
    if (index == selectedIndex) return;

    setState(() => selectedIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => HomeScreen(memberId: widget.memberId)),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  PastPapersPage(memberId: widget.memberId)),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  ActivityPage(memberId: widget.memberId)),
        );
        break;
      case 3:
      default:
        break;
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo.shade900,
            ),
            child:
                const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _storage.delete(key: 'token');
      await _storage.delete(key: 'userId');

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<List<ActivityRecord>> _fetchSubmittedActivities() async {
    try {
      final response = await http.get(
        Uri.parse("${Api.activities}?m_id=${widget.memberId}"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as List;
        return data.map((item) {
          return ActivityRecord(
            text: item['activity_text'],
            rating: (item['rating'] as num).toInt(),
            date: DateFormat.yMMMMd().format(
                DateTime.tryParse(item['raw_date'] ?? '') ?? DateTime.now()),
            rawDate:
                DateTime.tryParse(item['raw_date'] ?? '') ?? DateTime.now(),
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('❌ Error fetching activities: $e');
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final avatarSize = isTablet ? 70.0 : 50.0;
    final fontSize = isTablet ? 18.0 : 14.0;
    final padding = isTablet ? 20.0 : 12.0;
    final cardHeight = isTablet ? 150.0 : 130.0;
    final buttonFontSize = isTablet ? 16.0 : 14.0;

    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.indigo.shade900,
        elevation: 2,
        centerTitle: true,
        title: const Text(
          "Profile",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<String>(
            color: Colors.white,
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'logout') {
                _confirmLogout();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Text('Logout',
                    style: TextStyle(color: Colors.indigo.shade900)),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: isLoadingProfile
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: padding, vertical: 20),
                child: Column(
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: avatarSize,
                        backgroundColor: Colors.indigo.shade200,
                        backgroundImage: (profileImage.isNotEmpty)
                            ? NetworkImage(profileImage)
                            : null,
                        child: profileImage.isEmpty
                            ? Icon(Icons.person,
                                size: avatarSize * 0.6,
                                color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(padding),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileRow(
                              'Full Name', fullName, fontSize),
                          _buildProfileRow(
                              'Date Of Birth', dob, fontSize),
                          _buildProfileRow(
                              'E-mail Address', email, fontSize),
                          _buildProfileRow(
                              'Phone Number', phone, fontSize),
                          _buildProfileRow('Gender', gender, fontSize),
                          const SizedBox(height: 16),
                          Center(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.edit, size: 16),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo.shade900,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12)),
                              ),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EditProfileScreen(
                                      memberId: widget.memberId,
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  fetchUserProfile(widget.memberId);
                                }
                              },
                              label: Text('Edit Profile',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: buttonFontSize)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Progress Overview',
                      style: TextStyle(
                        fontSize: fontSize + 3,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      QuizMarksPage(
                                          memberId: widget.memberId),
                                ),
                              );
                            },
                            child: Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12)),
                              child: Container(
                                height: cardHeight,
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Image.asset(
                                        'assets/images/exam2.png',
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Exam',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: fontSize,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              Colors.indigo.shade900),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final records =
                                  await _fetchSubmittedActivities();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ProgressPage(
                                          records: records),
                                ),
                              );
                            },
                            child: Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12)),
                              child: Container(
                                height: cardHeight,
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Image.asset(
                                        'assets/images/activity2.png',
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Activity',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: fontSize,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              Colors.indigo.shade900),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.indigo.shade900,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.indigo.shade200,
        showUnselectedLabels: true,
        currentIndex: selectedIndex,
        onTap: onItemTapped,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.assignment), label: 'Past Papers'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: 'Activities'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildProfileRow(
      String label, String value, double fontSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                color: Colors.indigo.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value.isNotEmpty ? value : '-',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: fontSize,
                color: Colors.indigo.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
