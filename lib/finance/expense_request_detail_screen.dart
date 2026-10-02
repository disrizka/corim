import 'dart:async';

import 'package:corim/admin/project/project_detail_screen.dart';
import 'package:corim/crm/client_detail/client_detail_screen.dart';
import 'package:corim/finance/expense_request_model.dart';
import 'package:corim/finance/expense_request_provider.dart';
import 'package:corim/notifications/notification_style.dart';
import 'package:corim/notifications/request_detail_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which of the two independent panels the user is currently interacting
/// with. Drives the animated split ratio between them — see
/// [_ExpenseRequestDetailScreenState._targetRatioFor].
enum _ActivePanel { none, top, bottom }

class ExpenseRequestDetailScreen extends ConsumerStatefulWidget {
  final String expenseId;

  const ExpenseRequestDetailScreen({super.key, required this.expenseId});

  @override
  ConsumerState<ExpenseRequestDetailScreen> createState() =>
      _ExpenseRequestDetailScreenState();
}

class _ExpenseRequestDetailScreenState
    extends ConsumerState<ExpenseRequestDetailScreen>
    with TickerProviderStateMixin {
  final _noteController = TextEditingController();
  late final TabController _tabController;
  bool _isSubmitting = false;

  // ---------------------------------------------------------------------
  // Two-panel split state.
  //
  // The screen is split into a top panel (Detail Information / Travel
  // Itinerary) and a bottom panel (the Detail Item / Status / History
  // tabs). Both scroll independently — there's no shared/coordinated
  // scroll offset like a NestedScrollView would give you.
  //
  // Instead, whichever panel the user is actively scrolling "wins" more
  // space, and the other panel is animated down to about half its normal
  // height — like the active panel is sliding over and partially covering
  // the idle one. Once scrolling settles (with a short grace period so
  // fling/deceleration doesn't flicker the layout), both panels animate
  // back to their normal proportional split.
  // ---------------------------------------------------------------------

  static const double _baseTopRatio = 0.42;
  static const double _minPanelHeight = 160.0;
  static const Duration _splitAnimDuration = Duration(milliseconds: 320);
  static const Duration _idleGrace = Duration(milliseconds: 260);

  _ActivePanel _activePanel = _ActivePanel.none;
  late AnimationController _splitController;
  late Animation<double> _splitRatio;
  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _splitController = AnimationController(
      vsync: this,
      duration: _splitAnimDuration,
    );
    _splitRatio = const AlwaysStoppedAnimation(_baseTopRatio);
  }

  @override
  void dispose() {
    _noteController.dispose();
    _tabController.dispose();
    _splitController.dispose();
    _idleTimer?.cancel();
    super.dispose();
  }

  /// Target top-panel height ratio for a given active panel:
  /// - none   → the normal proportional split
  /// - top    → top panel grows, bottom panel shrinks to ~half its size
  /// - bottom → bottom panel grows, top panel shrinks to ~half its size
  double _targetRatioFor(_ActivePanel panel) {
    switch (panel) {
      case _ActivePanel.top:
        return _baseTopRatio + (1 - _baseTopRatio) * 0.5;
      case _ActivePanel.bottom:
        return _baseTopRatio * 0.5;
      case _ActivePanel.none:
        return _baseTopRatio;
    }
  }

  void _setActivePanel(_ActivePanel panel) {
    if (_activePanel == panel) return;
    final begin = _splitRatio.value;
    final end = _targetRatioFor(panel);
    _activePanel = panel;
    _splitRatio = Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(parent: _splitController, curve: Curves.easeOutCubic),
    );
    _splitController
      ..stop()
      ..reset()
      ..forward();
  }

  /// Wired into both panels' [NotificationListener]. Scroll activity in
  /// either panel nudges the split; a short idle grace period after the
  /// scroll ends restores the normal split so quick taps/tiny scrolls
  /// don't cause jumpy layout changes.
  bool _handleScrollNotification(_ActivePanel panel, ScrollNotification n) {
    if (n is ScrollStartNotification || n is ScrollUpdateNotification) {
      _idleTimer?.cancel();
      if (_activePanel != panel) {
        setState(() => _setActivePanel(panel));
      }
    } else if (n is ScrollEndNotification) {
      _idleTimer?.cancel();
      _idleTimer = Timer(_idleGrace, () {
        if (mounted) setState(() => _setActivePanel(_ActivePanel.none));
      });
    }
    return false;
  }

  void _openProject(BuildContext context, ExpenseRequestDetail d) {
    if (d.project.id.trim().isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectDetailScreen(projectId: d.project.id),
      ),
    );
  }

  void _openClient(BuildContext context, ExpenseRequestDetail d) {
    if (d.client.id.trim().isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientDetailScreen(
          clientId: d.client.id,
          companyName: d.client.name,
        ),
      ),
    );
  }

  Future<void> _submit(bool approve, {String note = ''}) async {
    setState(() => _isSubmitting = true);
    final result = await ref
        .read(expenseRequestDetailProvider(widget.expenseId).notifier)
        .sendAction(approve: approve, note: note.trim());
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.success) {
      if (approve) {
        await showRequestAcceptedDialog(context);
      } else {
        await showRequestRejectedDialog(context);
      }
      _noteController.clear();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.grey.shade800,
        content: Text(
          result.message ?? 'Failed to process request, please try again',
        ),
      ),
    );
  }

  /// Approve/Reject always goes through a confirmation modal first, with
  /// the note field living inside that modal (not sitting permanently on
  /// screen). Confirming here closes the modal and fires the actual
  /// request; the floating bar's buttons show the loading/disabled state
  /// while it's in flight.
  Future<void> _confirmAndSubmit(bool approve) async {
    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: approve
                          ? const Color(0xFFE0F2FE)
                          : const Color(0xFFFEE2E2),
                    ),
                    child: Icon(
                      approve
                          ? Icons.assignment_turned_in_rounded
                          : Icons.cancel_rounded,
                      color: approve
                          ? const Color(0xFF075985)
                          : const Color(0xFFB91C1C),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      approve ? 'Approve Request' : 'Reject Request',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Are you sure you want to ${approve ? 'approve' : 'reject'} '
                'this request? This action cannot be undone.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              Text(
                'Add a note (optional):',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              RequestNoteField(controller: noteController, enabled: true),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: approve ? null : const Color(0xFFB91C1C),
                          gradient: approve
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF1B1C52),
                                    Color(0xFF075985),
                                  ],
                                )
                              : null,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            approve ? 'Approve' : 'Reject',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    final note = noteController.text;
    noteController.dispose();
    if (confirmed != true || !mounted) return;
    await _submit(approve, note: note);
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(
      expenseRequestDetailProvider(widget.expenseId),
    );

    return Scaffold(
      backgroundColor: NotifColors.background,
      appBar: const RequestDetailHeader(),
      body: detailAsync.when(
        data: (d) => _buildBody(context, ref, d),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => _buildError(context, ref, err),
      ),
      bottomNavigationBar: detailAsync.maybeWhen(
        data: (d) => _buildFloatingApprovalBar(d),
        orElse: () => null,
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object err) {
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
                  .read(expenseRequestDetailProvider(widget.expenseId).notifier)
                  .fetch(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Body: two INDEPENDENT scrollables stacked in a Column — the top panel
  // (Detail Information / Travel Itinerary) and the bottom panel (the
  // tabs). They do not share a scroll position. Instead their heights are
  // driven by an animated ratio: whichever one the user is scrolling
  // grows, the other shrinks to ~half its normal height, then both settle
  // back to the proportional base split shortly after scrolling stops.
  // See _handleScrollNotification / _setActivePanel above.
  // ---------------------------------------------------------------------

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    ExpenseRequestDetail d,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight;
        return AnimatedBuilder(
          animation: _splitController,
          builder: (context, _) {
            final ratio = _splitRatio.value;
            var topHeight = totalHeight * ratio;
            final maxTop = totalHeight - _minPanelHeight;
            topHeight = topHeight.clamp(
              _minPanelHeight,
              maxTop <= _minPanelHeight ? _minPanelHeight : maxTop,
            );
            final bottomHeight = totalHeight - topHeight;

            return Column(
              children: [
                SizedBox(height: topHeight, child: _buildTopPanel(context, d)),
                SizedBox(
                  height: bottomHeight,
                  child: _buildBottomPanel(context, ref, d),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Top panel: Detail Information + (optional) Travel Itinerary, in its
  /// own independent scroll view. Rounded bottom + subtle shadow so it
  /// visually reads as a sheet that can slide down and cover the panel
  /// below when it's the one being actively scrolled.
  Widget _buildTopPanel(BuildContext context, ExpenseRequestDetail d) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: NotifColors.background,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) => _handleScrollNotification(_ActivePanel.top, n),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailInformationCard(context, d),
                if (d.hasTravelItinerary) ...[
                  const SizedBox(height: 12),
                  _buildTravelItineraryCard(d),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Bottom panel: TabBar (fixed) + TabBarView, each tab scrolling
  /// independently of the top panel. Rounded top + shadow + a small drag
  /// handle so it reads as a sheet that can rise up and cover the top
  /// panel when it's the one being actively scrolled.
  Widget _buildBottomPanel(
    BuildContext context,
    WidgetRef ref,
    ExpenseRequestDetail d,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 6),
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF075985),
            unselectedLabelColor: Colors.grey.shade500,
            indicatorColor: const Color(0xFF075985),
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(text: 'Detail Item'),
              Tab(text: 'Status'),
              Tab(text: 'History'),
            ],
          ),
          const Divider(height: 1, color: NotifColors.divider),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) =>
                  _handleScrollNotification(_ActivePanel.bottom, n),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildItemsTab(context, ref, d),
                  _buildStatusTab(context, d),
                  _buildHistoryTab(context, ref, d),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Tab 1: Items (layout differs between PRF/SRF/SSR and STB)
  // ---------------------------------------------------------------------

  Widget _buildItemsTab(
    BuildContext context,
    WidgetRef ref,
    ExpenseRequestDetail d,
  ) {
    return RefreshIndicator(
      color: NotifColors.gradientEnd,
      onRefresh: () => ref
          .read(expenseRequestDetailProvider(widget.expenseId).notifier)
          .fetch(),
      child: CustomScrollView(
        key: const PageStorageKey('expense_tab_items'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (d.isSettlementForm && d.stb != null && !d.stb!.isEmpty)
                  _buildStbSections(d.stb!)
                else if (d.isSettlementForm)
                  _buildSettlementItemsCard(d)
                else
                  _buildStandardItemsCard(d),
                const SizedBox(height: 16),
                _buildFilesSection(d),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// PRF / SRF / SSR: itemized cards (description, qty, rate, due date, amount).
  Widget _buildStandardItemsCard(ExpenseRequestDetail d) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NotifColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DETAIL ITEM',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          if (d.items.isEmpty)
            Text(
              'No items',
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
            )
          else
            for (final item in d.items) _ItemTile(item: item),
        ],
      ),
    );
  }

  /// STB: rendered as separate sections matching how the web dashboard
  /// shows it — Air Ticket, Hotel Reservation, Rent Car/BBM/Toll, Tactical
  /// Funds & Meals (combined), Coordination Funds, and UPD — each only
  /// shown when the backend actually sent lines for it.
  Widget _buildStbSections(ExpenseStbDetail stb) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (stb.airTicket.isNotEmpty) ...[
          _StbAirTicketCard(lines: stb.airTicket),
          const SizedBox(height: 12),
        ],
        if (stb.hotelReservation.isNotEmpty) ...[
          _StbDayCard(title: 'HOTEL RESERVATION', lines: stb.hotelReservation),
          const SizedBox(height: 12),
        ],
        if (stb.rentCarBbmToll.isNotEmpty) ...[
          _StbDayCard(title: 'RENT CAR, BBM & TOLL', lines: stb.rentCarBbmToll),
          const SizedBox(height: 12),
        ],
        if (stb.tacticalFunds.isNotEmpty || stb.meals.isNotEmpty) ...[
          _StbLabeledDayCard(
            title: 'TACTICAL FUNDS & MEALS',
            groups: [
              if (stb.tacticalFunds.isNotEmpty)
                ('Tactical Funds', stb.tacticalFunds),
              if (stb.meals.isNotEmpty) ('Meals', stb.meals),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (stb.coordinationFunds.isNotEmpty) ...[
          _StbDayCard(
            title: 'COORDINATION FUNDS',
            lines: stb.coordinationFunds,
          ),
          const SizedBox(height: 12),
        ],
        if (stb.upd != null) ...[
          _StbUpdCard(upd: stb.upd!),
          const SizedBox(height: 12),
        ],
        if (stb.totalBudget != 0)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: NotifColors.brandGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Budget',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  formatRupiahExpense(stb.totalBudget),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// STB (settlement/reimbursement): shown as a settlement table with a
  /// total row, since STB is about reconciling actual spend against the
  /// requested amount rather than a plain item/qty/rate breakdown.
  ///
  /// NOTE: the backend response for STB item lines hasn't been shared yet,
  /// so this reuses the same [ExpenseItemLine] fields as PRF/SRF/SSU as a
  /// placeholder. If STB actually returns different fields (e.g. advance
  /// amount vs realized amount, settlement date, variance), send over a
  /// sample `detailInformation.items` JSON for an STB request and this tab
  /// can be adjusted to match exactly.
  Widget _buildSettlementItemsCard(ExpenseRequestDetail d) {
    final total = d.items.fold<num>(0, (sum, item) => sum + item.amount);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NotifColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SETTLEMENT DETAIL',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          if (d.items.isEmpty)
            Text(
              'No settlement items',
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
            )
          else ...[
            const _SettlementHeaderRow(),
            const Divider(height: 16, color: NotifColors.divider),
            for (final item in d.items) _SettlementRow(item: item),
            const Divider(height: 20, color: NotifColors.divider),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  formatRupiahExpense(total),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF075985),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilesSection(ExpenseRequestDetail d) {
    final files = d.allFiles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'File Document:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 4),
        if (files.isEmpty)
          Text(
            'No documents attached',
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
          )
        else
          for (final f in files) RequestFileTile(file: f),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Tab 2: Status (request info, status badge/banner, approval phases)
  // ---------------------------------------------------------------------

  /// Status tab now only holds the phase-of-request timeline (Detail
  /// Information and Travel Itinerary live in the top panel instead, since
  /// they're relevant regardless of which tab is open).
  Widget _buildStatusTab(BuildContext context, ExpenseRequestDetail d) {
    final phases = [...d.phaseOfRequest]
      ..sort((a, b) => a.phaseOrder.compareTo(b.phaseOrder));

    final isEmpty =
        phases.isEmpty && (d.notes.trim().isEmpty || d.notes.trim() == '-');

    return CustomScrollView(
      key: const PageStorageKey('expense_tab_status'),
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timelapse_rounded,
                      size: 36,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No phase information yet',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (phases.isNotEmpty) _buildPhaseCard(phases),
                if (d.notes.trim().isNotEmpty && d.notes.trim() != '-') ...[
                  const SizedBox(height: 16),
                  Text(
                    'Notes:',
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
                      d.notes,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ]),
            ),
          ),
      ],
    );
  }

  Widget _buildDetailInformationCard(
    BuildContext context,
    ExpenseRequestDetail d,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NotifColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DETAIL INFORMATION',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _InfoPill(
                label: d.entity.code,
                background: const Color(0xFFDCFCE7),
                foreground: const Color(0xFF15803D),
              ),
              const SizedBox(width: 8),
              _InfoPill(
                label: expenseFormTypeLabel(d.formType),
                background: const Color(0xFFDBEAFE),
                foreground: const Color(0xFF1D4ED8),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RequestInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Request Date:',
            value: d.requestDateWithTime,
          ),
          RequestInfoRow(
            icon: Icons.receipt_long_outlined,
            label: 'Request No:',
            value: d.requestNumber,
          ),
          if (d.operationExpense.trim().isNotEmpty && d.operationExpense != '-')
            RequestInfoRow(
              icon: Icons.local_offer_outlined,
              label: 'Operation:',
              value: expenseTitleCase(d.operationExpense),
            ),
          RequestInfoRow(
            icon: Icons.apartment_outlined,
            label: 'Entity:',
            value: '${d.entity.name} (${d.entity.code})',
          ),
          if (d.client.name.trim().isNotEmpty && d.client.name != '-')
            RequestInfoLinkRow(
              icon: Icons.business_outlined,
              label: 'Client:',
              value: d.client.name,
              onTap: () => _openClient(context, d),
            ),
          RequestInfoLinkRow(
            icon: Icons.folder_outlined,
            label: 'Project:',
            value: d.project.name,
            onTap: () => _openProject(context, d),
          ),
          RequestInfoWidgetRow(
            icon: Icons.check_circle_outline_rounded,
            label: 'Status:',
            trailing: NotifStatusBadge(status: d.status, dense: true),
          ),
          RequestInfoRow(
            icon: Icons.timelapse_rounded,
            label: 'Current Phase:',
            value: expenseTitleCase(d.currentPhase),
          ),
          RequestInfoRow(
            icon: Icons.person_outline,
            label: 'Created By:',
            value: d.createdBy,
          ),
          if (d.revisionCount > 0)
            RequestInfoRow(
              icon: Icons.history_rounded,
              label: 'Revision:',
              value: '${d.revisionCount}x',
            ),
          const Divider(height: 22, color: NotifColors.divider),
          RequestInfoWidgetRow(
            icon: Icons.payments_outlined,
            label: 'Amount:',
            trailing: Text(
              d.formattedAmount,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF075985),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTravelItineraryCard(ExpenseRequestDetail d) {
    final legs = d.stb?.travelItinerary ?? const <ExpenseTravelLeg>[];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NotifColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TRAVEL ITINERARY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          if (d.travelStartDate.trim().isNotEmpty ||
              d.travelEndDate.trim().isNotEmpty)
            RequestInfoRow(
              icon: Icons.date_range_outlined,
              label: 'Duration Travel:',
              value:
                  '${d.travelStartDate.isEmpty ? '-' : d.travelStartDate} — '
                  '${d.travelEndDate.isEmpty ? '-' : d.travelEndDate}',
            ),
          if (d.reasonForTravel.trim().isNotEmpty)
            RequestInfoRow(
              icon: Icons.flag_outlined,
              label: 'Reason for Travel:',
              value: d.reasonForTravel,
            ),
          if (legs.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: NotifColors.divider),
            const SizedBox(height: 10),
            for (var i = 0; i < legs.length; i++) ...[
              _TravelLegRow(leg: legs[i]),
              if (i != legs.length - 1)
                const Divider(height: 14, color: NotifColors.divider),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildPhaseCard(List<ExpensePhase> phases) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NotifColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PHASE OF REQUEST',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < phases.length; i++)
            _PhaseTile(phase: phases[i], isLast: i == phases.length - 1),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Tab 3: History (past submissions / revisions)
  // ---------------------------------------------------------------------

  Widget _buildHistoryTab(
    BuildContext context,
    WidgetRef ref,
    ExpenseRequestDetail d,
  ) {
    return CustomScrollView(
      key: const PageStorageKey('expense_tab_history'),
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (d.history.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 36,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No history yet',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                for (var i = 0; i < d.history.length; i++)
                  _HistoryTile(
                    entry: d.history[i],
                    isLast: i == d.history.length - 1,
                    onTap: () => _openHistoryEntry(context, d.history[i]),
                  ),
              ]),
            ),
          ),
      ],
    );
  }

  /// Opens the "DETAIL INFORMATION" popup for a History row — mirrors the
  /// web dashboard's modal (Notes + item list for that revision) instead
  /// of navigating to a whole new detail screen, and loads it live from
  /// `GET finance/expenses-employee/{expenseId}/history/{snapshotId}`.
  void _openHistoryEntry(BuildContext context, ExpenseHistoryEntry entry) {
    if (entry.id.trim().isEmpty) return;
    _showHistorySnapshotDialog(entry.id);
  }

  void _showHistorySnapshotDialog(String snapshotId) {
    final future = ref
        .read(expenseRequestDetailProvider(widget.expenseId).notifier)
        .fetchHistorySnapshot(snapshotId);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.8,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
            child: FutureBuilder<ExpenseHistorySnapshotDetail>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SizedBox(
                    height: 160,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return _HistorySnapshotError(
                    message: snapshot.error.toString(),
                    onClose: () => Navigator.of(ctx).pop(),
                  );
                }
                return _HistorySnapshotContent(
                  detail: snapshot.data!,
                  onClose: () => Navigator.of(ctx).pop(),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Floating approve/reject bar
  // ---------------------------------------------------------------------

  Widget? _buildFloatingApprovalBar(ExpenseRequestDetail d) {
    // Only pending requests can be actioned at all, and only by users the
    // backend says are allowed to approve/reject this one — everyone else
    // can still open and read the request, they just won't see these
    // buttons.
    if (!d.isPending || !d.canApprove) return null;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        14 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: RequestApprovalButtons(
        isSubmitting: _isSubmitting,
        enabled: true,
        onReject: () => _confirmAndSubmit(false),
        onApprove: () => _confirmAndSubmit(true),
      ),
    );
  }
}

/// Small rounded status/category pill, e.g. entity code or form type,
/// shown at the top of the Detail Information card.
class _InfoPill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _InfoPill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

class _PhaseTile extends StatelessWidget {
  final ExpensePhase phase;
  final bool isLast;

  const _PhaseTile({required this.phase, required this.isLast});

  Color get _dotColor {
    if (phase.isApproved) return const Color(0xFF16A34A);
    if (phase.isRejected) return const Color(0xFFDC2626);
    if (phase.isDone) return const Color(0xFF2563EB);
    return const Color(0xFFCBD5E1);
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 3),
                decoration: BoxDecoration(
                  color: _dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: NotifColors.divider,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    phase.actionAt.trim().isEmpty
                        ? '-'
                        : expenseFormatDateTime(phase.actionAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    phase.phaseName,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF075985),
                    ),
                  ),
                  if (phase.actionByName.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      phase.actionNote.trim().isNotEmpty
                          ? '${phase.actionByName} — ${phase.actionNote}'
                          : phase.actionByName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TravelLegRow extends StatelessWidget {
  final ExpenseTravelLeg leg;

  const _TravelLegRow({required this.leg});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.circle, size: 6, color: Colors.grey.shade400),
            const SizedBox(width: 6),
            Text(
              '${leg.date} · Day ${leg.day}',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                '${leg.from}  →  ${leg.to}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),
            Text(
              'ETD ${leg.etd}  ·  ETA ${leg.eta}',
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
            ),
          ],
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final ExpenseHistoryEntry entry;
  final bool isLast;
  final VoidCallback? onTap;

  const _HistoryTile({required this.entry, required this.isLast, this.onTap});

  bool get _isTappable => onTap != null && entry.id.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 3),
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB),
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: NotifColors.divider,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Material(
                color: const Color(0xFFF8F9FC),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: _isTappable ? onTap : null,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                entry.formNumber,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A2E),
                                ),
                              ),
                            ),
                            if (_isTappable) ...[
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(width: 2),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          expenseFormatDateTime(entry.createdAt),
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        if (entry.createdByName.trim().isNotEmpty &&
                            entry.createdByName != '-') ...[
                          const SizedBox(height: 4),
                          Text(
                            entry.createdByName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                        if (entry.notes.trim().isNotEmpty &&
                            entry.notes != '-') ...[
                          const SizedBox(height: 6),
                          Text(
                            entry.notes,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF444444),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Content of the History "DETAIL INFORMATION" popup — Notes + Items,
/// matching the web dashboard's modal for a history/revision snapshot.
class _HistorySnapshotContent extends StatelessWidget {
  final ExpenseHistorySnapshotDetail detail;
  final VoidCallback onClose;

  const _HistorySnapshotContent({required this.detail, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DETAIL INFORMATION',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: Colors.grey,
          ),
        ),
        const Divider(height: 22, color: NotifColors.divider),
        RequestInfoRow(
          icon: Icons.description_outlined,
          label: 'Notes:',
          value: detail.notes.trim().isEmpty || detail.notes == '-'
              ? '-'
              : detail.notes,
        ),
        const SizedBox(height: 14),
        const Text(
          'ITEMS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Flexible(
          child: detail.items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No items',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey.shade500,
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemCount: detail.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) =>
                      _HistoryItemTile(item: detail.items[i]),
                ),
        ),
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            height: 42,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: NotifColors.brandGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ElevatedButton(
                onPressed: onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// One item row inside the history snapshot popup — same shape as the
/// Detail Item tab's [_ItemTile], plus the Operation Expense chip the web
/// table shows as its first column.
class _HistoryItemTile extends StatelessWidget {
  final ExpenseItemLine item;

  const _HistoryItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.operationExpense.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  expenseTitleCase(item.operationExpense).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: Color(0xFF5B21B6),
                  ),
                ),
              ),
            ),
          Text(
            item.itemDescription,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _ItemStat(label: 'Qty', value: '${item.qty}'),
              ),
              Expanded(
                child: _ItemStat(label: 'Rate', value: item.formattedRate),
              ),
              Expanded(
                child: _ItemStat(
                  label: 'Due Date',
                  value: item.dueDate.isEmpty ? '-' : item.dueDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              item.formattedAmount,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF075985),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Error state for the history snapshot popup (fetch failed).
class _HistorySnapshotError extends StatelessWidget {
  final String message;
  final VoidCallback onClose;

  const _HistorySnapshotError({required this.message, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.wifi_off_rounded, size: 32, color: Color(0xFFB91C1C)),
        const SizedBox(height: 10),
        const Text(
          'Failed to load history detail',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(onPressed: onClose, child: const Text('Close')),
        ),
      ],
    );
  }
}

class _ItemTile extends StatelessWidget {
  final ExpenseItemLine item;

  const _ItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.itemDescription,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _ItemStat(label: 'Qty', value: '${item.qty}'),
              ),
              Expanded(
                child: _ItemStat(label: 'Rate', value: item.formattedRate),
              ),
              Expanded(
                child: _ItemStat(
                  label: 'Due Date',
                  value: item.dueDate.isEmpty ? '-' : item.dueDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              item.formattedAmount,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF075985),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemStat extends StatelessWidget {
  final String label;
  final String value;

  const _ItemStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }
}

/// Shared white/bordered card shell used by all STB sections, matching the
/// look of [_buildStandardItemsCard] / [_buildDetailInformationCard].
class _StbCardShell extends StatelessWidget {
  final String title;
  final Widget child;

  const _StbCardShell({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NotifColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// AIR TICKET section: detail / date / time / amount, with a per-line file
/// link when the backend attached one.
class _StbAirTicketCard extends StatelessWidget {
  final List<ExpenseStbLine> lines;

  const _StbAirTicketCard({required this.lines});

  @override
  Widget build(BuildContext context) {
    return _StbCardShell(
      title: 'AIR TICKET',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    line.detail.isEmpty ? '-' : line.detail,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    line.date.isEmpty ? '-' : line.date,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    line.time.isEmpty ? '-' : line.time,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    line.formattedAmount,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF075985),
                    ),
                  ),
                ),
              ],
            ),
            if (line.uploadFile.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final f in line.uploadFile) RequestFileTile(file: f),
                  ],
                ),
              ),
            if (line != lines.last)
              const Divider(height: 16, color: NotifColors.divider),
          ],
        ],
      ),
    );
  }
}

/// HOTEL RESERVATION / RENT CAR-BBM-TOLL / COORDINATION FUNDS: date / day /
/// amount-per-day / sub total.
class _StbDayCard extends StatelessWidget {
  final String title;
  final List<ExpenseStbLine> lines;

  const _StbDayCard({required this.title, required this.lines});

  @override
  Widget build(BuildContext context) {
    return _StbCardShell(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    line.date.isEmpty ? '-' : line.date,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    '${line.day} day',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    line.formattedAmount,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    line.formattedTotal,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF075985),
                    ),
                  ),
                ),
              ],
            ),
            if (line.uploadFile.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final f in line.uploadFile) RequestFileTile(file: f),
                  ],
                ),
              ),
            if (line != lines.last)
              const Divider(height: 16, color: NotifColors.divider),
          ],
        ],
      ),
    );
  }
}

/// TACTICAL FUNDS & MEALS: same layout as [_StbDayCard] but combining two
/// labeled groups (e.g. "Tactical Funds" rows then "Meals" rows) under one
/// card, matching the web dashboard.
class _StbLabeledDayCard extends StatelessWidget {
  final String title;
  final List<(String, List<ExpenseStbLine>)> groups;

  const _StbLabeledDayCard({required this.title, required this.groups});

  @override
  Widget build(BuildContext context) {
    return _StbCardShell(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final group in groups)
            for (final line in group.$2)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        group.$1,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        line.formattedAmount,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${line.day}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        line.formattedTotal,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF075985),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

/// UPD: a single amount / night / sub total row.
class _StbUpdCard extends StatelessWidget {
  final ExpenseStbUpd upd;

  const _StbUpdCard({required this.upd});

  @override
  Widget build(BuildContext context) {
    return _StbCardShell(
      title: 'UPD',
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              upd.formattedAmount,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF1A1A2E)),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${upd.night} night',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              upd.formattedSubTotal,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF075985),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettlementHeaderRow extends StatelessWidget {
  const _SettlementHeaderRow();

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.3,
      color: Colors.grey.shade500,
    );
    return Row(
      children: [
        Expanded(flex: 3, child: Text('DESCRIPTION', style: style)),
        Expanded(
          flex: 1,
          child: Text('QTY', style: style, textAlign: TextAlign.center),
        ),
        Expanded(
          flex: 2,
          child: Text('AMOUNT', style: style, textAlign: TextAlign.right),
        ),
      ],
    );
  }
}

class _SettlementRow extends StatelessWidget {
  final ExpenseItemLine item;

  const _SettlementRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              item.itemDescription,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${item.qty}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.formattedAmount,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF075985),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
