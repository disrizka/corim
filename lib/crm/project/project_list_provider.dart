import 'dart:convert';
import 'package:corim/api/api.dart';
import 'package:corim/api/auth_http_client.dart';
import 'package:corim/crm/client_detail/project_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

class ProjectStatusSummary {
  final int newProject;
  final int ontimeProject;
  final int delayProject;

  const ProjectStatusSummary({
    required this.newProject,
    required this.ontimeProject,
    required this.delayProject,
  });
}

const _monthMap = {
  'jan': 1,
  'feb': 2,
  'mar': 3,
  'apr': 4,
  'may': 5,
  'jun': 6,
  'jul': 7,
  'aug': 8,
  'sep': 9,
  'oct': 10,
  'nov': 11,
  'dec': 12,
};

DateTime? _parseApiDate(String raw) {
  final value = raw.trim();
  if (value.isEmpty || value == '-') return null;

  final parts = value.split(RegExp(r'\s+'));
  if (parts.length != 3) return null;

  final day = int.tryParse(parts[0]);
  final month =
      _monthMap[parts[1].toLowerCase().substring(
        0,
        parts[1].length >= 3 ? 3 : parts[1].length,
      )];
  final year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null) return null;

  return DateTime(year, month, day);
}

class _ProjectPage {
  final List<ProjectListItem> items;
  final int totalPages;

  const _ProjectPage({required this.items, required this.totalPages});
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

  return _ProjectPage(items: items, totalPages: totalPages);
}

class ProjectListPagingState {
  final List<ProjectListItem> items;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final String? error;

  const ProjectListPagingState({
    this.items = const [],
    this.isInitialLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 0,
    this.error,
  });

  ProjectListPagingState copyWith({
    List<ProjectListItem>? items,
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    String? error,
  }) {
    return ProjectListPagingState(
      items: items ?? this.items,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: error,
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

// Summary langsung dihitung dari paging state tanpa memicu request ekstra ke seluruh database
final projectStatusSummaryProvider = Provider.autoDispose<ProjectStatusSummary>(
  (ref) {
    final pagingState = ref.watch(projectListPagingProvider);
    final projects = pagingState.items;

    int newCount = 0;
    int ontimeCount = 0;
    int delayCount = 0;

    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);

    for (final p in projects) {
      final status = p.projectStatus.toLowerCase();
      if (status == 'won') continue;

      final endDate = _parseApiDate(p.expectedEndDate);
      if (endDate == null) {
        newCount++;
      } else if (endDate.isBefore(todayDateOnly)) {
        delayCount++;
      } else {
        ontimeCount++;
      }
    }

    return ProjectStatusSummary(
      newProject: newCount,
      ontimeProject: ontimeCount,
      delayProject: delayCount,
    );
  },
);
