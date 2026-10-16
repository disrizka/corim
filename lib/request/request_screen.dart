import 'package:corim/main_button_nav.dart';
import 'package:corim/notifications/notification_model.dart';
import 'package:corim/notifications/notification_pageview.dart';
import 'package:corim/notifications/notification_provider.dart';
import 'package:corim/request/request_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RequestScreen extends ConsumerStatefulWidget {
  const RequestScreen({super.key});

  @override
  ConsumerState<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends ConsumerState<RequestScreen> {
  static const double _bottomNavReservedHeight = 16 + 60 + 16;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesSearch(NotificationItem n, String query) {
    final q = query.toLowerCase();
    return n.title.toLowerCase().contains(q) ||
        n.desc.toLowerCase().contains(q) ||
        n.projectName.toLowerCase().contains(q) ||
        n.clientName.toLowerCase().contains(q) ||
        n.requestedBy.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Column(
              children: [
                _buildTabHeader(),
                _buildSearchBar(),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildTab(RequestKind.salesEscalation),
                      _buildTab(RequestKind.expenseRequest),
                    ],
                  ),
                ),
              ],
            ),
            const Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: MainBottomNav(currentItem: MainNavItem.request),
            ),
          ],
        ),
      ),
    );
  }

  /// Judul "Request List" + tab Sales Escalation / Expense Request.
  /// Background putih, gaya mengikuti "Update Activity" di Home.
  Widget _buildTabHeader() {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Request List',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: TabBar(
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  labelColor: const Color(0xFF1D4ED8),
                  unselectedLabelColor: const Color(0xFF6B7280),
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  splashBorderRadius: BorderRadius.circular(8),
                  tabs: const [
                    Tab(height: 34, text: 'Sales Escalation'),
                    Tab(height: 34, text: 'Expense Request'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
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
                  hintText: 'Search title, project, client, requester...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey, size: 18),
                onPressed: _searchController.clear,
                splashRadius: 16,
              )
            else
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.search, color: Colors.grey, size: 20),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(RequestKind kind) {
    return NotificationInfiniteListView(
      listPadding: const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        _bottomNavReservedHeight + 8,
      ),
      cardBuilder: (context, item) => RequestCard(item: item),
      filter: (n) => n.kind == kind,
      searchQuery: _searchController.text,
      searchMatcher: _matchesSearch,
      sortRank: (n) => n.isPending ? 0 : 1,
      emptyBuilder: (context) => _message('No requests yet'),
      emptyFilterBuilder: (context, hasSearch) => _message(
        hasSearch ? 'No requests match your search' : 'No requests found',
      ),
      errorBuilder: (context, err) => Center(
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
              'Failed to load request list',
              style: TextStyle(fontSize: 13),
            ),
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

  Widget _message(String text) => Center(
    child: Text(
      text,
      style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
    ),
  );
}
