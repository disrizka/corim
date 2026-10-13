import 'package:corim/admin/home/activity_model.dart';
import 'package:corim/admin/home/activity_provider.dart';
import 'package:corim/admin/project/project_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// List "Update Activity" dengan infinite scroll:
/// 20 data per halaman, halaman berikutnya dimuat saat scroll mendekati bawah.
class ActivityInfiniteListView extends ConsumerStatefulWidget {
  final EdgeInsetsGeometry listPadding;

  const ActivityInfiniteListView({
    super.key,
    this.listPadding = const EdgeInsets.fromLTRB(16, 8, 16, 24),
  });

  @override
  ConsumerState<ActivityInfiniteListView> createState() =>
      _ActivityInfiniteListViewState();
}

class _ActivityInfiniteListViewState
    extends ConsumerState<ActivityInfiniteListView> {
  final ScrollController _controller = ScrollController();
  static const double _threshold = 240;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final p = _controller.position;
    if (p.pixels >= p.maxScrollExtent - _threshold) {
      ref.read(activityListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activityListProvider);
    final notifier = ref.read(activityListProvider.notifier);

    if (state.isInitialLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF075985)),
      );
    }

    if (state.items.isEmpty && state.error != null) {
      return Center(
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
              'Failed to load activity',
              style: TextStyle(fontSize: 13),
            ),
            TextButton(onPressed: notifier.refresh, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No activity yet',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    final showFooter =
        state.hasMore || state.isLoadingMore || state.error != null;

    return RefreshIndicator(
      color: const Color(0xFF075985),
      onRefresh: notifier.refresh,
      child: ListView.separated(
        controller: _controller,
        padding: widget.listPadding,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: state.items.length + (showFooter ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          if (i >= state.items.length) {
            // Footer: retry kalau gagal, loading kalau masih ada halaman
            if (state.error != null && !state.isLoadingMore) {
              return Center(
                child: TextButton(
                  onPressed: notifier.loadMore,
                  child: const Text('Retry loading more'),
                ),
              );
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) notifier.loadMore();
            });
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Color(0xFF075985),
                  ),
                ),
              ),
            );
          }
          return ActivityCard(item: state.items[i]);
        },
      ),
    );
  }
}

class ActivityCard extends StatelessWidget {
  final ActivityItem item;
  const ActivityCard({super.key, required this.item});

  void _openProject(BuildContext context) {
    if (item.projectId.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectDetailScreen(
          projectId: item.projectId,
          initialTab: item.detailTabIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSales = item.isSales;
    final dot = isSales ? const Color(0xFF3B82F6) : const Color(0xFF22C55E);
    final badgeBg = isSales ? const Color(0xFFEFF6FF) : const Color(0xFFF0FDF4);
    final badgeBorder = isSales
        ? const Color(0xFFBFDBFE)
        : const Color(0xFFBBF7D0);
    final badgeFg = isSales ? const Color(0xFF1D4ED8) : const Color(0xFF15803D);
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
          onTap: () => _openProject(context),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dot.withOpacity(0.2),
                      ),
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: dot,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.dateTimeLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        border: Border.all(color: badgeBorder),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.typeLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: badgeFg,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: item.clientName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      TextSpan(
                        text: ' - ${item.projectName}',
                        style: const TextStyle(color: Color(0xFF374151)),
                      ),
                    ],
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.createdBy} - ${item.title}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
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
