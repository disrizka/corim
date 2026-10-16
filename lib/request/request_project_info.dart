import 'package:corim/admin/project/project_provider.dart';
import 'package:corim/notifications/notification_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Data Project Name, Client Name & Entity untuk sebuah request.
///
/// Endpoint notifikasi sering mengirim `entity` / `clientName` kosong ("-"),
/// jadi nilainya diambil dari Project Detail:
///   - Client Name -> Client Data > Name        (ProjectDetail.client.name)
///   - Entity      -> Project Progress > Involved Entity
///                    (ProjectDetail.involvedEntityLabel)
class RequestProjectInfo {
  final String projectName;
  final String clientName;
  final String entity;

  const RequestProjectInfo({
    required this.projectName,
    required this.clientName,
    required this.entity,
  });
}

bool _isEmpty(String? v) {
  final t = (v ?? '').trim();
  return t.isEmpty || t == '-';
}

String _pick(String? primary, String? fallback) {
  if (!_isEmpty(primary)) return primary!.trim();
  if (!_isEmpty(fallback)) return fallback!.trim();
  return '-';
}

/// Gabungkan data dari notifikasi dengan data Project Detail.
/// Project Detail diprioritaskan; kalau belum load / gagal / tidak ada
/// projectId (mis. Expense Request), pakai nilai dari notifikasi.
RequestProjectInfo resolveRequestProjectInfo(
  WidgetRef ref,
  NotificationItem n,
) {
  final projectId = n.projectId.trim();
  if (projectId.isEmpty) {
    return RequestProjectInfo(
      projectName: _pick(n.projectName, null),
      clientName: _pick(n.clientName, null),
      entity: _pick(n.entity, null),
    );
  }

  final async = ref.watch(projectDetailProvider(projectId));
  final project = async.hasValue ? async.value : null;

  return RequestProjectInfo(
    projectName: _pick(project?.projectName, n.projectName),
    clientName: _pick(project?.client.name, n.clientName),
    entity: _pick(project?.involvedEntityLabel, n.entity),
  );
}
