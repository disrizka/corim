import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:corim/admin/home/home_screen.dart';
import 'package:corim/api/api.dart';
import 'package:android_id/android_id.dart';
import 'package:corim/auth/auth_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  /// Versi aplikasi yang terpasang (sama dengan "Versi Anda" di pop up update).
  /// Dibaca otomatis dari pubspec.yaml (version: 1.0.0+6) -> tampil "v1.0.0".
  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _appVersion = 'v${info.version}');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        String? fcmToken;
        try {
          fcmToken = await FirebaseMessaging.instance.getToken();
        } catch (e) {
          fcmToken = null;
        }

        final deviceType = Platform.isAndroid
            ? 'android'
            : (Platform.isIOS ? 'ios' : 'web');
        final osName = Platform.isAndroid
            ? 'Android'
            : (Platform.isIOS ? 'iOS' : Platform.operatingSystem);

        // Info device & aplikasi
        String deviceId = '';
        String osVersion = '';
        String modelName = '';
        String appVersion = '';
        try {
          final deviceInfo = DeviceInfoPlugin();
          if (Platform.isAndroid) {
            final android = await deviceInfo.androidInfo;
            deviceId = await const AndroidId().getId() ?? android.id;
            osVersion = android.version.release;
            // Contoh: "samsung SM-G980F" / "google Pixel 8"
            modelName = '${android.brand} ${android.model}';
          } else if (Platform.isIOS) {
            final ios = await deviceInfo.iosInfo;
            deviceId = ios.identifierForVendor ?? '';
            osVersion = ios.systemVersion;
            modelName = ios.utsname.machine;
          }
          final pkg = await PackageInfo.fromPlatform();
          appVersion = pkg.version; // otomatis dari pubspec.yaml
        } catch (e) {
          debugPrint('DEVICE INFO ERROR >> $e');
        }

        debugPrint(
          'LOGIN PAYLOAD >> email=${_emailController.text}, fcmToken=$fcmToken, deviceId=$deviceId, deviceType=$deviceType, osName=$osName, osVersion=$osVersion, modelName=$modelName, appVersion=$appVersion',
        );

        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}${Endpoints.login}'),
          headers: {'Content-Type': ApiConfig.contentTypeJson},
          body: jsonEncode({
            'email': _emailController.text.trim(),
            'password': _passwordController.text,
            'fcmToken': fcmToken ?? '',
            'deviceId': deviceId,
            'deviceType': deviceType,
            'osName': osName,
            'osVersion': osVersion,
            'modelName': modelName,
            'appVersion': appVersion,
          }),
        );

        final responseData = jsonDecode(response.body);

        if (response.statusCode == 200 && responseData['token'] != null) {
          final tokenData = responseData['token'];
          final userData = responseData['data'];
          final accessToken = tokenData['accessToken'];
          final refreshToken = tokenData['refreshToken'];
          final userName = userData?['name'];

          if (accessToken != null && refreshToken != null) {
            await ref
                .read(authProvider.notifier)
                .saveLoginData(accessToken, refreshToken, userName);

            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            }
            return;
          }
        }

        final errorMsg =
            responseData['msg'] ??
            'Login gagal, periksa email dan password Anda.';
        _showSnackBar(errorMsg);
      } catch (e) {
        _showSnackBar(
          'Gagal terhubung ke server. Periksa koneksi internet Anda.',
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  InputDecoration _inputDecoration(String label, {Widget? suffixIcon}) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color),
    );

    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Colors.white70,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.18),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      suffixIcon: suffixIcon,
      border: border(Colors.white.withOpacity(0.3)),
      enabledBorder: border(Colors.white.withOpacity(0.3)),
      focusedBorder: border(Colors.white.withOpacity(0.6)),
      errorBorder: border(Colors.redAccent),
      focusedErrorBorder: border(Colors.redAccent),
      errorStyle: const TextStyle(color: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Background gambar
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/login/login.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Overlay gelap tipis supaya teks putih tetap terbaca
          // (hapus bagian ini kalau gambar sudah cukup gelap)
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.35)),
          ),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.13),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.22),
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/images/logo.png',
                                    height: 90,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'CORIM APEX',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  const SizedBox(height: 28),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                    decoration: _inputDecoration('Email *'),
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Wajib diisi'
                                        : null,
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                    decoration: _inputDecoration(
                                      'Password *',
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: Colors.white60,
                                          size: 20,
                                        ),
                                        onPressed: () => setState(
                                          () => _obscurePassword =
                                              !_obscurePassword,
                                        ),
                                      ),
                                    ),
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Wajib diisi'
                                        : null,
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton(
                                      onPressed: () {},
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        'Forget Password?',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                          colors: [
                                            Color(0xFF1B1C52),
                                            Color(0xFF075985),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _isLoading
                                            ? null
                                            : _handleLogin,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          foregroundColor: Colors.white,
                                          disabledBackgroundColor:
                                              Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 15,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                              )
                                            : const Text(
                                                'Login',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(bottom: 28),
                  child: Column(
                    children: [
                      const Text(
                        'CORIM APEX',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '©2026 Corim Group Indonesia. All rights reserved',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 11,
                        ),
                      ),
                      if (_appVersion.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _appVersion,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
