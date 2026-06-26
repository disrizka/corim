import 'dart:convert';
import 'package:corim/api/api.dart';
import 'package:corim/auth/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthHttpClient extends http.BaseClient {
  final http.Client _inner;
  final Ref _ref;
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  bool _isRefreshing = false;

  AuthHttpClient(this._inner, this._ref);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final accessToken = await _storage.read(key: StorageKeys.accessToken);

    if (accessToken != null) {
      request.headers['Authorization'] = 'Bearer $accessToken';
      print('[INTERCEPTOR] ${request.method} ${request.url}');
      print('[INTERCEPTOR] Token: ${accessToken.substring(0, 20)}...');
    }

    final response = await _inner.send(request);
    print('[INTERCEPTOR] Status ${response.statusCode} ← ${request.url}');
    if (response.statusCode == 401 && !_isRefreshing) {
      print('[INTERCEPTOR] 401 → silent refresh...');
      return await _handleUnauthorized(request, response);
    }

    return response;
  }

  Future<http.StreamedResponse> _handleUnauthorized(
    http.BaseRequest originalRequest,
    http.StreamedResponse originalResponse,
  ) async {
    _isRefreshing = true;
    print('[INTERCEPTOR] Request dibekukan → refresh dulu...');

    try {
      final newToken = await _ref
          .read(authProvider.notifier)
          .refreshFromInterceptor();

      if (newToken == null) {
        print(' [INTERCEPTOR] Session Dead → Force Logout');
        return originalResponse;
      }

      print('[INTERCEPTOR] Retry request dengan token baru...');
      final retryRequest = _cloneRequest(originalRequest, newToken);
      final retryResponse = await _inner.send(retryRequest);
      print('[INTERCEPTOR] Retry ${retryResponse.statusCode} → data ke user');
      return retryResponse;
    } catch (e) {
      print('[INTERCEPTOR] Exception: $e');
      _ref.read(authProvider.notifier).forceLogout();
      return originalResponse;
    } finally {
      _isRefreshing = false;
    }
  }

  http.BaseRequest _cloneRequest(http.BaseRequest original, String newToken) {
    final clone = http.Request(original.method, original.url);
    clone.headers.addAll(original.headers);
    clone.headers['Authorization'] = 'Bearer $newToken';
    if (original is http.Request) {
      clone.body = original.body;
    }
    return clone;
  }
}

final authHttpClientProvider = Provider<AuthHttpClient>((ref) {
  return AuthHttpClient(http.Client(), ref);
});
