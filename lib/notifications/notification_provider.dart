import 'dart:convert';
import 'package:corim/api/api.dart';
import 'package:corim/auth/auth_provider.dart';
import 'package:corim/notifications/notification_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;

Map<String, String> _headers(String token) => {
  'Content-Type': ApiConfig.contentTypeJson,
  'Access-Token': 'Bearer $token',
};

List<NotificationItem> _parseList(String responseBody) {
  final body = jsonDecode(responseBody);
  final List<dynamic> rawList = (body['data'] ?? []) as List<dynamic>;
  return rawList
      .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
      .toList();
}

class NotificationListNotifier
    extends StateNotifier<AsyncValue<List<NotificationItem>>> {
  final Ref ref;

  NotificationListNotifier(this.ref) : super(const AsyncValue.loading()) {
    fetch();
  }

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    try {
      final token = ref.read(authProvider).accessToken ?? '';
      final uri = Uri.parse('${ApiConfig.baseUrl}${Endpoints.notifications}');

      print('[NOTIF] GET $uri');
      var response = await http.get(uri, headers: _headers(token));
      print('[NOTIF] Status: ${response.statusCode}');

      if (response.statusCode == 401) {
        print('[NOTIF] 401 -> mencoba refresh token...');
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
        print('[NOTIF] Retry status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        state = AsyncValue.data(_parseList(response.body));
      } else {
        print('[NOTIF] Body: ${response.body}');
        state = AsyncValue.error(
          'Gagal memuat notifikasi (${response.statusCode})\n${response.body}',
          StackTrace.current,
        );
      }
    } catch (e, st) {
      print('[NOTIF] Exception: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> sendAction(
    String id, {
    required bool approve,
    String? note,
  }) async {
    try {
      final token = ref.read(authProvider).accessToken ?? '';
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}${Endpoints.notificationAction(id)}',
      );

      var response = await http.post(
        uri,
        headers: _headers(token),
        body: jsonEncode({
          'action': approve ? 'approve' : 'reject',
          'note': note ?? '',
        }),
      );

      if (response.statusCode == 401) {
        final newToken = await ref
            .read(authProvider.notifier)
            .refreshFromInterceptor();
        if (newToken == null) return false;

        response = await http.post(
          uri,
          headers: _headers(newToken),
          body: jsonEncode({
            'action': approve ? 'approve' : 'reject',
            'note': note ?? '',
          }),
        );
      }

      if (response.statusCode == 200) {
        state = state.whenData(
          (items) => [
            for (final n in items)
              if (n.id == id)
                n.copyWith(
                  approvalStatus: approve ? 'APPROVED' : 'REJECTED',
                  note: note,
                )
              else
                n,
          ],
        );
        return true;
      }
      print('[NOTIF] Action failed (${response.statusCode}): ${response.body}');
      return false;
    } catch (e) {
      print('[NOTIF] Action exception: $e');
      return false;
    }
  }
}

final notificationListProvider =
    StateNotifierProvider<
      NotificationListNotifier,
      AsyncValue<List<NotificationItem>>
    >((ref) => NotificationListNotifier(ref));

final pendingNotificationCountProvider = Provider<int>((ref) {
  final state = ref.watch(notificationListProvider);
  return state.maybeWhen(
    data: (items) => items.where((n) => n.isPending).length,
    orElse: () => 0,
  );
});

class NotificationDetailNotifier
    extends StateNotifier<AsyncValue<NotificationItem>> {
  final Ref ref;
  final String id;

  NotificationDetailNotifier(this.ref, this.id)
    : super(const AsyncValue.loading()) {
    fetch();
  }

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    try {
      final token = ref.read(authProvider).accessToken ?? '';
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}${Endpoints.notificationDetail(id)}',
      );

      print('[NOTIF DETAIL] GET $uri');
      var response = await http.get(uri, headers: _headers(token));
      print('[NOTIF DETAIL] Status: ${response.statusCode}');

      if (response.statusCode == 401) {
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
      }

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'];
        final map = data is List
            ? (data.isNotEmpty ? data.first : <String, dynamic>{})
            : data;
        state = AsyncValue.data(
          NotificationItem.fromJson(Map<String, dynamic>.from(map ?? {})),
        );
      } else {
        print('[NOTIF DETAIL] Body: ${response.body}');
        state = AsyncValue.error(
          'Gagal memuat detail (${response.statusCode})\n${response.body}',
          StackTrace.current,
        );
      }
    } catch (e, st) {
      print('[NOTIF DETAIL] Exception: $e');
      state = AsyncValue.error(e, st);
    }
  }
}

final notificationDetailProvider =
    StateNotifierProvider.family<
      NotificationDetailNotifier,
      AsyncValue<NotificationItem>,
      String
    >((ref, id) => NotificationDetailNotifier(ref, id));
