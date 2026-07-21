import 'package:corim/admin/project/project_detail_screen.dart';
import 'package:corim/notifications/notification_model.dart';
import 'package:corim/notifications/notification_provider.dart';
import 'package:corim/notifications/request_detail_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SalesEscalationDetailScreen extends ConsumerStatefulWidget {
  final String notificationId;

  const SalesEscalationDetailScreen({super.key, required this.notificationId});

  @override
  ConsumerState<SalesEscalationDetailScreen> createState() =>
      _SalesEscalationDetailScreenState();
}

class _SalesEscalationDetailScreenState
    extends ConsumerState<SalesEscalationDetailScreen> {
  final _noteController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit(bool approve) async {
    setState(() => _isSubmitting = true);
    final ok = await ref
        .read(notificationListProvider.notifier)
        .sendAction(
          widget.notificationId,
          approve: approve,
          note: _noteController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (ok) {
      if (approve) {
        await showRequestAcceptedDialog(context);
      } else {
        await showRequestRejectedDialog(context);
      }
      if (mounted) Navigator.pop(context);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.grey.shade800,
        content: const Text('Failed to process request, please try again'),
      ),
    );
  }

  void _openProject(NotificationItem n) {
    if (n.projectId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('No project linked to this request'),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectDetailScreen(projectId: n.projectId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(
      notificationDetailProvider(widget.notificationId),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const RequestDetailHeader(),
      body: detailAsync.when(
        data: (n) => _buildBody(context, n),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => _buildError(err),
      ),
    );
  }

  Widget _buildError(Object err) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 40,
              color: Color(0xFFB91C1C),
            ),
            const SizedBox(height: 12),
            const Text('Failed to load request detail'),
            const SizedBox(height: 6),
            Text(
              err.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref
                  .read(
                    notificationDetailProvider(widget.notificationId).notifier,
                  )
                  .fetch(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, NotificationItem n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            n.title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            n.desc,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: Color(0xFF444444),
            ),
          ),
          const SizedBox(height: 18),

          RequestInfoRow(
            icon: Icons.person_outline,
            label: 'Request By:',
            value: n.requestedBy,
          ),
          RequestInfoRow(
            icon: Icons.access_time_rounded,
            label: 'Request At:',
            value: '${n.activityDateId}, ${n.activityTime}',
          ),
          RequestInfoRow(
            icon: Icons.apartment_outlined,
            label: 'Entity:',
            value: n.entity,
          ),
          RequestInfoRow(
            icon: Icons.business_outlined,
            label: 'Client Name:',
            value: n.clientName,
          ),
          RequestInfoRow(
            icon: Icons.folder_outlined,
            label: 'Project Name:',
            value: n.projectName,
          ),

          const SizedBox(height: 16),
          const Text(
            'File Document:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 4),
          if (n.files.isEmpty)
            Text(
              'No documents attached',
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
            )
          else
            for (final f in n.files) RequestFileTile(file: f),

          const SizedBox(height: 18),
          RequestOutlinedActionButton(
            label: 'Open Project',
            onPressed: () => _openProject(n),
          ),

          const SizedBox(height: 20),
          if (n.isPending) ...[
            RequestNoteField(controller: _noteController, enabled: true),
            const SizedBox(height: 18),
            RequestApprovalButtons(
              isSubmitting: _isSubmitting,
              enabled: true,
              onReject: () => _submit(false),
              onApprove: () => _submit(true),
            ),
          ] else ...[
            if (n.note != null && n.note!.trim().isNotEmpty) ...[
              Text(
                'Note:',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  n.note!,
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
                ),
              ),
              const SizedBox(height: 14),
            ],
            RequestStatusBar(status: n.approvalStatus),
          ],
        ],
      ),
    );
  }
}
