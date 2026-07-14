import 'package:corim/notifications/notification_detail_screen.dart';
import 'package:corim/notifications/notification_model.dart';
import 'package:corim/notifications/notification_provider.dart';
import 'package:corim/notifications/notification_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _NotifFilter { all, pending, approved, rejected }

extension on _NotifFilter {
  String get label {
    switch (this) {
      case _NotifFilter.all:
        return 'Semua';
      case _NotifFilter.pending:
        return 'Tertunda';
      case _NotifFilter.approved:
        return 'Disetujui';
      case _NotifFilter.rejected:
        return 'Ditolak';
    }
  }

  bool matches(NotificationItem n) {
    switch (this) {
      case _NotifFilter.all:
        return true;
      case _NotifFilter.pending:
        return n.isPending;
      case _NotifFilter.approved:
        return n.isApproved;
      case _NotifFilter.rejected:
        return n.isRejected;
    }
  }
}

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  _NotifFilter _filter = _NotifFilter.all;

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationListProvider);

    return Scaffold(
      backgroundColor: NotifColors.background,
      body: Column(
        children: [
          _buildHeader(context, notificationsAsync),
          notificationsAsync.maybeWhen(
            data: (items) => items.isEmpty
                ? const SizedBox.shrink()
                : _buildFilterBar(items),
            orElse: () => const SizedBox.shrink(),
          ),
          Expanded(
            child: notificationsAsync.when(
              data: (items) {
                final filtered = items.where(_filter.matches).toList();
                if (items.isEmpty) return _buildEmptyState();
                if (filtered.isEmpty) return _buildEmptyFilterState();

                return RefreshIndicator(
                  color: NotifColors.gradientEnd,
                  onRefresh: () =>
                      ref.read(notificationListProvider.notifier).fetch(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _NotificationCard(item: filtered[index]),
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: NotifColors.gradientEnd,
                ),
              ),
              error: (err, st) => _buildErrorState(err),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AsyncValue<List<NotificationItem>> notificationsAsync,
  ) {
    final pendingCount = notificationsAsync.maybeWhen(
      data: (items) => items.where((n) => n.isPending).length,
      orElse: () => 0,
    );

    return Container(
      decoration: const BoxDecoration(gradient: NotifColors.brandGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 16, 18),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const Expanded(
                child: Text(
                  'Pemberitahuan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (pendingCount > 0)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$pendingCount tertunda',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              IconButton(
                onPressed: () =>
                    ref.read(notificationListProvider.notifier).fetch(),
                icon: const Icon(Icons.refresh, color: Colors.white, size: 22),
                tooltip: 'Muat ulang',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar(List<NotificationItem> items) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _NotifFilter.values.map((f) {
            final count = items.where(f.matches).length;
            final isActive = f == _filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text('${f.label}${count > 0 ? ' ($count)' : ''}'),
                selected: isActive,
                onSelected: (_) => setState(() => _filter = f),
                labelStyle: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : NotifColors.textMuted,
                ),
                selectedColor: NotifColors.gradientEnd,
                backgroundColor: NotifColors.background,
                showCheckmark: false,
                side: BorderSide(
                  color: isActive ? Colors.transparent : NotifColors.divider,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: NotifColors.background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_off_outlined,
                size: 32,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum ada notifikasi',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: NotifColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Permintaan approval baru akan muncul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFilterState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_alt_off_outlined,
              size: 40,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'Tidak ada notifikasi "${_filter.label}"',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object err) {
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
              'Gagal memuat notifikasi',
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
                onPressed: () =>
                    ref.read(notificationListProvider.notifier).fetch(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: NotifColors.gradientEnd,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Coba lagi',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends ConsumerStatefulWidget {
  final NotificationItem item;

  const _NotificationCard({required this.item});

  @override
  ConsumerState<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends ConsumerState<_NotificationCard> {
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
          widget.item.id,
          approve: approve,
          note: _noteController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ok
            ? (approve ? const Color(0xFF16A34A) : const Color(0xFFB91C1C))
            : Colors.grey.shade800,
        content: Text(
          ok
              ? (approve ? 'Permintaan disetujui' : 'Permintaan ditolak')
              : 'Gagal memproses permintaan, coba lagi',
        ),
      ),
    );
  }

  void _openDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            NotificationDetailScreen(notificationId: widget.item.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.item;
    final status = NotifStatus.fromApproval(n.approvalStatus);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NotifColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _openDetail,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NotifIconChip(
                      icon: status.icon,
                      background: status.bg,
                      foreground: status.accent,
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
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: NotifColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.folder_outlined,
                                size: 12,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  n.projectName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
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
                const SizedBox(height: 12),
                Text(
                  n.desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF444444),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    _metaChip(Icons.person_outline, n.requestedBy),
                    _metaChip(Icons.calendar_today_outlined, n.activityDateId),
                    _metaChip(Icons.access_time, n.activityTime),
                  ],
                ),
                if (n.isPending) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: NotifColors.divider),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _noteController,
                    style: const TextStyle(fontSize: 13),
                    minLines: 1,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Tambahkan catatan (opsional)',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                      ),
                      filled: true,
                      fillColor: NotifColors.background,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isSubmitting
                              ? null
                              : () => _submit(false),
                          icon: const Icon(Icons.close_rounded, size: 17),
                          label: const Text('Tolak'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFB91C1C),
                            side: const BorderSide(color: Color(0xFFFCA5A5)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : () => _submit(true),
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 15,
                                  height: 15,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_rounded, size: 17),
                          label: const Text('Setujui'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (n.note != null && n.note!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: NotifColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Catatan: ${n.note}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metaChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}
