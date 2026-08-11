import 'dart:async';

import 'package:corim/finance/entity_model.dart';
import 'package:corim/finance/entity_provider.dart';
import 'package:corim/finance/expense_request_detail_screen.dart';
import 'package:corim/finance/expense_request_model.dart';
import 'package:corim/finance/expense_request_provider.dart';
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
  final _scrollController = ScrollController();
  Timer? _debounce;
  static const double _loadMoreThreshold = 240;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      ref.read(expenseRequestListProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final notifier = ref.read(expenseRequestListProvider.notifier);
      final current = ref.read(expenseRequestListProvider).filter;
      notifier.applyFilter(current.copyWith(search: value.trim()));
    });
    setState(() {});
  }

  Future<void> _openFilterSheet() async {
    final notifier = ref.read(expenseRequestListProvider.notifier);
    final state = ref.read(expenseRequestListProvider);
    var draft = state.filter;

    // Prefer the real `GET /entities` list so every entity shows up in the
    // filter, not just the ones that happen to be present on the requests
    // already loaded on screen. Fall back to whatever entities we've seen
    // in the loaded items if that list hasn't loaded yet.
    final fetchedEntities = ref.read(entityOptionsProvider);
    final entityOptions = fetchedEntities.isNotEmpty
        ? fetchedEntities
        : (state.knownEntities.values
              .map((e) => EntityItem(id: e.id, code: e.code, name: e.name))
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name)));

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Filter',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: NotifColors.textPrimary,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setSheetState(
                          () => draft = const ExpenseRequestFilter(),
                        ),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildFilterSection(
                    title: 'Entity',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _filterChip(
                          label: 'All',
                          selected: draft.entityId.isEmpty,
                          onTap: () => setSheetState(
                            () => draft = draft.copyWith(entityId: ''),
                          ),
                        ),
                        for (final e in entityOptions)
                          _filterChip(
                            label: e.displayLabel,
                            selected: draft.entityId == e.id,
                            onTap: () => setSheetState(
                              () => draft = draft.copyWith(entityId: e.id),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFilterSection(
                    title: 'Status',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final s in const [
                          ('', 'All'),
                          ('PENDING', 'Pending'),
                          ('APPROVED', 'Approved'),
                          ('REJECTED', 'Rejected'),
                        ])
                          _filterChip(
                            label: s.$2,
                            selected: draft.status == s.$1,
                            onTap: () => setSheetState(
                              () => draft = draft.copyWith(status: s.$1),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFilterSection(
                    title: 'Form Type',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final t in const ['', 'PRF', 'STB', 'SRF', 'SSR'])
                          _filterChip(
                            label: t.isEmpty ? 'All' : expenseFormTypeLabel(t),
                            selected: draft.formType == t,
                            onTap: () => setSheetState(
                              () => draft = draft.copyWith(formType: t),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: NotifColors.brandGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          notifier.applyFilter(draft);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Apply Filter',
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
            );
          },
        );
      },
    );
  }

  Widget _buildFilterSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: NotifColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected ? NotifColors.brandGradient : null,
          color: selected ? null : Colors.white,
          border: Border.all(
            color: selected ? Colors.transparent : const Color(0xFFCCCCCC),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : const Color(0xFF555555),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expenseRequestListProvider);
    // Kick off (and keep cached) the entities fetch as soon as this screen
    // is shown, so it's ready by the time the filter sheet opens.
    ref.watch(entityListProvider);

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
                    ref.read(expenseRequestListProvider.notifier).refresh(),
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: Row(
                          children: [
                            Expanded(child: _buildSearchBar()),
                            const SizedBox(width: 10),
                            _buildFilterButton(state),
                          ],
                        ),
                      ),
                    ),
                    _buildContentSliver(state),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(ExpenseRequestListState state) {
    final active = state.filter.hasActiveFilters;
    return GestureDetector(
      onTap: _openFilterSheet,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? const Color(0xFFEAF2FF) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFE0E0E0),
              ),
            ),
            child: Icon(
              Icons.tune_rounded,
              size: 20,
              color: active ? const Color(0xFF2563EB) : Colors.grey.shade600,
            ),
          ),
          if (active)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFFDC2626),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContentSliver(ExpenseRequestListState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: CircularProgressIndicator(color: NotifColors.gradientEnd),
        ),
      );
    }

    if (state.error != null && state.items.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildErrorState(state.error!),
      );
    }

    if (state.items.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildEmptyState(state.filter.search),
      );
    }

    // The list API doesn't include an `entity` object per item (only the
    // detail endpoint does). When a single entity is selected in the
    // filter, every visible item necessarily belongs to it, so we can
    // still show a correct badge by resolving the filter's entityId
    // against the entities we fetched from `GET /entities`.
    final filterEntity = state.filter.entityId.isEmpty
        ? null
        : ref.watch(entityByIdProvider)[state.filter.entityId];

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index < state.items.length) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ExpenseRequestCard(
                item: state.items[index],
                fallbackEntity: filterEntity,
              ),
            );
          }
          return _buildListFooter(state);
        }, childCount: state.items.length + 1),
      ),
    );
  }

  Widget _buildListFooter(ExpenseRequestListState state) {
    if (state.loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: TextButton(
            onPressed: () =>
                ref.read(expenseRequestListProvider.notifier).loadMore(),
            child: const Text('Retry loading more'),
          ),
        ),
      );
    }

    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: NotifColors.gradientEnd,
            ),
          ),
        ),
      );
    }

    if (!state.hasNextPage) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            '${state.meta.totalRows} total requests',
            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
          ),
        ),
      );
    }

    return const SizedBox(height: 4);
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
              onChanged: _onSearchChanged,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Search request number, notes, status...',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey, size: 18),
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
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

  Widget _buildEmptyState(String query) {
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
            Text(
              query.isEmpty
                  ? 'No expense requests yet'
                  : 'No expense requests match "$query"',
              textAlign: TextAlign.center,
              style: const TextStyle(
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
                  ref.read(expenseRequestListProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseRequestCard extends StatelessWidget {
  final ExpenseRequestItem item;
  // Resolved entity to fall back to when the list API didn't send one for
  // this item (see the note in `_buildContentSliver`). Null when no single
  // entity is selected in the filter, in which case the badge is hidden.
  final EntityItem? fallbackEntity;

  const _ExpenseRequestCard({required this.item, this.fallbackEntity});

  void _openDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExpenseRequestDetailScreen(expenseId: item.id),
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
                    _buildTypeIcon(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.requestNumber,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: NotifColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 12,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${item.createdDatePart} ${item.createdTimePart}'
                                    .trim(),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    NotifStatusBadge(status: item.status, dense: true),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item.notes,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF444444),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                _EntityBadge(
                  code: item.entity?.code ?? fallbackEntity?.code,
                  name: item.entity?.name ?? fallbackEntity?.name,
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

  /// Icon chip with the form type (PRF/STB/SRF/SSR) shown as a small badge
  /// on its corner, so the type indicator lives on the icon itself instead
  /// of a separate pill in the header.
  Widget _buildTypeIcon() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const NotifIconChip(
          icon: Icons.receipt_long_rounded,
          background: Color(0xFFEAF2FF),
          foreground: Color(0xFF2563EB),
        ),
        Positioned(
          right: -6,
          bottom: -6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Text(
              expenseFormTypeLabel(item.formType),
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EntityBadge extends StatelessWidget {
  final String? code;
  final String? name;

  const _EntityBadge({this.code, this.name});

  @override
  Widget build(BuildContext context) {
    final resolvedName = name;
    if (resolvedName == null || resolvedName.isEmpty || resolvedName == '-') {
      // No entity info available for this item (list API doesn't send one,
      // and no single-entity filter is active to fall back on) — hide the
      // badge instead of showing a misleading "-".
      return const SizedBox.shrink();
    }
    final resolvedCode = code;
    final label =
        (resolvedCode != null && resolvedCode.isNotEmpty && resolvedCode != '-')
        ? '$resolvedCode - $resolvedName'
        : resolvedName;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.apartment_outlined,
              size: 13,
              color: Color(0xFF0824A0),
            ),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0824A0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
