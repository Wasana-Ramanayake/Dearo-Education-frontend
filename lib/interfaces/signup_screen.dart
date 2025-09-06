import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api.dart'; // ✅ Import Api class
import 'login_screen.dart';
import 'home.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  SignUpScreenState createState() => SignUpScreenState();
}

class SignUpScreenState extends State<SignUpScreen> {
  final Color primaryColor = Colors.indigo.shade900;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  final Map<String, int> genderMap = {
    'Male': 1,
    'Female': 2,
    'Other': 3,
  };

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return "Email is required";
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return "Enter a valid email";
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return "Phone number is required";
    final phoneRegex = RegExp(r'^\d{10}$');
    if (!phoneRegex.hasMatch(value)) return "Enter a valid 10-digit phone number";
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return "Password is required";
    if (value.length < 8) return "Password must be at least 8 characters";
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return "Confirm your password";
    if (value != passwordController.text) return "Passwords do not match";
    return null;
  }

  Future<void> _submitForm() async {
    final url = Uri.parse(Api.signup); // ✅ Use Api class

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "name": nameController.text.trim(),
          "dob": dateController.text.trim(),
          "gender": genderController.text.trim(),
          "phone": phoneController.text.trim(),
          "email": emailController.text.trim(),
          "password": passwordController.text,
          "confirm_password": confirmPasswordController.text,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 201) {
        if (responseData['user'] != null && responseData['user']['id'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('memberId', responseData['user']['id']);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Signup successful! Logged in.")),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(memberId: responseData['user']['id']),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Signup successful! Please log in.")),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Signup failed: ${responseData['message']}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (selectedDate != null) {
      setState(() {
        dateController.text = DateFormat('yyyy-MM-dd').format(selectedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  "Sign Up",
                  style: TextStyle(
                    fontSize: screenWidth * 0.08,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.05),
              buildTextField("Name with Initials", controller: nameController),
              SizedBox(height: screenHeight * 0.02),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: buildTextField("Date of Birth", controller: dateController),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              DropdownButtonFormField<String>(
                value: genderController.text.isEmpty
                    ? null
                    : genderMap.entries
                        .firstWhere(
                          (entry) =>
                              entry.value.toString() == genderController.text,
                          orElse: () => const MapEntry('Male', 1),
                        )
                        .key,
                decoration: InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: genderMap.keys.map((String genderLabel) {
                  return DropdownMenuItem<String>(
                    value: genderLabel,
                    child: Text(genderLabel),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    genderController.text = genderMap[newValue!].toString();
                  });
                },
                validator: (value) => value == null || value.isEmpty ? 'Gender is required' : null,
              ),
              SizedBox(height: screenHeight * 0.02),
              TextFormField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                keyboardType: TextInputType.phone,
                validator: _validatePhone,
              ),
              SizedBox(height: screenHeight * 0.02),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'E-mail Address',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: _validateEmail,
              ),
              SizedBox(height: screenHeight * 0.02),
              TextFormField(
                controller: passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: primaryColor,
                    ),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                ),
                validator: _validatePassword,
              ),
              SizedBox(height: screenHeight * 0.015),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: primaryColor,
                    ),
                    onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                  ),
                ),
                validator: _validateConfirmPassword,
              ),
              SizedBox(height: screenHeight * 0.04),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1, vertical: screenHeight * 0.02),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _submitForm();
                    }
                  },
                  child: Text(
                    "Sign Up",
                    style: TextStyle(fontSize: screenWidth * 0.05, color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? "),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                      child: Text(
                        "Login",
                        style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(String labelText, {TextEditingController? controller}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      validator: (value) => value == null || value.isEmpty ? "$labelText is required" : null,
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    dateController.dispose();
    genderController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
