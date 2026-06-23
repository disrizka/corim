import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../api/api.dart';

class AuthState {
  final String? accessToken;
  final bool isAuthenticated;

  AuthState({this.accessToken, this.isAuthenticated = false});
}

class AuthNotifier extends Notifier<AuthState> {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  @override
  AuthState build() {
    return AuthState();
  }

  Future<void> saveLoginData(String accessToken, String refreshToken) async {
    try {
      await _storage.write(key: StorageKeys.accessToken, value: accessToken);
      await _storage.write(key: StorageKeys.refreshToken, value: refreshToken);
      await _storage.write(
        key: StorageKeys.loginTime,
        value: DateTime.now().toIso8601String(),
      );

      state = AuthState(accessToken: accessToken, isAuthenticated: true);
    } catch (e) {
      await forceLogout();
    }
  }

  Future<void> initializeAppFlow() async {
    try {
      final accessToken = await _storage.read(key: StorageKeys.accessToken);
      final refreshToken = await _storage.read(key: StorageKeys.refreshToken);
      final loginTimeString = await _storage.read(key: StorageKeys.loginTime);

      if (accessToken == null ||
          refreshToken == null ||
          loginTimeString == null) {
        await forceLogout();
        return;
      }

      final loginTime = DateTime.parse(loginTimeString);
      final totalDuration = DateTime.now().difference(loginTime);

      if (totalDuration.inHours >= 8) {
        await forceLogout();
        return;
      }

      state = AuthState(accessToken: accessToken, isAuthenticated: true);
    } catch (e) {
      await forceLogout();
    }
  }

  Future<String?> refreshAccessToken() async {
    try {
      final refreshToken = await _storage.read(key: StorageKeys.refreshToken);
      if (refreshToken == null) {
        await forceLogout();
        return null;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${Endpoints.refreshToken}'),
        headers: {
          'Refresh-Token': refreshToken,
          'Content-Type': ApiConfig.contentTypeJson,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['access_token'];

        await _storage.write(
          key: StorageKeys.accessToken,
          value: newAccessToken,
        );

        state = AuthState(accessToken: newAccessToken, isAuthenticated: true);
        return newAccessToken;
      } else {
        await forceLogout();
        return null;
      }
    } catch (e) {
      await forceLogout();
      return null;
    }
  }

  Future<void> forceLogout() async {
    try {
      await _storage.deleteAll();
    } catch (_) {}
    state = AuthState(accessToken: null, isAuthenticated: false);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
