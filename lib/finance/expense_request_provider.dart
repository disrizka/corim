import 'dart:convert';
import 'package:corim/api/api.dart';
import 'package:corim/auth/auth_provider.dart';
import 'package:corim/finance/expense_request_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;

const int kExpenseRequestRowPerPage = 20;

Map<String, String> _headers(String token) => {
  'Content-Type': ApiConfig.contentTypeJson,
  'Access-Token': 'Bearer $token',
};

class ExpenseRequestFilter {
  final String search;
  final String status;
  final String formType;

  const ExpenseRequestFilter({
    this.search = '',
    this.status = '',
    this.formType = '',
  });

  ExpenseRequestFilter copyWith({
    String? search,
    String? status,
    String? formType,
  }) {
    return ExpenseRequestFilter(
      search: search ?? this.search,
      status: status ?? this.status,
      formType: formType ?? this.formType,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ExpenseRequestFilter &&
      other.search == search &&
      other.status == status &&
      other.formType == formType;

  @override
  int get hashCode => Object.hash(search, status, formType);
}

class ExpenseRequestPageMeta {
  final int currentPage;
  final int totalPages;
  final int totalRows;
  final int rowPerPage;

  const ExpenseRequestPageMeta({
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalRows = 0,
    this.rowPerPage = kExpenseRequestRowPerPage,
  });

  factory ExpenseRequestPageMeta.fromJson(Map<String, dynamic> json) {
    return ExpenseRequestPageMeta(
      currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
      totalPages: (json['total_pages'] as num?)?.toInt() ?? 1,
      totalRows: (json['total_rows'] as num?)?.toInt() ?? 0,
      rowPerPage:
          (json['row_per_page'] as num?)?.toInt() ?? kExpenseRequestRowPerPage,
    );
  }
}

class ExpenseRequestListState {
  final List<ExpenseRequestItem> items;
  final ExpenseRequestPageMeta meta;
  final ExpenseRequestFilter filter;
  final bool isLoading;
  final bool isLoadingMore;
  final Object? error;

  const ExpenseRequestListState({
    this.items = const [],
    this.meta = const ExpenseRequestPageMeta(),
    this.filter = const ExpenseRequestFilter(),
    this.isLoading = true,
    this.isLoadingMore = false,
    this.error,
  });

  bool get hasNextPage => meta.currentPage < meta.totalPages;
  bool get hasPrevPage => meta.currentPage > 1;

  ExpenseRequestListState copyWith({
    List<ExpenseRequestItem>? items,
    ExpenseRequestPageMeta? meta,
    ExpenseRequestFilter? filter,
    bool? isLoading,
    bool? isLoadingMore,
    Object? error,
    bool clearError = false,
  }) {
    return ExpenseRequestListState(
      items: items ?? this.items,
      meta: meta ?? this.meta,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ExpenseRequestListNotifier
    extends StateNotifier<ExpenseRequestListState> {
  final Ref ref;

  ExpenseRequestListNotifier(this.ref)
    : super(const ExpenseRequestListState()) {
    fetchPage(1);
  }

  Future<void> fetchPage(int page) async {
    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      clearError: true,
    );

    try {
      final token = ref.read(authProvider).accessToken ?? '';
      final uri = Uri.parse('${ApiConfig.baseUrl}${Endpoints.expensesEmployee}')
          .replace(
            queryParameters: {
              'page': '$page',
              'limit': '$kExpenseRequestRowPerPage',
              'search': state.filter.search,
              'status': state.filter.status,
              'formType': state.filter.formType,
            },
          );

      print('[EXPENSE] GET $uri');
      var response = await http.get(uri, headers: _headers(token));
      print('[EXPENSE] Status: ${response.statusCode}');

      if (response.statusCode == 401) {
        final newToken = await ref
            .read(authProvider.notifier)
            .refreshFromInterceptor();
        if (newToken == null) {
          state = state.copyWith(
            isLoading: false,
            error: 'Sesi berakhir, silakan login kembali',
          );
          return;
        }
        response = await http.get(uri, headers: _headers(newToken));
      }

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> rawList = (body['data'] ?? []) as List<dynamic>;
        final items = rawList
            .map((e) => ExpenseRequestItem.fromJson(e as Map<String, dynamic>))
            .toList();
        final meta = ExpenseRequestPageMeta.fromJson(
          (body['page'] ?? {}) as Map<String, dynamic>,
        );

        state = state.copyWith(
          items: items,
          meta: meta,
          isLoading: false,
          clearError: true,
        );
      } else {
        print('[EXPENSE] Body: ${response.body}');
        state = state.copyWith(
          isLoading: false,
          error:
              'Gagal memuat daftar expense request (${response.statusCode})\n${response.body}',
        );
      }
    } catch (e, st) {
      print('[EXPENSE] Exception: $e');
      print('[EXPENSE] Stack: $st');
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> refresh() => fetchPage(state.meta.currentPage);

  Future<void> nextPage() async {
    if (!state.hasNextPage) return;
    await fetchPage(state.meta.currentPage + 1);
  }

  Future<void> prevPage() async {
    if (!state.hasPrevPage) return;
    await fetchPage(state.meta.currentPage - 1);
  }

  Future<void> goToPage(int page) async {
    if (page < 1 ||
        page > state.meta.totalPages ||
        page == state.meta.currentPage) {
      return;
    }
    await fetchPage(page);
  }

  Future<void> applyFilter(ExpenseRequestFilter filter) async {
    if (filter == state.filter) return;
    state = state.copyWith(filter: filter);
    await fetchPage(1);
  }
}

final expenseRequestListProvider =
    StateNotifierProvider<ExpenseRequestListNotifier, ExpenseRequestListState>(
      (ref) => ExpenseRequestListNotifier(ref),
    );

class ExpenseRequestDetailNotifier
    extends StateNotifier<AsyncValue<ExpenseRequestDetail>> {
  final Ref ref;
  final String id;

  ExpenseRequestDetailNotifier(this.ref, this.id)
    : super(const AsyncValue.loading()) {
    fetch();
  }

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    try {
      final token = ref.read(authProvider).accessToken ?? '';
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}${Endpoints.expensesEmployeeDetail(id)}',
      );

      print('[EXPENSE DETAIL] GET $uri');
      var response = await http.get(uri, headers: _headers(token));
      print('[EXPENSE DETAIL] Status: ${response.statusCode}');

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
        print('[EXPENSE DETAIL] raw project field: ${data?['project']}');
        state = AsyncValue.data(
          ExpenseRequestDetail.fromJson(Map<String, dynamic>.from(data ?? {})),
        );
      } else {
        print('[EXPENSE DETAIL] Body: ${response.body}');
        state = AsyncValue.error(
          'Gagal memuat detail expense request (${response.statusCode})\n${response.body}',
          StackTrace.current,
        );
      }
    } catch (e, st) {
      print('[EXPENSE DETAIL] Exception: $e');
      state = AsyncValue.error(e, st);
    }
  }

  /// Approve or reject this expense request while it's still PENDING.
  /// Refetches the detail afterwards (on success) so the screen reflects
  /// the new status/phase immediately.
  ///
  /// IMPORTANT: the backend can respond with HTTP 200 even when the action
  /// actually failed for a business reason (e.g. "you are not assigned as
  /// level 1 approver") — the real result lives inside the JSON body, not
  /// the status code. So we must inspect the body instead of trusting
  /// `statusCode == 200` alone, otherwise the app shows a fake "success"
  /// while nothing actually changed.
  Future<ExpenseActionResult> sendAction({
    required bool approve,
    String? note,
  }) async {
    try {
      final token = ref.read(authProvider).accessToken ?? '';
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}${Endpoints.expensesEmployeeAction(id)}',
      );

      Future<http.Response> post(String accessToken) => http.post(
        uri,
        headers: _headers(accessToken),
        body: jsonEncode({
          'action': approve ? 'approve' : 'reject',
          'note': note ?? '',
        }),
      );

      print('[EXPENSE ACTION] POST $uri (${approve ? 'approve' : 'reject'})');
      var response = await post(token);
      print('[EXPENSE ACTION] Status: ${response.statusCode}');
      print('[EXPENSE ACTION] Body: ${response.body}');

      if (response.statusCode == 401) {
        final newToken = await ref
            .read(authProvider.notifier)
            .refreshFromInterceptor();
        if (newToken == null) {
          return const ExpenseActionResult(
            success: false,
            message: 'Sesi berakhir, silakan login kembali',
          );
        }
        response = await post(newToken);
        print('[EXPENSE ACTION] Retry status: ${response.statusCode}');
        print('[EXPENSE ACTION] Retry body: ${response.body}');
      }

      Map<String, dynamic> body = const {};
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) body = Map<String, dynamic>.from(decoded);
      } catch (_) {
        // Body bukan JSON valid, biarkan body kosong.
      }

      // Cari indikator sukses/gagal dari body. Backend ini ternyata selalu
      // bisa saja membalas HTTP 200 di level transport, sementara kode
      // status sesungguhnya ada di body sebagai angka (contoh nyata:
      // {"status": 400, "msg": "Validation failed", "errors": {...}}).
      // Jadi field 'status' numerik di body HARUS diperiksa juga, bukan
      // cuma HTTP status code-nya.
      final successField = body['success'];
      final numericBodyStatus = body['status'] is num
          ? (body['status'] as num).toInt()
          : int.tryParse('${body['status']}');
      final stringStatusField = body['status']?.toString().toLowerCase();
      final hasErrorField =
          (body['error'] != null && body['error'].toString().isNotEmpty) ||
          (body['errors'] != null &&
              !(body['errors'] is Map && (body['errors'] as Map).isEmpty));

      final bodySaysFailed =
          successField == false ||
          stringStatusField == 'error' ||
          stringStatusField == 'failed' ||
          (numericBodyStatus != null && numericBodyStatus >= 400) ||
          hasErrorField;

      final isHttpOk = response.statusCode >= 200 && response.statusCode < 300;
      final isSuccess = isHttpOk && !bodySaysFailed;

      // Susun pesan: kalau ada detail per-field di 'errors', gabungkan
      // supaya jelas field mana yang salah (mis. "action: must be one of
      // approve or reject"), fallback ke message/msg/error top-level.
      String? message;
      final errorsField = body['errors'];
      if (errorsField is Map && errorsField.isNotEmpty) {
        message = errorsField.entries
            .map((e) => '${e.key}: ${e.value}')
            .join('\n');
      } else if (errorsField is String && errorsField.trim().isNotEmpty) {
        message = errorsField;
      }
      message ??= (body['message'] ?? body['msg'] ?? body['error'])?.toString();

      if (isSuccess) {
        await fetch();
        return ExpenseActionResult(success: true, message: message);
      }

      return ExpenseActionResult(
        success: false,
        message: (message != null && message.trim().isNotEmpty)
            ? message
            : 'Failed to process request, please try again',
      );
    } catch (e, st) {
      print('[EXPENSE ACTION] Exception: $e');
      print('[EXPENSE ACTION] Stack: $st');
      return const ExpenseActionResult(
        success: false,
        message: 'Failed to process request, please try again',
      );
    }
  }
}

class ExpenseActionResult {
  final bool success;
  final String? message;

  const ExpenseActionResult({required this.success, this.message});
}

final expenseRequestDetailProvider =
    StateNotifierProvider.family<
      ExpenseRequestDetailNotifier,
      AsyncValue<ExpenseRequestDetail>,
      String
    >((ref, id) => ExpenseRequestDetailNotifier(ref, id));
