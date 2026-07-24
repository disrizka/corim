import 'dart:convert';

import 'package:corim/api/api.dart';
import 'package:corim/api/auth_http_client.dart';
import 'package:corim/crm/client_detail/project_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

final projectListProvider = FutureProvider.autoDispose<List<ProjectListItem>>((
  ref,
) async {
  final client = ref.read(authHttpClientProvider);
  final List<ProjectListItem> allProjects = [];

  int currentPage = 1;
  int totalPages = 1;

  do {
    final res = await client.get(
      Uri.parse(
        '${ApiConfig.baseUrl}${Endpoints.projects}',
      ).replace(queryParameters: {'page': '$currentPage'}),
    );

    final body = jsonDecode(res.body);
    if (body['status'] != 200) {
      throw Exception(body['message'] ?? 'Gagal memuat data project');
    }

    final data = (body['data'] as List? ?? []);
    allProjects.addAll(data.map((e) => ProjectListItem.fromJson(e)));

    totalPages = (body['page']?['total_pages'] as num?)?.toInt() ?? 1;
    currentPage++;
  } while (currentPage <= totalPages);

  return allProjects;
});

final projectStatusSummaryProvider = Provider<ProjectStatusSummary>((ref) {
  final listAsync = ref.watch(projectListProvider);

  return listAsync.maybeWhen(
    data: (projects) {
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
    orElse: () => const ProjectStatusSummary(
      newProject: 0,
      ontimeProject: 0,
      delayProject: 0,
    ),
  );
});
