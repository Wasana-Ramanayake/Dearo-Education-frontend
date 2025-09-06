import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../config/api.dart';

class EditProfileScreen extends StatefulWidget {
  final int memberId;

  const EditProfileScreen({
    super.key,
    required this.memberId,
  });

  @override
  EditProfileScreenState createState() => EditProfileScreenState();
}

class EditProfileScreenState extends State<EditProfileScreen> {
  static const Map<String, String> genderToCode = {
    'Male': '1',
    'Female': '2',
    'Other': '3',
  };
  static const Map<String, String> codeToGender = {
    '1': 'Male',
    '2': 'Female',
    '3': 'Other',
  };

  String? selectedGender;

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  File? _image;
  String? profileImageUrl;
  final ImagePicker _picker = ImagePicker();

  bool isLoading = false;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final response = await http
          .get(Uri.parse("${Api.profile}/${widget.memberId}"))
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        firstNameController.text = (data['first_name'] ?? '').toString();
        lastNameController.text = (data['last_name'] ?? '').toString();

        final rawDob = (data['dob'] ?? '').toString();
        if (rawDob.isNotEmpty) {
          try {
            dateController.text =
                DateTime.parse(rawDob).toLocal().toString().split(' ').first;
          } catch (_) {
            dateController.text = rawDob;
          }
        } else {
          dateController.text = '';
        }

        emailController.text = (data['email'] ?? '').toString();
        phoneController.text = (data['phone'] ?? '').toString();

        String g = (data['gender'] ?? '').toString().toLowerCase();
        if (g == '1' || g == 'male') {
          selectedGender = 'Male';
        } else if (g == '2' || g == 'female') {
          selectedGender = 'Female';
        } else if (g == '3' || g == 'other') {
          selectedGender = 'Other';
        } else {
          selectedGender = null;
        }

        profileImageUrl = (data['profile_image'] ?? '').toString();
        if (profileImageUrl != null &&
            profileImageUrl!.isNotEmpty &&
            profileImageUrl!.startsWith('/')) {
          profileImageUrl = '${Api.uploads}$profileImageUrl'; // ✅ fixed
        }
      } else {
        _showSnackBar(
            "Failed to load profile data (${response.statusCode})",
            isError: true);
      }
    } catch (e) {
      _showSnackBar("Error fetching profile", isError: true);
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initial = DateTime.now();
    if (dateController.text.isNotEmpty) {
      final parsed = DateTime.tryParse(dateController.text);
      if (parsed != null) initial = parsed;
    }

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null && mounted) {
      setState(() {
        dateController.text =
            pickedDate.toLocal().toString().split(' ').first; // yyyy-MM-dd
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (pickedFile != null && mounted) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  String? _validateRequired(String? v, String label) {
    if (v == null || v.trim().isEmpty) return '$label is required';
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(v.trim())) return 'Enter a valid email';
    return null;
  }

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone is required';
    if (v.trim().length < 7) return 'Enter a valid phone number';
    return null;
  }

  Future<void> _submitProfile() async {
    if (!mounted) return;

    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please fix the errors above', isError: true);
      return;
    }
    if (selectedGender == null) {
      _showSnackBar('Please select gender', isError: true);
      return;
    }

    setState(() => isSubmitting = true);

    final uri = Uri.parse("${Api.profile}/${widget.memberId}");
    final request = http.MultipartRequest("PUT", uri);

    request.fields['first_name'] = firstNameController.text.trim();
    request.fields['last_name'] = lastNameController.text.trim();
    request.fields['dob'] = dateController.text.trim();
    request.fields['email'] = emailController.text.trim();
    request.fields['phone'] = phoneController.text.trim();
    request.fields['gender'] = genderToCode[selectedGender] ?? '3';

    if (_image != null) {
      request.files
          .add(await http.MultipartFile.fromPath('profile_image', _image!.path));
    } else if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
      request.fields['profile_image'] = profileImageUrl!;
    }

    try {
      final streamed = await request.send().timeout(const Duration(seconds: 30));
      if (!mounted) return;

      if (streamed.statusCode == 200) {
        _showSnackBar("Profile updated successfully!");
        Navigator.pop(context, true);
      } else {
        _showSnackBar(
            "Failed to update profile (${streamed.statusCode}).",
            isError: true);
      }
    } catch (e) {
      _showSnackBar("Something went wrong while saving.", isError: true);
    } finally {
      if (!mounted) return;
      setState(() => isSubmitting = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      content: Row(
        children: [
          Icon(isError ? Icons.error : Icons.check_circle, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
    ));
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    dateController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    Widget avatar() {
      ImageProvider? provider;
      if (_image != null) {
        provider = FileImage(_image!);
      } else if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
        provider = NetworkImage(profileImageUrl!);
      }

      return CircleAvatar(
        radius: screenWidth > 600 ? 70 : 55,
        backgroundColor: Colors.indigo.shade200,
        backgroundImage: provider,
        child: (provider == null)
            ? const Icon(Icons.person, size: 60, color: Colors.white)
            : null,
      );
    }

    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        backgroundColor: Colors.indigo.shade900,
        elevation: 0,
        title: const Text(
          "Edit Profile",
          style:
              TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(screenWidth > 600 ? 32 : 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          avatar(),
                          Positioned(
                            right: 5,
                            bottom: 5,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: CircleAvatar(
                                backgroundColor: Colors.white,
                                radius: 20,
                                child: Icon(Icons.camera_alt,
                                    size: 20, color: Colors.indigo.shade900),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    _buildInputCard(
                        label: "First name",
                        controller: firstNameController,
                        validator: (v) => _validateRequired(v, 'First name')),
                    _buildInputCard(
                        label: "Last name",
                        controller: lastNameController,
                        validator: (v) => _validateRequired(v, 'Last name')),
                    _buildDateField("Date of birth", dateController),
                    _buildInputCard(
                        label: "E-mail Address",
                        controller: emailController,
                        inputType: TextInputType.emailAddress,
                        validator: _validateEmail),
                    _buildInputCard(
                        label: "Phone Number",
                        controller: phoneController,
                        inputType: TextInputType.phone,
                        validator: _validatePhone),
                    _buildGenderDropdown(),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: 180, // reduced button width
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : _submitProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo.shade900,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Text("Save Changes",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInputCard({
    required String label,
    required TextEditingController controller,
    TextInputType inputType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: TextFormField(
          controller: controller,
          keyboardType: inputType,
          validator: validator,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.blue.shade900),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: TextFormField(
          controller: controller,
          readOnly: true,
          onTap: () => _selectDate(context),
          validator: (v) => _validateRequired(v, 'Date of birth'),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.blue.shade900),
            border: InputBorder.none,
            suffixIcon:
                Icon(Icons.calendar_today, color: Colors.indigo.shade900),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: DropdownButtonFormField<String>(
          value: selectedGender,
          hint: const Text("Select Gender"),
          decoration: InputDecoration(
              border: InputBorder.none,
              hintStyle: TextStyle(color: Colors.blue.shade900)),
          validator: (v) => v == null ? 'Please select gender' : null,
          onChanged: (String? value) {
            if (!mounted) return;
            setState(() => selectedGender = value);
          },
          items: const [
            DropdownMenuItem(value: 'Male', child: Text('Male')),
            DropdownMenuItem(value: 'Female', child: Text('Female')),
            DropdownMenuItem(value: 'Other', child: Text('Other')),
          ],
        ),
      ),
    );
  }
}
