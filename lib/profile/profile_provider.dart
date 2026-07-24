import 'dart:convert';

import 'package:corim/api/api.dart';
import 'package:corim/api/auth_http_client.dart';
import 'package:corim/profile/profile_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileProvider = FutureProvider.autoDispose<ProfileData>((ref) async {
  final client = ref.watch(authHttpClientProvider);

  final response = await client.get(
    Uri.parse('${ApiConfig.baseUrl}${Endpoints.profile}'),
    headers: {'Content-Type': ApiConfig.contentTypeJson},
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to load profile (${response.statusCode})');
  }

  final body = jsonDecode(response.body) as Map<String, dynamic>;
  final data = body['data'] as Map<String, dynamic>? ?? {};
  return ProfileData.fromJson(data);
});
