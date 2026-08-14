import 'package:corim/admin/project/project_detail_screen.dart';
import 'package:corim/crm/client_detail/client_detail_screen.dart';
import 'package:corim/finance/expense_request_model.dart';
import 'package:corim/finance/expense_request_provider.dart';
import 'package:corim/notifications/notification_style.dart';
import 'package:corim/notifications/request_detail_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExpenseRequestDetailScreen extends ConsumerStatefulWidget {
  final String expenseId;

  const ExpenseRequestDetailScreen({super.key, required this.expenseId});

  @override
  ConsumerState<ExpenseRequestDetailScreen> createState() =>
      _ExpenseRequestDetailScreenState();
}

class _ExpenseRequestDetailScreenState
    extends ConsumerState<ExpenseRequestDetailScreen>
    with SingleTickerProviderStateMixin {
  final _noteController = TextEditingController();
  late final TabController _tabController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _noteController.dispose();
    _tabController.dispose();
    super.dispose();
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

  Future<void> _submit(bool approve) async {
    setState(() => _isSubmitting = true);
    final result = await ref
        .read(expenseRequestDetailProvider(widget.expenseId).notifier)
        .sendAction(approve: approve, note: _noteController.text.trim());
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

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    ExpenseRequestDetail d,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: _buildHeaderCard(d),
        ),
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF075985),
            unselectedLabelColor: Colors.grey.shade500,
            indicatorColor: const Color(0xFF075985),
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(text: 'Items'),
              Tab(text: 'Status'),
              Tab(text: 'History'),
            ],
          ),
        ),
        const Divider(height: 1, color: NotifColors.divider),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildItemsTab(context, ref, d),
              _buildStatusTab(context, d),
              _buildHistoryTab(d),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Header (always visible above the tabs)
  // ---------------------------------------------------------------------

  Widget _buildHeaderCard(ExpenseRequestDetail d) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: NotifColors.brandGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            d.requestNumber,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            d.formattedAmount,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
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
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (d.isSettlementForm && d.stb != null && !d.stb!.isEmpty)
              _buildStbSections(d.stb!)
            else if (d.isSettlementForm)
              _buildSettlementItemsCard(d)
            else
              _buildStandardItemsCard(d),
            const SizedBox(height: 16),
            _buildFilesSection(d),
          ],
        ),
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

  Widget _buildStatusTab(BuildContext context, ExpenseRequestDetail d) {
    final phases = [...d.phaseOfRequest]
      ..sort((a, b) => a.phaseOrder.compareTo(b.phaseOrder));

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailInformationCard(context, d),
          if (d.hasTravelItinerary) ...[
            const SizedBox(height: 16),
            _buildTravelItineraryCard(d),
          ],
          if (phases.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildPhaseCard(phases),
          ],
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
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
              ),
            ),
          ],
        ],
      ),
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
          const SizedBox(height: 8),
          RequestInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Request Date:',
            value: d.requestDateWithTime,
          ),
          RequestInfoRow(
            icon: Icons.description_outlined,
            label: 'Form Type:',
            value: expenseFormTypeLabel(d.formType),
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

  Widget _buildHistoryTab(ExpenseRequestDetail d) {
    if (d.history.isEmpty) {
      return Center(
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
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < d.history.length; i++)
            _HistoryTile(
              entry: d.history[i],
              isLast: i == d.history.length - 1,
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Floating approve/reject bar
  // ---------------------------------------------------------------------

  Widget? _buildFloatingApprovalBar(ExpenseRequestDetail d) {
    if (!d.isPending) return null;

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add a note (optional):',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          RequestNoteField(controller: _noteController, enabled: true),
          const SizedBox(height: 12),
          RequestApprovalButtons(
            isSubmitting: _isSubmitting,
            enabled: true,
            onReject: () => _submit(false),
            onApprove: () => _submit(true),
          ),
        ],
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
                    phase.actionAt.trim().isEmpty ? '-' : phase.actionAt,
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

  const _HistoryTile({required this.entry, required this.isLast});

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
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FC),
                  borderRadius: BorderRadius.circular(10),
                ),
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
                        Text(
                          entry.createdAt,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
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
        ],
      ),
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
