import 'dart:convert';
import 'package:corim/api/api.dart';
import 'package:corim/auth/auth_provider.dart';
import 'package:corim/notifications/notification_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;

const int kNotificationRowPerPage = 20;

Map<String, String> _headers(String token) => {
  'Content-Type': ApiConfig.contentTypeJson,
  'Access-Token': 'Bearer $token',
};

class NotificationPageMeta {
  final int currentPage;
  final int totalPages;
  final int totalRows;
  final int rowPerPage;

  const NotificationPageMeta({
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalRows = 0,
    this.rowPerPage = kNotificationRowPerPage,
  });

  factory NotificationPageMeta.fromJson(Map<String, dynamic> json) {
    return NotificationPageMeta(
      currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
      totalPages: (json['total_pages'] as num?)?.toInt() ?? 1,
      totalRows: (json['total_rows'] as num?)?.toInt() ?? 0,
      rowPerPage:
          (json['row_per_page'] as num?)?.toInt() ?? kNotificationRowPerPage,
    );
  }
}

class NotificationListState {
  final Map<int, List<NotificationItem>> pages;
  final Set<int> loadingPages;
  final Set<int> failedPages;
  final NotificationPageMeta meta;
  final Object? error;
  final bool isInitialLoading;

  const NotificationListState({
    this.pages = const {},
    this.loadingPages = const {},
    this.failedPages = const {},
    this.meta = const NotificationPageMeta(),
    this.error,
    this.isInitialLoading = true,
  });

  List<NotificationItem> pageItems(int page) => pages[page] ?? const [];

  bool isPageLoaded(int page) => pages.containsKey(page);

  bool isPageLoading(int page) => loadingPages.contains(page);
  bool didPageFail(int page) => failedPages.contains(page);
  List<NotificationItem> get loadedItems =>
      pages.values.expand((e) => e).toList();

  NotificationListState copyWith({
    Map<int, List<NotificationItem>>? pages,
    Set<int>? loadingPages,
    Set<int>? failedPages,
    NotificationPageMeta? meta,
    Object? error,
    bool clearError = false,
    bool? isInitialLoading,
  }) {
    return NotificationListState(
      pages: pages ?? this.pages,
      loadingPages: loadingPages ?? this.loadingPages,
      failedPages: failedPages ?? this.failedPages,
      meta: meta ?? this.meta,
      error: clearError ? null : (error ?? this.error),
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
    );
  }
}

class NotificationListNotifier extends StateNotifier<NotificationListState> {
  final Ref ref;

  NotificationListNotifier(this.ref) : super(const NotificationListState()) {
    fetchPage(1);
  }

  Future<void> fetchPage(int page, {bool forceRefresh = false}) async {
    if (!forceRefresh &&
        (state.isPageLoaded(page) || state.isPageLoading(page))) {
      return;
    }

    state = state.copyWith(
      loadingPages: {...state.loadingPages, page},
      failedPages: Set<int>.from(state.failedPages)..remove(page),
      clearError: true,
    );

    try {
      final token = ref.read(authProvider).accessToken ?? '';
      final uri = Uri.parse('${ApiConfig.baseUrl}${Endpoints.notifications}')
          .replace(
            queryParameters: {
              'page': '$page',
              'row_per_page': '$kNotificationRowPerPage',
            },
          );

      print('[NOTIF] GET $uri');
      var response = await http.get(uri, headers: _headers(token));
      print('[NOTIF] Status: ${response.statusCode}');

      if (response.statusCode == 401) {
        print('[NOTIF] 401 -> mencoba refresh token...');
        final newToken = await ref
            .read(authProvider.notifier)
            .refreshFromInterceptor();

        if (newToken == null) {
          state = state.copyWith(
            loadingPages: state.loadingPages.difference({page}),
            failedPages: {...state.failedPages, page},
            error: 'Sesi berakhir, silakan login kembali',
            isInitialLoading: false,
          );
          return;
        }

        response = await http.get(uri, headers: _headers(newToken));
        print('[NOTIF] Retry status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> rawList = (body['data'] ?? []) as List<dynamic>;
        final items = rawList
            .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
            .toList();
        final meta = NotificationPageMeta.fromJson(
          (body['page'] ?? {}) as Map<String, dynamic>,
        );

        final newPages = Map<int, List<NotificationItem>>.from(state.pages)
          ..[page] = items;
        final newLoading = Set<int>.from(state.loadingPages)..remove(page);

        state = state.copyWith(
          pages: newPages,
          loadingPages: newLoading,
          meta: meta,
          clearError: true,
          isInitialLoading: false,
        );
      } else {
        print('[NOTIF] Body: ${response.body}');
        final newLoading = Set<int>.from(state.loadingPages)..remove(page);
        state = state.copyWith(
          loadingPages: newLoading,
          failedPages: {...state.failedPages, page},
          error:
              'Gagal memuat notifikasi (${response.statusCode})\n${response.body}',
          isInitialLoading: false,
        );
      }
    } catch (e, st) {
      print('[NOTIF] Exception: $e');
      final newLoading = Set<int>.from(state.loadingPages)..remove(page);
      state = state.copyWith(
        loadingPages: newLoading,
        failedPages: {...state.failedPages, page},
        error: e,
        isInitialLoading: false,
      );
      print('[NOTIF] Stack: $st');
    }
  }

  Future<void> fetch() async {
    state = const NotificationListState();
    await fetchPage(1, forceRefresh: true);
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
        final newPages = <int, List<NotificationItem>>{
          for (final entry in state.pages.entries)
            entry.key: [
              for (final n in entry.value)
                if (n.id == id)
                  n.copyWith(
                    approvalStatus: approve ? 'APPROVED' : 'REJECTED',
                    note: note,
                  )
                else
                  n,
            ],
        };
        state = state.copyWith(pages: newPages);
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
    StateNotifierProvider<NotificationListNotifier, NotificationListState>(
      (ref) => NotificationListNotifier(ref),
    );

final pendingNotificationCountProvider = Provider<int>((ref) {
  final state = ref.watch(notificationListProvider);
  return state.loadedItems.where((n) => n.isPending).length;
});

final expenseRequestListProvider = Provider<AsyncValue<List<NotificationItem>>>(
  (ref) {
    final state = ref.watch(notificationListProvider);

    if (state.error != null && state.pages.isEmpty) {
      return AsyncValue.error(state.error!, StackTrace.current);
    }
    if (state.isInitialLoading) {
      return const AsyncValue.loading();
    }

    final expenseItems = state.loadedItems
        .where((n) => n.isExpenseRequest)
        .toList();
    return AsyncValue.data(expenseItems);
  },
);

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
