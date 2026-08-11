import 'dart:convert';
import 'package:corim/api/api.dart';
import 'package:corim/api/auth_http_client.dart';
import 'package:corim/crm/client_list/client_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

enum ClientPhase { leads, account, stages }

extension ClientPhaseX on ClientPhase {
  String get apiValue {
    switch (this) {
      case ClientPhase.leads:
        return 'leads';
      case ClientPhase.account:
        return 'account';
      case ClientPhase.stages:
        return 'stages';
    }
  }

  String get label {
    switch (this) {
      case ClientPhase.leads:
        return 'LEADS';
      case ClientPhase.account:
        return 'ACCOUNT';
      case ClientPhase.stages:
        return 'STAGES';
    }
  }
}

class ClientPagingState {
  final List<ClientModel> items;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final int totalRows;
  final String? error;

  const ClientPagingState({
    this.items = const [],
    this.isInitialLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 0,
    this.totalRows = 0,
    this.error,
  });

  ClientPagingState copyWith({
    List<ClientModel>? items,
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    int? totalRows,
    String? error,
  }) {
    return ClientPagingState(
      items: items ?? this.items,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      totalRows: totalRows ?? this.totalRows,
      error: error,
    );
  }
}

class ClientListPagingNotifier extends StateNotifier<ClientPagingState> {
  final Ref ref;
  final ClientPhase phase;

  ClientListPagingNotifier(this.ref, this.phase)
    : super(const ClientPagingState()) {
    _loadFirstPage();
  }

  Future<void> _loadFirstPage() async {
    state = const ClientPagingState(isInitialLoading: true);
    try {
      final httpClient = ref.read(authHttpClientProvider);
      final response = await httpClient.get(
        Uri.parse(
          '${ApiConfig.baseUrl}${Endpoints.clients}?phase=${phase.apiValue}&page=1&limit=20',
        ),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> rawList = (body['data'] ?? []) as List<dynamic>;
        final clients = rawList
            .map((e) => ClientModel.fromJson(e as Map<String, dynamic>))
            .toList();

        final totalRows =
            (body['page']?['total_rows'] as num?)?.toInt() ?? clients.length;
        final totalPages = (body['page']?['total_pages'] as num?)?.toInt() ?? 1;

        state = ClientPagingState(
          items: clients,
          isInitialLoading: false,
          page: 1,
          totalRows: totalRows,
          hasMore: 1 < totalPages && clients.length == 20,
        );
      } else {
        state = ClientPagingState(
          isInitialLoading: false,
          error: 'Gagal memuat data (${response.statusCode})',
        );
      }
    } catch (e) {
      state = ClientPagingState(isInitialLoading: false, error: '$e');
    }
  }

  Future<void> loadMore() async {
    if (state.isInitialLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final httpClient = ref.read(authHttpClientProvider);
      final nextPage = state.page + 1;
      final response = await httpClient.get(
        Uri.parse(
          '${ApiConfig.baseUrl}${Endpoints.clients}?phase=${phase.apiValue}&page=$nextPage&limit=20',
        ),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> rawList = (body['data'] ?? []) as List<dynamic>;
        final newClients = rawList
            .map((e) => ClientModel.fromJson(e as Map<String, dynamic>))
            .toList();

        final totalPages =
            (body['page']?['total_pages'] as num?)?.toInt() ?? nextPage;

        state = state.copyWith(
          items: [...state.items, ...newClients],
          isLoadingMore: false,
          page: nextPage,
          hasMore: nextPage < totalPages && newClients.length == 20,
        );
      } else {
        state = state.copyWith(isLoadingMore: false);
      }
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> refresh() => _loadFirstPage();
}

final clientListPagingProvider = StateNotifierProvider.family
    .autoDispose<ClientListPagingNotifier, ClientPagingState, ClientPhase>(
      (ref, phase) => ClientListPagingNotifier(ref, phase),
    );

// Pasang provider summary agar lazy-load per-phase tanpa memaksa 3 HTTP request di awal secara bersamaan
final clientPhaseSummaryProvider = Provider.family<int?, ClientPhase>((
  ref,
  phase,
) {
  final paging = ref.watch(clientListPagingProvider(phase));
  return paging.isInitialLoading ? null : paging.totalRows;
});
