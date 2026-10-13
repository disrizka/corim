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
  static const _gradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF1B1C52), Color(0xFF075985)],
  );

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

  /// Langsung tab Sales Escalation & Expense Request (tanpa judul "Request").
  Widget _buildTabHeader() {
    return Container(
      decoration: const BoxDecoration(gradient: _gradient),
      child: const SafeArea(
        bottom: false,
        child: TabBar(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          dividerColor: Colors.transparent,
          labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          tabs: [
            Tab(text: 'Sales Escalation'),
            Tab(text: 'Expense Request'),
          ],
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
