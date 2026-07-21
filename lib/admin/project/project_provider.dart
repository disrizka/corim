import 'dart:convert';
import 'package:corim/admin/project/project_model.dart';
import 'package:corim/api/api.dart';
import 'package:corim/auth/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;

Map<String, String> _headers(String token) => {
  'Content-Type': ApiConfig.contentTypeJson,
  'Access-Token': 'Bearer $token',
};

class ProjectDetailNotifier extends StateNotifier<AsyncValue<ProjectDetail>> {
  final Ref ref;
  final String id;

  ProjectDetailNotifier(this.ref, this.id) : super(const AsyncValue.loading()) {
    fetch();
  }

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    try {
      final token = ref.read(authProvider).accessToken ?? '';
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}${Endpoints.projectDetail(id)}',
      );

      print('[PROJECT DETAIL] GET $uri');
      var response = await http.get(uri, headers: _headers(token));
      print('[PROJECT DETAIL] Status: ${response.statusCode}');

      if (response.statusCode == 401) {
        print('[PROJECT DETAIL] 401 -> mencoba refresh token...');
        final newToken = await ref
            .read(authProvider.notifier)
            .refreshFromInterceptor();

        if (newToken == null) {
          state = AsyncValue.error(
            'Sesi berakhir, silakan login kembali',
            StackTrace.current,
          );
          return;
        }

        response = await http.get(uri, headers: _headers(newToken));
        print('[PROJECT DETAIL] Retry status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'];
        state = AsyncValue.data(
          ProjectDetail.fromJson(Map<String, dynamic>.from(data ?? {})),
        );
      } else {
        print('[PROJECT DETAIL] Body: ${response.body}');
        state = AsyncValue.error(
          'Gagal memuat detail proyek (${response.statusCode})\n${response.body}',
          StackTrace.current,
        );
      }
    } catch (e, st) {
      print('[PROJECT DETAIL] Exception: $e');
      state = AsyncValue.error(e, st);
    }
  }
}

final projectDetailProvider =
    StateNotifierProvider.family<
      ProjectDetailNotifier,
      AsyncValue<ProjectDetail>,
      String
    >((ref, id) => ProjectDetailNotifier(ref, id));
