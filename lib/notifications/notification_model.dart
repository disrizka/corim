class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String? type;
  final Map<String, dynamic>? data;
  final DateTime receivedAt;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.type,
    this.data,
    DateTime? receivedAt,
    this.isRead = false,
  }) : receivedAt = receivedAt ?? DateTime.now();

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      body: body,
      type: type,
      data: data,
      receivedAt: receivedAt,
      isRead: isRead ?? this.isRead,
    );
  }

  factory NotificationModel.fromFcm({
    required String? title,
    required String? body,
    required Map<String, dynamic> data,
  }) {
    return NotificationModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title ?? 'Notifikasi',
      body: body ?? '',
      type: data['type'] as String?,
      data: data,
    );
  }
}
