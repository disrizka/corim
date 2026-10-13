class ActivityItem {
  final String id;
  final String projectId;
  final String activityType; // "sales" | "delivery"
  final String clientName;
  final String projectName;
  final String title;
  final String description;
  final String status; // NONE / PENDING / APPROVED / REJECTED / On Progress
  final String createdBy;
  final String activityDate;
  final String activityTime;
  final String activityAt; // "2026-09-25 16:51:18"

  const ActivityItem({
    required this.id,
    required this.projectId,
    required this.activityType,
    required this.clientName,
    required this.projectName,
    required this.title,
    required this.description,
    required this.status,
    required this.createdBy,
    required this.activityDate,
    required this.activityTime,
    required this.activityAt,
  });

  /// Tab awal di Project Detail: sales -> Sales Status (1), delivery -> Delivery (2)
  int get detailTabIndex {
    switch (activityType.toLowerCase()) {
      case 'sales':
        return 1;
      case 'delivery':
        return 2;
      default:
        return 0;
    }
  }

  bool get isSales => activityType.toLowerCase() == 'sales';

  /// "sales" -> "Sales", "delivery" -> "Delivery"
  String get typeLabel {
    final t = activityType.trim();
    if (t.isEmpty) return '-';
    return t[0].toUpperCase() + t.substring(1).toLowerCase();
  }

  /// "2026-09-25 16:51:18" -> "Sep 25, 2026 16:51" (sama seperti di web)
  String get dateTimeLabel {
    final dt = DateTime.tryParse(activityAt);
    if (dt == null) return '$activityDate $activityTimeShort';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} $hh:$mm';
  }

  bool get hasStatus {
    final s = status.trim().toUpperCase();
    return s.isNotEmpty && s != 'NONE';
  }

  /// "16:51:18" -> "16:51"
  String get activityTimeShort {
    final m = RegExp(r'^(\d{1,2}:\d{2}):\d{2}$').firstMatch(activityTime);
    return m?.group(1) ?? activityTime;
  }

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    String s(String key, [String def = '-']) => (json[key] ?? def).toString();

    return ActivityItem(
      id: s('id', ''),
      projectId: s('projectId', ''),
      activityType: s('activityType', ''),
      clientName: s('clientName'),
      projectName: s('projectName'),
      title: s('title'),
      description: s('description'),
      status: s('status', 'NONE'),
      createdBy: s('createdBy'),
      activityDate: s('activityDate'),
      activityTime: s('activityTime'),
      activityAt: s('activityAt', ''),
    );
  }
}
