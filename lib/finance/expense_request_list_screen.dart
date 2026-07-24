import 'package:corim/notifications/expense_request_detail_screen.dart';
import 'package:corim/notifications/notification_model.dart';
import 'package:corim/notifications/notification_provider.dart';
import 'package:corim/notifications/notification_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExpenseRequestListScreen extends ConsumerStatefulWidget {
  const ExpenseRequestListScreen({super.key});

  @override
  ConsumerState<ExpenseRequestListScreen> createState() =>
      _ExpenseRequestListScreenState();
}

class _ExpenseRequestListScreenState
    extends ConsumerState<ExpenseRequestListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() => setState(() {});

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesSearch(NotificationItem n, String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return n.clientName.toLowerCase().contains(q) ||
        n.projectName.toLowerCase().contains(q) ||
        n.approvalStatus.toLowerCase().contains(q) ||
        n.title.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expenseRequestListProvider);

    return Scaffold(
      backgroundColor: NotifColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: RefreshIndicator(
                color: NotifColors.gradientEnd,
                onRefresh: () =>
                    ref.read(notificationListProvider.notifier).fetch(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Request Data',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: NotifColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSearchBar(),
                      const SizedBox(height: 16),
                      expensesAsync.when(
                        data: (items) {
                          final query = _searchController.text.trim();
                          final filtered =
                              items
                                  .where((n) => _matchesSearch(n, query))
                                  .toList()
                                ..sort((a, b) {
                                  int rank(NotificationItem n) =>
                                      n.isPending ? 0 : 1;
                                  return rank(a).compareTo(rank(b));
                                });

                          if (items.isEmpty) return _buildEmptyState();
                          if (filtered.isEmpty) {
                            return _buildEmptyFilterState(query);
                          }

                          return Column(
                            children: [
                              for (final n in filtered) ...[
                                _ExpenseRequestCard(item: n),
                                const SizedBox(height: 12),
                              ],
                            ],
                          );
                        },
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: NotifColors.gradientEnd,
                            ),
                          ),
                        ),
                        error: (err, st) => _buildErrorState(err),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F3F7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: Colors.black87,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Expenses Request',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
          const SizedBox(width: 34),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Search client name, project name, status...',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey, size: 18),
              onPressed: () => _searchController.clear(),
              splashRadius: 16,
            )
          else
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.search, color: Colors.grey, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: NotifColors.divider),
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 32,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No expense requests yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: NotifColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'New expense requests will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFilterState(String query) {
    final message = query.isEmpty
        ? 'No expense requests found'
        : 'No expense requests match "$query"';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Text(
          message,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        ),
      ),
    );
  }

  Widget _buildErrorState(Object err) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 32,
              color: Color(0xFFB91C1C),
            ),
            const SizedBox(height: 8),
            const Text(
              'Failed to load expense requests',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              err.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () =>
                  ref.read(notificationListProvider.notifier).fetch(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseRequestCard extends StatelessWidget {
  final NotificationItem item;

  const _ExpenseRequestCard({required this.item});

  String get _timeAgo {
    final created = DateTime.tryParse(item.createdAt);
    if (created == null) return item.activityTime;
    final diff = DateTime.now().difference(created);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return item.activityDateId;
  }

  void _openDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExpenseRequestDetailScreen(notificationId: item.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          onTap: () => _openDetail(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const NotifIconChip(
                      icon: Icons.receipt_long_rounded,
                      background: Color(0xFFEAF2FF),
                      foreground: Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: NotifColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _timeAgo,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item.desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF444444),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Project Name',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.folder_outlined,
                                size: 14,
                                color: Color(0xFF555555),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item.projectName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF222222),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Due Date',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 14,
                                color: Color(0xFF555555),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${item.activityDateId}, ${item.activityTime}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF222222),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: NotifColors.brandGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ElevatedButton(
                      onPressed: () => _openDetail(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'More Detail',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
