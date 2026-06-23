import 'package:corim/api/api.dart';
import 'package:corim/auth/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final Ref _ref;

  ApiService(this._ref);

  Future<http.Response?> get(String endpoint) async {
    await _ref.read(authProvider.notifier).initializeAppFlow();

    String? token = _ref.read(authProvider).accessToken;
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    var response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': ApiConfig.contentTypeJson,
      },
    );

    if (response.statusCode == 401) {
      final newToken = await _ref
          .read(authProvider.notifier)
          .refreshAccessToken();

      if (newToken != null) {
        response = await http.get(
          url,
          headers: {
            'Authorization': 'Bearer $newToken',
            'Content-Type': ApiConfig.contentTypeJson,
          },
        );
      }
    }

    return response;
  }
}

final apiServiceProvider = Provider((ref) => ApiService(ref));
