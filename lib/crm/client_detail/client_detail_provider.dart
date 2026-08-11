import 'dart:convert';

import 'package:corim/api/api.dart';
import 'package:corim/api/auth_http_client.dart';
import 'package:corim/crm/client_detail/client_detail_model.dart';
import 'package:corim/crm/client_detail/project_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final clientDetailProvider = FutureProvider.autoDispose
    .family<ClientDetailModel, String>((ref, id) async {
      final client = ref.read(authHttpClientProvider);
      final res = await client.get(
        Uri.parse('${ApiConfig.baseUrl}${Endpoints.clientDetail(id)}'),
      );
      final body = jsonDecode(res.body);
      if (body['status'] == 200) {
        return ClientDetailModel.fromJson(body['data']);
      }
      throw Exception(body['message'] ?? 'Gagal memuat detail client');
    });

// Mengambil list project khusus client secara langsung & cepat
final clientProjectListProvider = FutureProvider.autoDispose
    .family<List<ProjectListItem>, String>((ref, companyName) async {
      if (companyName.trim().isEmpty) return [];

      final client = ref.read(authHttpClientProvider);
      final res = await client.get(
        Uri.parse(
          '${ApiConfig.baseUrl}${Endpoints.projects}',
        ).replace(queryParameters: {'limit': '50'}),
      );

      final body = jsonDecode(res.body);
      if (body['status'] != 200) {
        throw Exception(body['message'] ?? 'Gagal memuat project client');
      }

      final data = (body['data'] as List? ?? []);
      final items = data.map((e) => ProjectListItem.fromJson(e)).toList();

      return items
          .where((p) => p.clientName.toLowerCase() == companyName.toLowerCase())
          .toList();
    });
