import 'dart:convert';
import 'package:corim/api/api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

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
  AuthState build() => AuthState();
  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      String payload = parts[1];
      while (payload.length % 4 != 0) {
        payload += '=';
      }

      final decoded = jsonDecode(utf8.decode(base64Url.decode(payload)));
      final exp = decoded['exp'] as int?;
      if (exp == null) return true;

      final expiryTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final now = DateTime.now();
      final isExpired = now.isAfter(expiryTime);

      print('[JWT] Expiry  : $expiryTime');
      print('[JWT] Sekarang: $now');
      print(' [JWT] Expired : $isExpired');

      if (!isExpired) {
        final sisa = expiryTime.difference(now);
        print(
          ' [JWT] Sisa aktif: ${sisa.inHours}j ${sisa.inMinutes % 60}m ${sisa.inSeconds % 60}s',
        );
      }

      return isExpired;
    } catch (e) {
      print(' [JWT] Gagal decode: $e');
      return true;
    }
  }

  Future<void> saveLoginData(String accessToken, String refreshToken) async {
    try {
      await _storage.write(key: StorageKeys.accessToken, value: accessToken);
      await _storage.write(key: StorageKeys.refreshToken, value: refreshToken);
      print('[AUTH] Token tersimpan');
      state = AuthState(accessToken: accessToken, isAuthenticated: true);
    } catch (e) {
      print('[AUTH] Gagal simpan token: $e');
      await forceLogout();
    }
  }

  Future<void> initializeAppFlow() async {
    print('\n [INIT] App launch → cek token...');
    try {
      final accessToken = await _storage.read(key: StorageKeys.accessToken);
      final refreshToken = await _storage.read(key: StorageKeys.refreshToken);

      if (accessToken == null || refreshToken == null) {
        print('[INIT] Tidak ada token > Login Screen');
        await forceLogout();
        return;
      }

      print('[INIT] Token ditemukan di storage');
      final expired = _isTokenExpired(accessToken);

      if (!expired) {
        print('[INIT] Token valid > Home Screen');
        state = AuthState(accessToken: accessToken, isAuthenticated: true);
        return;
      }
      print(' [INIT] Token expired > coba refresh...');
      await _doRefresh();
    } catch (e) {
      print(' [INIT] Error: $e');
      await forceLogout();
    }
  }

  Future<String?> _doRefresh() async {
    print(' [REFRESH] Memanggil endpoint refresh...');
    try {
      final refreshToken = await _storage.read(key: StorageKeys.refreshToken);
      if (refreshToken == null) {
        print('[REFRESH] Tidak ada refresh token → force logout');
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

      print(' [REFRESH] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken =
            data['token']?['accessToken'] ??
            data['accessToken'] ??
            data['access_token'];

        if (newAccessToken == null) {
          print('[REFRESH] accessToken tidak ada di response');
          await forceLogout();
          return null;
        }

        await _storage.write(
          key: StorageKeys.accessToken,
          value: newAccessToken,
        );
        print('[REFRESH] Token baru disimpan → Home Screen');
        state = AuthState(accessToken: newAccessToken, isAuthenticated: true);
        return newAccessToken;
      } else {
        print(' [REFRESH] Gagal (${response.statusCode}) → force logout');
        await forceLogout();
        return null;
      }
    } catch (e) {
      print(' [REFRESH] Exception: $e');
      await forceLogout();
      return null;
    }
  }

  Future<String?> refreshFromInterceptor() async {
    print(' [INTERCEPTOR→AUTH] Silent refresh dipanggil interceptor');
    return await _doRefresh();
  }

  Future<void> forceLogout() async {
    print('[AUTH] Force logout → clear storage → Login Screen');
    try {
      await _storage.deleteAll();
    } catch (_) {}
    state = AuthState(accessToken: null, isAuthenticated: false);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
