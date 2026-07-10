import 'dart:convert';
import 'package:corim/auth/auth_provider.dart';
import 'package:corim/api/api.dart';
import 'package:corim/crm/client/client_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;

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

class ClientListNotifier extends StateNotifier<AsyncValue<ClientListResult>> {
  final Ref ref;
  final ClientPhase phase;

  ClientListNotifier(this.ref, this.phase) : super(const AsyncValue.loading()) {
    fetch();
  }

  Future<void> fetch() async {
    state = const AsyncValue.loading();

    try {
      final authState = ref.read(authProvider);
      final token = authState.accessToken ?? '';
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}${Endpoints.clients}?phase=${phase.apiValue}',
        ),
        headers: {
          'Content-Type': ApiConfig.contentTypeJson,
          'Access-Token': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> rawList = (body['data'] ?? []) as List<dynamic>;

        final clients = rawList
            .map((e) => ClientModel.fromJson(e as Map<String, dynamic>))
            .toList();

        final totalRows =
            (body['page']?['total_rows'] as num?)?.toInt() ?? clients.length;

        state = AsyncValue.data(
          ClientListResult(clients: clients, totalRows: totalRows),
        );
      } else {
        state = AsyncValue.error(
          'Gagal memuat data (${response.statusCode})',
          StackTrace.current,
        );
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final clientListProvider =
    StateNotifierProvider.family<
      ClientListNotifier,
      AsyncValue<ClientListResult>,
      ClientPhase
    >((ref, phase) => ClientListNotifier(ref, phase));

final clientPhaseSummaryProvider = Provider<ClientPhaseSummary>((ref) {
  final leads = ref.watch(clientListProvider(ClientPhase.leads));
  final account = ref.watch(clientListProvider(ClientPhase.account));
  final stages = ref.watch(clientListProvider(ClientPhase.stages));

  return ClientPhaseSummary(
    leads: leads.maybeWhen(data: (d) => d.totalRows, orElse: () => null),
    account: account.maybeWhen(data: (d) => d.totalRows, orElse: () => null),
    stages: stages.maybeWhen(data: (d) => d.totalRows, orElse: () => null),
  );
});
