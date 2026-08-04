import 'package:corim/notifications/notification_model.dart';
import 'package:corim/notifications/notification_provider.dart';
import 'package:corim/notifications/notification_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef NotificationCardBuilder =
    Widget Function(BuildContext context, NotificationItem item);
typedef NotificationFilterMatcher = bool Function(NotificationItem item);
typedef NotificationSearchMatcher =
    bool Function(NotificationItem item, String query);
typedef NotificationSortRank = int Function(NotificationItem item);

class NotificationPageView extends ConsumerStatefulWidget {
  final NotificationCardBuilder cardBuilder;
  final NotificationFilterMatcher? filter;
  final String searchQuery;
  final NotificationSearchMatcher? searchMatcher;
  final NotificationSortRank? sortRank;
  final WidgetBuilder emptyBuilder;
  final Widget Function(BuildContext context, bool hasSearch)
  emptyFilterBuilder;
  final Widget Function(BuildContext context, Object error) errorBuilder;
  final EdgeInsetsGeometry listPadding;
  final ValueChanged<int>? onPageChanged;

  const NotificationPageView({
    super.key,
    required this.cardBuilder,
    required this.emptyBuilder,
    required this.emptyFilterBuilder,
    required this.errorBuilder,
    this.filter,
    this.searchQuery = '',
    this.searchMatcher,
    this.sortRank,
    this.listPadding = const EdgeInsets.fromLTRB(16, 16, 16, 24),
    this.onPageChanged,
  });

  @override
  ConsumerState<NotificationPageView> createState() =>
      _NotificationPageViewState();
}

class _NotificationPageViewState extends ConsumerState<NotificationPageView> {
  late final PageController _pageController;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onPageChanged?.call(1);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _ensurePageLoaded(int page, int totalPages) {
    final notifier = ref.read(notificationListProvider.notifier);
    notifier.fetchPage(page);
    if (page + 1 <= totalPages) notifier.fetchPage(page + 1);
    if (page - 1 >= 1) notifier.fetchPage(page - 1);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationListProvider);

    if (state.isInitialLoading) {
      return const Center(
        child: CircularProgressIndicator(color: NotifColors.gradientEnd),
      );
    }

    if (state.error != null && state.pages.isEmpty) {
      return widget.errorBuilder(context, state.error!);
    }

    final totalPages = state.meta.totalPages < 1 ? 1 : state.meta.totalPages;
    final page1Loaded = state.pageItems(1);
    if (state.meta.totalRows == 0 &&
        state.isPageLoaded(1) &&
        page1Loaded.isEmpty) {
      return widget.emptyBuilder(context);
    }

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: totalPages,
            onPageChanged: (index) {
              setState(() => _currentPageIndex = index);
              _ensurePageLoaded(index + 1, totalPages);
              widget.onPageChanged?.call(index + 1);
            },
            itemBuilder: (context, index) {
              final page = index + 1;
              final loaded = state.isPageLoaded(page);

              if (state.didPageFail(page)) {
                return widget.errorBuilder(
                  context,
                  state.error ?? 'Failed to load page $page',
                );
              }

              if (!loaded) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  final s = ref.read(notificationListProvider);
                  if (!s.isPageLoaded(page) &&
                      !s.isPageLoading(page) &&
                      !s.didPageFail(page)) {
                    ref.read(notificationListProvider.notifier).fetchPage(page);
                  }
                });
                return const Center(
                  child: CircularProgressIndicator(
                    color: NotifColors.gradientEnd,
                  ),
                );
              }

              final rawItems = state.pageItems(page);
              var items = rawItems;
              if (widget.filter != null) {
                items = items.where(widget.filter!).toList();
              }
              final query = widget.searchQuery.trim();
              if (query.isNotEmpty && widget.searchMatcher != null) {
                items = items
                    .where((n) => widget.searchMatcher!(n, query))
                    .toList();
              }
              if (widget.sortRank != null) {
                items = [...items]
                  ..sort(
                    (a, b) =>
                        widget.sortRank!(a).compareTo(widget.sortRank!(b)),
                  );
              }

              if (rawItems.isEmpty) return widget.emptyBuilder(context);
              if (items.isEmpty) {
                return widget.emptyFilterBuilder(context, query.isNotEmpty);
              }

              return RefreshIndicator(
                color: NotifColors.gradientEnd,
                onRefresh: () => ref
                    .read(notificationListProvider.notifier)
                    .fetchPage(page, forceRefresh: true),
                child: ListView.separated(
                  padding: widget.listPadding,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) =>
                      widget.cardBuilder(context, items[i]),
                ),
              );
            },
          ),
        ),
        if (totalPages > 1) _buildPageIndicator(totalPages),
      ],
    );
  }

  Widget _buildPageIndicator(int totalPages) {
    final current = _currentPageIndex + 1;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            iconSize: 20,
            visualDensity: VisualDensity.compact,
            onPressed: _currentPageIndex > 0
                ? () => _goToPage(_currentPageIndex - 1)
                : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Text(
            'Page $current of $totalPages',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF555555),
            ),
          ),
          IconButton(
            iconSize: 20,
            visualDensity: VisualDensity.compact,
            onPressed: _currentPageIndex < totalPages - 1
                ? () => _goToPage(_currentPageIndex + 1)
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}
