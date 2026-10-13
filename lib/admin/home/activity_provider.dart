import 'dart:convert';
import 'package:corim/admin/home/activity_model.dart';
import 'package:corim/api/api.dart';
import 'package:corim/api/auth_http_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

const int kActivityRowPerPage = 20;

class ActivityListState {
  final List<ActivityItem> items;
  final int currentPage; // halaman terakhir yang sudah termuat
  final int totalPages;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final Object? error;

  const ActivityListState({
    this.items = const [],
    this.currentPage = 0,
    this.totalPages = 1,
    this.isInitialLoading = true,
    this.isLoadingMore = false,
    this.error,
  });

  bool get hasMore => currentPage < totalPages;

  ActivityListState copyWith({
    List<ActivityItem>? items,
    int? currentPage,
    int? totalPages,
    bool? isInitialLoading,
    bool? isLoadingMore,
    Object? error,
    bool clearError = false,
  }) {
    return ActivityListState(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ActivityListNotifier extends StateNotifier<ActivityListState> {
  final Ref ref;
  int _generation = 0; // mencegah hasil request lama menimpa hasil refresh

  ActivityListNotifier(this.ref) : super(const ActivityListState()) {
    refresh();
  }

  /// Muat ulang dari halaman 1 (dipakai saat pertama buka & pull-to-refresh).
  Future<void> refresh() async {
    _generation++;
    state = const ActivityListState();
    await _fetch(1);
  }

  /// Muat 20 data berikutnya. Aman dipanggil berkali-kali.
  Future<void> loadMore() async {
    if (state.isInitialLoading || state.isLoadingMore || !state.hasMore) return;
    await _fetch(state.currentPage + 1);
  }

  Future<void> _fetch(int page) async {
    final gen = _generation;
    final isFirst = page == 1;

    state = state.copyWith(
      isInitialLoading: isFirst,
      isLoadingMore: !isFirst,
      clearError: true,
    );

    try {
      final client = ref.read(authHttpClientProvider);
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}${Endpoints.dashboardActivities}',
      ).replace(
        queryParameters: {
          'page': '$page',
          'row_per_page': '$kActivityRowPerPage',
        },
      );

      final res = await client.get(
        uri,
        headers: {'Content-Type': ApiConfig.contentTypeJson},
      );
      if (gen != _generation) return;

      if (res.statusCode != 200) {
        state = state.copyWith(
          isInitialLoading: false,
          isLoadingMore: false,
          error: 'Gagal memuat activity (${res.statusCode})',
        );
        return;
      }

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final raw = (body['data'] ?? []) as List<dynamic>;
      final newItems = raw
          .map((e) => ActivityItem.fromJson(e as Map<String, dynamic>))
          .toList();
      final meta = (body['page'] ?? {}) as Map<String, dynamic>;

      state = state.copyWith(
        items: isFirst ? newItems : [...state.items, ...newItems],
        currentPage: (meta['current_page'] as num?)?.toInt() ?? page,
        totalPages: (meta['total_pages'] as num?)?.toInt() ?? 1,
        isInitialLoading: false,
        isLoadingMore: false,
      );
    } catch (e) {
      if (gen != _generation) return;
      state = state.copyWith(
        isInitialLoading: false,
        isLoadingMore: false,
        error: e,
      );
    }
  }
}

final activityListProvider =
    StateNotifierProvider<ActivityListNotifier, ActivityListState>(
      (ref) => ActivityListNotifier(ref),
    );