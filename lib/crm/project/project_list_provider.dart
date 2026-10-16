import 'dart:convert';
import 'package:corim/api/api.dart';
import 'package:corim/api/auth_http_client.dart';
import 'package:corim/crm/client_detail/project_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

class ProjectStats {
  final int newProject;
  final int onTimeProject;
  final int delayProject;
  final int wonProject;
  final int lossProject;

  const ProjectStats({
    this.newProject = 0,
    this.onTimeProject = 0,
    this.delayProject = 0,
    this.wonProject = 0,
    this.lossProject = 0,
  });

  factory ProjectStats.fromJson(Map<String, dynamic> json) {
    int n(dynamic v) => (v as num?)?.toInt() ?? 0;
    return ProjectStats(
      newProject: n(json['newProject']),
      onTimeProject: n(json['onTimeProject'] ?? json['ontimeProject']),
      delayProject: n(json['delayProject']),
      wonProject: n(json['wonProject']),
      lossProject: n(json['lossProject']),
    );
  }
}

class _ProjectPage {
  final List<ProjectListItem> items;
  final int totalPages;
  final ProjectStats? stats;

  const _ProjectPage({
    required this.items,
    required this.totalPages,
    this.stats,
  });
}

Future<_ProjectPage> _fetchProjectPage(
  AuthHttpClient client,
  int page, {
  int limit = 20,
}) async {
  final res = await client.get(
    Uri.parse(
      '${ApiConfig.baseUrl}${Endpoints.projects}',
    ).replace(queryParameters: {'page': '$page', 'limit': '$limit'}),
  );

  final body = jsonDecode(res.body);
  if (body['status'] != 200) {
    throw Exception(body['message'] ?? 'Gagal memuat data project');
  }

  final data = (body['data'] as List? ?? []);
  final items = data.map((e) => ProjectListItem.fromJson(e)).toList();
  final totalPages = (body['page']?['total_pages'] as num?)?.toInt() ?? 1;

  final rawStats = body['stats'];
  final stats = rawStats is Map<String, dynamic>
      ? ProjectStats.fromJson(rawStats)
      : null;

  return _ProjectPage(items: items, totalPages: totalPages, stats: stats);
}

class ProjectListPagingState {
  final List<ProjectListItem> items;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final String? error;

  /// Statistik global dari API (`stats`). null = belum ada / tidak dikirim.
  final ProjectStats? stats;

  const ProjectListPagingState({
    this.items = const [],
    this.isInitialLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 0,
    this.error,
    this.stats,
  });

  ProjectListPagingState copyWith({
    List<ProjectListItem>? items,
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    String? error,
    ProjectStats? stats,
  }) {
    return ProjectListPagingState(
      items: items ?? this.items,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: error,
      stats: stats ?? this.stats,
    );
  }
}

class ProjectListPagingNotifier extends StateNotifier<ProjectListPagingState> {
  final Ref ref;

  ProjectListPagingNotifier(this.ref) : super(const ProjectListPagingState()) {
    _loadFirstPage();
  }

  Future<void> _loadFirstPage() async {
    state = const ProjectListPagingState(isInitialLoading: true);
    try {
      final client = ref.read(authHttpClientProvider);
      final result = await _fetchProjectPage(client, 1, limit: 20);
      state = ProjectListPagingState(
        items: result.items,
        isInitialLoading: false,
        page: 1,
        hasMore: 1 < result.totalPages && result.items.length == 20,
        stats: result.stats,
      );
    } catch (e) {
      state = ProjectListPagingState(isInitialLoading: false, error: '$e');
    }
  }

  Future<void> loadMore() async {
    if (state.isInitialLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final client = ref.read(authHttpClientProvider);
      final nextPage = state.page + 1;
      final result = await _fetchProjectPage(client, nextPage, limit: 20);
      state = state.copyWith(
        items: [...state.items, ...result.items],
        isLoadingMore: false,
        page: nextPage,
        hasMore: nextPage < result.totalPages && result.items.length == 20,
        stats: result.stats,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> refresh() => _loadFirstPage();
}

final projectListPagingProvider =
    StateNotifierProvider.autoDispose<
      ProjectListPagingNotifier,
      ProjectListPagingState
    >((ref) => ProjectListPagingNotifier(ref));

final projectStatsProvider = Provider.autoDispose<ProjectStats?>((ref) {
  return ref.watch(projectListPagingProvider.select((s) => s.stats));
});
