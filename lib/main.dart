import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'interfaces/get_started_screen.dart';
import 'interfaces/login_screen.dart';
import 'interfaces/home.dart'; // assumes: const HomeScreen({required int memberId})

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dearo Education',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      // ✅ SplashScreen is now the first screen
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/get-started': (context) => const GetStartedScreen(),
        '/home': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final memberId = (args is int) ? args : null;
          if (memberId == null) {
            return const GetStartedScreen();
          }
          return HomeScreen(memberId: memberId);
        },
      },
    );
  }
}

/// SplashScreen with animation and automatic navigation
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Fade-in animation for logo
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();

    // Navigate after splash
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(const Duration(seconds: 2)); // splash duration

    // Read token and memberId from storage
    final token = await _storage.read(key: 'token');
    final userIdStr = await _storage.read(key: 'userId');
    int? parsedId;
    if (userIdStr != null && userIdStr.isNotEmpty) {
      parsedId = int.tryParse(userIdStr);
    }

    // ✅ If valid token & memberId → HomeScreen
    if (token != null && token.isNotEmpty && parsedId != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(memberId: parsedId!), // fix: non-null
        ),
      );
      return;
    }

    // Otherwise → GetStartedScreen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const GetStartedScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ✅ Updated logo path
              Image.asset(
                'assets/images/logo_2.png',
                width: 150,
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
