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

class ProjectSalesStatusNotifier
    extends StateNotifier<AsyncValue<List<SalesStatusEvent>>> {
  final Ref ref;
  final String id;

  ProjectSalesStatusNotifier(this.ref, this.id)
    : super(const AsyncValue.loading()) {
    fetch();
  }

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    try {
      final token = ref.read(authProvider).accessToken ?? '';
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}${Endpoints.projectSalesStatusQuotations(id)}',
      );

      print('[PROJECT SALES STATUS] GET $uri');
      var response = await http.get(uri, headers: _headers(token));
      print('[PROJECT SALES STATUS] Status: ${response.statusCode}');

      if (response.statusCode == 401) {
        print('[PROJECT SALES STATUS] 401 -> mencoba refresh token...');
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
        print('[PROJECT SALES STATUS] Retry status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final rawList = (body['data'] is List)
            ? body['data'] as List
            : const [];
        final events =
            rawList
                .map(
                  (e) => SalesStatusEvent.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ),
                )
                .toList()
              ..sort((a, b) {
                final ad = a.createdAt;
                final bd = b.createdAt;
                if (ad == null && bd == null) return 0;
                if (ad == null) return 1;
                if (bd == null) return -1;
                return ad.compareTo(bd);
              });
        state = AsyncValue.data(events);
      } else if (response.statusCode == 404) {
        state = const AsyncValue.data([]);
      } else {
        print('[PROJECT SALES STATUS] Body: ${response.body}');
        state = AsyncValue.error(
          'Gagal memuat sales status (${response.statusCode})\n${response.body}',
          StackTrace.current,
        );
      }
    } catch (e, st) {
      print('[PROJECT SALES STATUS] Exception: $e');
      state = AsyncValue.error(e, st);
    }
  }
}

final projectSalesStatusProvider =
    StateNotifierProvider.family<
      ProjectSalesStatusNotifier,
      AsyncValue<List<SalesStatusEvent>>,
      String
    >((ref, id) => ProjectSalesStatusNotifier(ref, id));

class ProjectDeliveryStatusNotifier
    extends StateNotifier<AsyncValue<List<DeliveryStatusEvent>>> {
  final Ref ref;
  final String id;

  ProjectDeliveryStatusNotifier(this.ref, this.id)
    : super(const AsyncValue.loading()) {
    fetch();
  }

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    try {
      final token = ref.read(authProvider).accessToken ?? '';
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}${Endpoints.projectDeliveryStatus(id)}',
      );

      print('[PROJECT DELIVERY STATUS] GET $uri');
      var response = await http.get(uri, headers: _headers(token));
      print('[PROJECT DELIVERY STATUS] Status: ${response.statusCode}');

      if (response.statusCode == 401) {
        print('[PROJECT DELIVERY STATUS] 401 -> mencoba refresh token...');
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
        print('[PROJECT DELIVERY STATUS] Retry status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final rawList = (body['data'] is List)
            ? body['data'] as List
            : const [];
        final events = rawList
            .map(
              (e) => DeliveryStatusEvent.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();
        state = AsyncValue.data(events);
      } else if (response.statusCode == 404) {
        state = const AsyncValue.data([]);
      } else {
        print('[PROJECT DELIVERY STATUS] Body: ${response.body}');
        state = AsyncValue.error(
          'Gagal memuat delivery status (${response.statusCode})\n${response.body}',
          StackTrace.current,
        );
      }
    } catch (e, st) {
      print('[PROJECT DELIVERY STATUS] Exception: $e');
      state = AsyncValue.error(e, st);
    }
  }
}

final projectDeliveryStatusProvider =
    StateNotifierProvider.family<
      ProjectDeliveryStatusNotifier,
      AsyncValue<List<DeliveryStatusEvent>>,
      String
    >((ref, id) => ProjectDeliveryStatusNotifier(ref, id));
