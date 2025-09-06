import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'verify.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key}); // Changed to const constructor

  @override
  ForgotPasswordScreenState createState() => ForgotPasswordScreenState();
}

class ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final Color primaryColor = Colors.indigo.shade900;
  bool _isLoading = false;

  Future<void> sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final String email = emailController.text.trim();
    const String apiUrl = 'http://10.49.126.105:5000/api/password/forgot';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => VerificationScreen(email: email)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Failed to send OTP')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Server error')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: screenHeight * 0.03),
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: primaryColor, size: screenWidth * 0.05),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                SizedBox(height: screenHeight * 0.04),
                Text(
                  "Forgot Password",
                  style: TextStyle(
                    fontSize: screenWidth * 0.08,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                SizedBox(height: screenHeight * 0.04),
                Image.asset('assets/images/forgot.png', width: screenWidth * 0.6),
                SizedBox(height: screenHeight * 0.04),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Enter E-mail Address",
                    style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.w500),
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: "example@gmail.com",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.015),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Please enter your email";
                    if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(value)) return "Enter a valid email";
                    return null;
                  },
                ),
                SizedBox(height: screenHeight * 0.03),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Back to ", style: TextStyle(fontSize: 16)),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
                      child: Text(
                        "Login",
                        style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.03),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: sendOTP,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1, vertical: screenHeight * 0.02),
                        ),
                        child: Text(
                          "Send OTP",
                          style: TextStyle(fontSize: screenWidth * 0.05, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                SizedBox(height: screenHeight * 0.05),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
}