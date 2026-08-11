enum RequestKind { salesEscalation, expenseRequest }

class NotificationItem {
  final String id;
  final String notificationType;
  final String projectId;
  final String projectName;
  final String salesStatusId;
  final String deliveryId;
  final String title;
  final String desc;
  final String requestedBy;
  final String activityDate;
  final String activityTime;
  final String createdAt;
  final List<dynamic> files;
  final String approvalStatus;
  final String? note;
  final String entity;
  final String clientName;

  const NotificationItem({
    required this.id,
    required this.notificationType,
    required this.projectId,
    required this.projectName,
    required this.salesStatusId,
    required this.deliveryId,
    required this.title,
    required this.desc,
    required this.requestedBy,
    required this.activityDate,
    required this.activityTime,
    required this.createdAt,
    required this.files,
    required this.approvalStatus,
    this.note,
    this.entity = '-',
    this.clientName = '-',
  });

  bool get isPending => approvalStatus.toUpperCase() == 'PENDING';
  bool get isApproved => approvalStatus.toUpperCase() == 'APPROVED';
  bool get isRejected => approvalStatus.toUpperCase() == 'REJECTED';

  RequestKind get kind {
    final t = notificationType.toUpperCase();
    if (t.contains('EXPENSE') || t.contains('FINANCE')) {
      return RequestKind.expenseRequest;
    }
    return RequestKind.salesEscalation;
  }

  bool get isExpenseRequest => kind == RequestKind.expenseRequest;

  String get activityDateId {
    const monthMap = {
      'January': 'Januari',
      'February': 'Februari',
      'March': 'Maret',
      'April': 'April',
      'May': 'Mei',
      'June': 'Juni',
      'July': 'Juli',
      'August': 'Agustus',
      'September': 'September',
      'October': 'Oktober',
      'November': 'November',
      'December': 'Desember',
    };
    var result = activityDate;
    monthMap.forEach((en, id) {
      result = result.replaceAll(en, id);
    });
    return result;
  }

  /// [activityTime] without seconds, e.g. "14:30:00" -> "14:30".
  /// Falls back to the raw value if it doesn't match a HH:mm:ss pattern.
  String get activityTimeShort {
    final match = RegExp(r'^(\d{1,2}:\d{2}):\d{2}$').firstMatch(activityTime);
    return match?.group(1) ?? activityTime;
  }

  NotificationItem copyWith({String? approvalStatus, String? note}) {
    return NotificationItem(
      id: id,
      notificationType: notificationType,
      projectId: projectId,
      projectName: projectName,
      salesStatusId: salesStatusId,
      deliveryId: deliveryId,
      title: title,
      desc: desc,
      requestedBy: requestedBy,
      activityDate: activityDate,
      activityTime: activityTime,
      createdAt: createdAt,
      files: files,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      note: note ?? this.note,
      entity: entity,
      clientName: clientName,
    );
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: (json['id'] ?? '').toString(),
      notificationType: (json['notificationType'] ?? '').toString(),
      projectId: (json['projectId'] ?? '').toString(),
      projectName: (json['projectName'] ?? '-').toString(),
      salesStatusId: (json['salesStatusId'] ?? '').toString(),
      deliveryId: (json['deliveryId'] ?? '').toString(),
      title: (json['title'] ?? '-').toString(),
      desc: (json['desc'] ?? '-').toString(),
      requestedBy: (json['requestedBy'] ?? '-').toString(),
      activityDate: (json['activityDate'] ?? '-').toString(),
      activityTime: (json['activityTime'] ?? '-').toString(),
      createdAt: (json['createdAt'] ?? '-').toString(),
      files: (json['files'] is List)
          ? json['files'] as List<dynamic>
          : const [],
      approvalStatus: (json['approvalStatus'] ?? 'PENDING').toString(),
      note: json['note']?.toString(),
      entity: (json['entity'] ?? '-').toString(),
      clientName: (json['clientName'] ?? '-').toString(),
    );
  }
}
