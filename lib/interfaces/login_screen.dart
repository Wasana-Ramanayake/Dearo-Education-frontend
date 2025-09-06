import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/api.dart'; // ✅ Import Api class
import 'home.dart';
import 'forgot_password.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  bool rememberMe = false;
  bool _isPasswordVisible = false;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkExistingLogin();
  }

  Future<void> _checkExistingLogin() async {
    final String? token = await _storage.read(key: 'token');
    final String? userId = await _storage.read(key: 'userId');

    if (token != null && userId != null) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(memberId: int.parse(userId)),
        ),
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return "Password is required";
    if (value.length < 6) return "Password must be at least 6 characters long";
    return null;
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final url = Uri.parse(Api.login); // ✅ Use Api class

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailController.text.trim(),
          'password': passwordController.text,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        final String token = responseData['token'];
        final int memberId = responseData['user']['id'];

        await _storage.write(key: 'token', value: token);
        await _storage.write(key: 'userId', value: memberId.toString());

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(memberId: memberId),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login failed: ${responseData['message']}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.blue.shade900;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double screenWidth = constraints.maxWidth;
            final double screenHeight = constraints.maxHeight;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    SizedBox(height: screenHeight * 0.02),
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: primaryColor, size: screenWidth * 0.07),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    FittedBox(
                      child: Text(
                        "Log in",
                        style: TextStyle(
                          fontSize: screenWidth * 0.1,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.04),
                    Image.asset('assets/images/FF.png', width: screenWidth * 0.5),
                    SizedBox(height: screenHeight * 0.05),
                    _buildTextField(
                      controller: emailController,
                      label: 'E-mail',
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Email is required';
                        if (!value.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    SizedBox(height: screenHeight * 0.025),
                    _buildTextField(
                      controller: passwordController,
                      label: 'Password',
                      obscureText: !_isPasswordVisible,
                      validator: _validatePassword,
                      suffixIcon: IconButton(
                        icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    _buildRememberMeAndForgotPasswordRow(primaryColor),
                    SizedBox(height: screenHeight * 0.03),
                    _buildLoginButton(primaryColor, screenWidth, screenHeight),
                    SizedBox(height: screenHeight * 0.03),
                    _buildSignUpSection(primaryColor, screenWidth),
                    SizedBox(height: screenHeight * 0.05),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        suffixIcon: suffixIcon,
      ),
      validator: validator,
    );
  }

  Widget _buildRememberMeAndForgotPasswordRow(Color primaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Checkbox(
              value: rememberMe,
              onChanged: (value) => setState(() => rememberMe = value!),
            ),
            const Text("Remember Me", style: TextStyle(fontSize: 16)),
          ],
        ),
        Flexible(
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
              );
            },
            child: Text(
              "Forgot Password?",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(Color primaryColor, double screenWidth, double screenHeight) {
    return Center(
      child: _isLoading
          ? const CircularProgressIndicator()
          : SizedBox(
              width: screenWidth * 0.5, // ✅ reduced width
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                ),
                onPressed: _login,
                child: Text(
                  "Login",
                  style: TextStyle(fontSize: screenWidth * 0.05, color: Colors.white),
                ),
              ),
            ),
    );
  }

  Widget _buildSignUpSection(Color primaryColor, double screenWidth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            "If you are a new member",
            style: TextStyle(fontSize: screenWidth * 0.04),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SignUpScreen()),
            );
          },
          child: Text(
            "Sign Up",
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: screenWidth * 0.04,
            ),
          ),
        ),
      ],
    );
  }
}
