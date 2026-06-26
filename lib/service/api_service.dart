import 'dart:convert';
import 'package:corim/api/api.dart';
import 'package:corim/auth/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final Ref _ref;

  ApiService(this._ref);

  Future<http.Response?> get(String endpoint) async {
    String? token = _ref.read(authProvider).accessToken;
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    print('📤 [API] GET $endpoint');

    var response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': ApiConfig.contentTypeJson,
      },
    );

    print('📥 [API] Status: ${response.statusCode}');

    if (response.statusCode == 401) {
      print('⚠️ [API] 401 → mencoba silent refresh...');

      final newToken = await _ref
          .read(authProvider.notifier)
          .refreshFromInterceptor();

      if (newToken != null) {
        print('🔁 [API] Retry dengan token baru...');
        response = await http.get(
          url,
          headers: {
            'Authorization': 'Bearer $newToken',
            'Content-Type': ApiConfig.contentTypeJson,
          },
        );
        print('✅ [API] Retry status: ${response.statusCode}');
      } else {
        print('❌ [API] Refresh gagal → user diarahkan ke Login');
        return null;
      }
    }
    return response;
  }

  Future<http.Response?> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    String? token = _ref.read(authProvider).accessToken;
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    print('📤 [API] POST $endpoint');
    var response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': ApiConfig.contentTypeJson,
      },
      body: jsonEncode(body),
    );

    print('📥 [API] Status: ${response.statusCode}');

    if (response.statusCode == 401) {
      print('⚠️ [API] 401 → mencoba silent refresh...');

      final newToken = await _ref
          .read(authProvider.notifier)
          .refreshFromInterceptor();

      if (newToken != null) {
        print('🔁 [API] Retry POST dengan token baru...');
        response = await http.post(
          url,
          headers: {
            'Authorization': 'Bearer $newToken',
            'Content-Type': ApiConfig.contentTypeJson,
          },
          body: jsonEncode(body),
        );
        print('✅ [API] Retry status: ${response.statusCode}');
      } else {
        print('❌ [API] Refresh gagal → user diarahkan ke Login');
        return null;
      }
    }

    return response;
  }
}

final apiServiceProvider = Provider((ref) => ApiService(ref));
