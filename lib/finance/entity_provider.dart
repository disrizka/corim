import 'dart:convert';

import 'package:corim/api/api.dart';
import 'package:corim/finance/entity_model.dart';
import 'package:corim/service/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Fetches `GET /entities` once and keeps the result cached for the whole
/// app session, so the expense request list (card + filter) and the home
/// screen can all share the same list of entities instead of each guessing
/// it from whatever partial data happens to already be loaded.
class EntityListNotifier extends StateNotifier<AsyncValue<List<EntityItem>>> {
  final Ref ref;

  EntityListNotifier(this.ref) : super(const AsyncValue.loading()) {
    fetch();
  }

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    try {
      final response = await ref
          .read(apiServiceProvider)
          .get(Endpoints.entities);

      if (response == null) {
        state = AsyncValue.error(
          'Sesi berakhir, silakan login kembali',
          StackTrace.current,
        );
        return;
      }

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> rawList = (body['data'] ?? []) as List<dynamic>;
        final entities = rawList.map((e) => EntityItem.fromJson(e)).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        state = AsyncValue.data(entities);
      } else {
        state = AsyncValue.error(
          'Gagal memuat daftar entity (${response.statusCode})',
          StackTrace.current,
        );
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => fetch();
}

final entityListProvider =
    StateNotifierProvider<EntityListNotifier, AsyncValue<List<EntityItem>>>(
      (ref) => EntityListNotifier(ref),
    );

/// Convenience: the entities as a plain list, empty while loading/erroring.
final entityOptionsProvider = Provider<List<EntityItem>>((ref) {
  return ref
      .watch(entityListProvider)
      .maybeWhen(data: (entities) => entities, orElse: () => const []);
});

/// Convenience: quick lookup by id, for enriching data that only carries an
/// entity id.
final entityByIdProvider = Provider<Map<String, EntityItem>>((ref) {
  final entities = ref.watch(entityOptionsProvider);
  return {for (final e in entities) e.id: e};
});
