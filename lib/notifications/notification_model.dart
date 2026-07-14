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
  });

  bool get isPending => approvalStatus.toUpperCase() == 'PENDING';
  bool get isApproved => approvalStatus.toUpperCase() == 'APPROVED';
  bool get isRejected => approvalStatus.toUpperCase() == 'REJECTED';

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
    );
  }
}
