import 'package:corim/notifications/notification_detail_screen.dart';
import 'package:corim/notifications/notification_model.dart';
import 'package:corim/notifications/notification_style.dart';
import 'package:corim/request/request_project_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RequestCard extends ConsumerWidget {
  final NotificationItem item;
  const RequestCard({super.key, required this.item});

  void _openDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotificationDetailScreen(notificationId: item.id),
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  /// Satu sel info: icon + value (tanpa label).
  Widget _field(IconData icon, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 14, color: const Color(0xFF6B7280)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ),
      ],
    );
  }

  /// Dua sel berdampingan: kiri & kanan.
  Widget _pair(Widget left, Widget right) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = item;
    final info = resolveRequestProjectInfo(ref, n);
    final radius = BorderRadius.circular(12);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: () => _openDetail(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: n.isExpenseRequest
                            ? const Color(0xFFEEF2FF)
                            : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        n.isExpenseRequest
                            ? Icons.receipt_long_rounded
                            : Icons.trending_up_rounded,
                        color: n.isExpenseRequest
                            ? const Color(0xFF0824A0)
                            : const Color(0xFF16A34A),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            n.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Wrap(
                            spacing: 10,
                            runSpacing: 2,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _meta(
                                Icons.calendar_today_outlined,
                                n.activityDateId,
                              ),
                              _meta(
                                Icons.access_time_rounded,
                                n.activityTimeShort,
                              ),
                              if (n.files.isNotEmpty)
                                _meta(
                                  Icons.attach_file_rounded,
                                  n.files.length > 1
                                      ? '${n.files.length} files'
                                      : '1 file',
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    NotifStatusBadge(status: n.approvalStatus, dense: true),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  n.desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF444444),
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF0F1F5)),
                const SizedBox(height: 12),

                // Atas-bawah: Project, lalu Client
                _field(Icons.folder_outlined, info.projectName),
                const SizedBox(height: 10),
                _field(Icons.business_outlined, info.clientName),
                const SizedBox(height: 10),
                // Menyamping: Entity | Requested by
                _pair(
                  _field(Icons.apartment_outlined, info.entity),
                  _field(Icons.person_outline_rounded, n.requestedBy),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
