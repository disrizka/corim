import 'package:corim/notifications/notification_model.dart';
import 'package:corim/notifications/notification_provider.dart';
import 'package:corim/notifications/notification_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationDetailScreen extends ConsumerStatefulWidget {
  final String notificationId;

  const NotificationDetailScreen({super.key, required this.notificationId});

  @override
  ConsumerState<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState
    extends ConsumerState<NotificationDetailScreen> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _openFile(dynamic file) async {
    String url;
    String label = 'file';

    if (file is String) {
      url = file;
      label = file.split('/').last;
    } else if (file is Map) {
      url = (file['url'] ?? file['path'] ?? '').toString();
      label = (file['name'] ?? file['fileName'] ?? url.split('/').last)
          .toString();
    } else {
      return;
    }

    if (url.isEmpty) return;

    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final canOpen = await canLaunchUrl(uri);
    if (!mounted) return;

    if (canOpen) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Unable to open $label'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(
      notificationDetailProvider(widget.notificationId),
    );

    return Scaffold(
      backgroundColor: NotifColors.background,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: detailAsync.when(
              data: (n) => _buildBody(context, n),
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: NotifColors.gradientEnd,
                ),
              ),
              error: (err, st) => _buildError(context, err),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: NotifColors.brandGradient),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: kToolbarHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const Expanded(
                  child: Text(
                    'Notification Detail',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                  iconSize: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, Object err) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 28,
                color: Color(0xFFB91C1C),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load notification detail',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: NotifColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              err.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 160,
              child: ElevatedButton(
                onPressed: () => ref
                    .read(
                      notificationDetailProvider(
                        widget.notificationId,
                      ).notifier,
                    )
                    .fetch(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: NotifColors.gradientEnd,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, NotificationItem n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              NotifStatusBadge(status: n.approvalStatus),
              Text(
                n.activityDateId,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildInfoCard(n),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: NotifColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TITLE STATUS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  n.title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: NotifColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'DESCRIPTION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  n.desc,
                  style: const TextStyle(
                    fontSize: 14,
                    color: NotifColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          if (n.note != null && n.note!.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildLabelBlock(
              'APPROVAL NOTE',
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: NotifStatus.fromApproval(n.approvalStatus).bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  n.note!,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: NotifStatus.fromApproval(n.approvalStatus).fg,
                  ),
                ),
              ),
            ),
          ],

          if (n.files.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildLabelBlock(
              'ATTACHMENTS',
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: NotifColors.cardBorder),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < n.files.length; i++) ...[
                      if (i > 0)
                        const Divider(height: 1, color: NotifColors.divider),
                      InkWell(
                        onTap: () => _openFile(n.files[i]),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.insert_drive_file_outlined,
                                size: 20,
                                color: NotifColors.gradientEnd,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  n.files[i] is Map
                                      ? (n.files[i]['name'] ??
                                                n.files[i]['fileName'] ??
                                                'Attachment ${i + 1}')
                                            .toString()
                                      : n.files[i].toString().split('/').last,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    color: NotifColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                Icons.open_in_new,
                                size: 16,
                                color: Colors.grey.shade400,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: NotifColors.brandGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text('Project detail not available yet'),
                    ),
                  );
                },
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text(
                  'View Project Detail',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(NotificationItem n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NotifColors.cardBorder),
      ),
      child: Column(
        children: [
          _infoRow(Icons.folder_outlined, 'Project', n.projectName),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: NotifColors.divider),
          ),
          _infoRow(Icons.person_outline, 'Requested By', n.requestedBy),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: NotifColors.divider),
          ),
          _infoRow(Icons.access_time, 'Time', n.activityTime),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        NotifIconChip(
          icon: icon,
          background: NotifColors.background,
          foreground: NotifColors.gradientEnd,
          size: 36,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: NotifColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLabelBlock(String label, {required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
