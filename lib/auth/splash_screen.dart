import 'package:corim/admin/home/home_screen.dart';
import 'package:corim/auth/auth_provider.dart';
import 'package:corim/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleSplashLogic();
  }

  void _handleSplashLogic() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    await ref.read(authProvider.notifier).initializeAppFlow();
    final isAuthenticated = ref.read(authProvider).isAuthenticated;

    if (mounted) {
      if (isAuthenticated) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.expand(
        child: Image.asset(
          'assets/images/splash_screen.jpg',
          fit: BoxFit.cover,
          // Kalau file splash_screen.jpg belum ada, tampilkan logo lama
          errorBuilder: (context, error, stackTrace) => const Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: Image(
                image: AssetImage('assets/images/logo.png'),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
