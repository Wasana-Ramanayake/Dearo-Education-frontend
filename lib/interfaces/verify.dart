import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'new_password.dart';

class VerificationScreen extends StatefulWidget {
  final String email;
  const VerificationScreen({super.key, required this.email}); // Changed to const constructor

  @override
  VerificationScreenState createState() => VerificationScreenState();
}

class VerificationScreenState extends State<VerificationScreen> {
  final Color primaryColor = Colors.indigo.shade900;
  final List<TextEditingController> controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> focusNodes = List.generate(4, (_) => FocusNode());

  bool isResendDisabled = true;
  int resendTimer = 30;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    startResendTimer();
  }

  void startResendTimer() {
    setState(() {
      isResendDisabled = true;
      resendTimer = 30;
    });
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendTimer > 0) {
        setState(() => resendTimer--);
      } else {
        setState(() => isResendDisabled = false);
        timer.cancel();
      }
    });
  }

  Future<void> resendOTP() async {
    if (isResendDisabled) return;
    const String apiUrl = 'http://10.49.126.105:5000/api/password/resend-otp';
    try {
      final response = await http.post(Uri.parse(apiUrl),
          headers: {"Content-Type": "application/json"}, body: jsonEncode({"email": widget.email}));
      if (response.statusCode == 200) startResendTimer();
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> verifyOTP() async {
    final otp = controllers.map((e) => e.text).join();
    if (otp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter complete OTP')));
      return;
    }

    setState(() => _isLoading = true);
    const String apiUrl = 'http://127.0.0.1:5000/api/password/verify-otp';
    try {
      final response = await http.post(Uri.parse(apiUrl),
          headers: {"Content-Type": "application/json"}, body: jsonEncode({"email": widget.email, "otp": otp}));

      setState(() => _isLoading = false);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => NewPasswordScreen(email: widget.email)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Invalid OTP')));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget buildOtpBox(int index) {
    return Container(
      width: 55,
      height: 55,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(border: Border.all(color: primaryColor), borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: controllers[index],
        focusNode: focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        decoration: const InputDecoration(counterText: '', border: InputBorder.none),
        onChanged: (value) {
          if (value.isNotEmpty && index < 3) FocusScope.of(context).requestFocus(focusNodes[index + 1]);
          if (value.isEmpty && index > 0) FocusScope.of(context).requestFocus(focusNodes[index - 1]);
        },
        onSubmitted: (value) {
          if (index == 3) verifyOTP();
        },
      ),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: primaryColor, size: screenWidth * 0.06),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              SizedBox(height: screenHeight * 0.04),
              Center(
                child: Column(
                  children: [
                    Text("Verification", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor)),
                    SizedBox(height: screenHeight * 0.02),
                    Image.asset("assets/images/reset.png", height: 150),
                    SizedBox(height: screenHeight * 0.02),
                    const Text("Enter Verification Code", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                    SizedBox(height: screenHeight * 0.02),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(4, (index) => buildOtpBox(index))),
                    SizedBox(height: screenHeight * 0.02),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Didn't receive a code? "),
                        TextButton(
                          onPressed: isResendDisabled ? null : resendOTP,
                          child: Text("Resend",
                              style: TextStyle(color: isResendDisabled ? Colors.grey : primaryColor, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    if (isResendDisabled) Text("Resend in $resendTimer s", style: const TextStyle(color: Colors.grey)),
                    SizedBox(height: screenHeight * 0.02),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: verifyOTP,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.15, vertical: screenHeight * 0.02),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            child: const Text("Verify", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
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
    for (var c in controllers) {
      c.dispose();
    }
    for (var n in focusNodes) {
      n.dispose();
    }
    super.dispose();
  }
}