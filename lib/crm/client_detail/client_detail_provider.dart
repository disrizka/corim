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

final clientProjectListProvider = FutureProvider.autoDispose
    .family<List<ProjectListItem>, String>((ref, companyName) async {
      final client = ref.read(authHttpClientProvider);
      final res = await client.get(
        Uri.parse('${ApiConfig.baseUrl}${Endpoints.projects}'),
      );
      final body = jsonDecode(res.body);
      if (body['status'] == 200) {
        final all = (body['data'] as List)
            .map((e) => ProjectListItem.fromJson(e))
            .toList();
        return all
            .where(
              (p) => p.clientName.toLowerCase() == companyName.toLowerCase(),
            )
            .toList();
      }
      throw Exception('Gagal memuat data project');
    });
