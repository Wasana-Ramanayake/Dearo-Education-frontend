import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';

class NewPasswordScreen extends StatefulWidget {
  final String email;
  const NewPasswordScreen({super.key, required this.email}); // Changed to const constructor

  @override
  NewPasswordScreenState createState() => NewPasswordScreenState();
}

class NewPasswordScreenState extends State<NewPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscureText = true;
  final Color primaryColor = Colors.indigo.shade900;
  bool _isLoading = false;

  void _toggleVisibility() => setState(() => _obscureText = !_obscureText);

  Future<void> resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    const String apiUrl = 'http://10.49.126.105:5000/api/password/reset';
    final body = jsonEncode({"email": widget.email, "password": _passwordController.text});

    try {
      final response = await http.post(Uri.parse(apiUrl), headers: {"Content-Type": "application/json"}, body: body);
      setState(() => _isLoading = false);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset successful')));
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Reset failed')));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildPasswordField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      obscureText: _obscureText,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility), onPressed: _toggleVisibility),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return "Password is required";
        if (controller == _confirmPasswordController && value != _passwordController.text) return "Passwords do not match";
        if (value.length < 6) return "Password must be at least 6 characters";
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08, vertical: screenHeight * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(icon: Icon(Icons.arrow_back, color: primaryColor, size: screenWidth * 0.06), onPressed: () => Navigator.pop(context)),
              SizedBox(height: screenHeight * 0.04),
              Text("New Password", style: TextStyle(fontSize: screenWidth * 0.08, fontWeight: FontWeight.bold, color: primaryColor)),
              SizedBox(height: screenHeight * 0.03),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildPasswordField("Password", _passwordController),
                    SizedBox(height: screenHeight * 0.02),
                    _buildPasswordField("Confirm Password", _confirmPasswordController),
                    SizedBox(height: screenHeight * 0.04),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: resetPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.15, vertical: screenHeight * 0.02),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                            ),
                            child: const Text("Reset", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
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

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}