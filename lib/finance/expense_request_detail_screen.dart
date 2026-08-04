import 'package:corim/admin/project/project_detail_screen.dart';
import 'package:corim/finance/expense_request_model.dart';
import 'package:corim/finance/expense_request_provider.dart';
import 'package:corim/notifications/notification_style.dart';
import 'package:corim/notifications/request_detail_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExpenseRequestDetailScreen extends ConsumerWidget {
  final String expenseId;

  const ExpenseRequestDetailScreen({super.key, required this.expenseId});

  void _openProject(BuildContext context, ExpenseRequestDetail d) {
    if (d.project.id.trim().isEmpty) {
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
        builder: (_) => ProjectDetailScreen(projectId: d.project.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(expenseRequestDetailProvider(expenseId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const RequestDetailHeader(),
      body: detailAsync.when(
        data: (d) => _buildBody(context, ref, d),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => _buildError(context, ref, err),
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
                  .read(expenseRequestDetailProvider(expenseId).notifier)
                  .fetch(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, ExpenseRequestDetail d) {
    return RefreshIndicator(
      color: NotifColors.gradientEnd,
      onRefresh: () =>
          ref.read(expenseRequestDetailProvider(expenseId).notifier).fetch(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(d),
            const SizedBox(height: 16),
            _buildDetailInformationCard(d),
            const SizedBox(height: 16),
            if (d.phaseOfRequest.isNotEmpty) ...[
              _buildPhaseCard(d),
              const SizedBox(height: 16),
            ],
            _buildItemsCard(d),
            const SizedBox(height: 16),
            _buildFilesSection(d),
            const SizedBox(height: 18),
            RequestOutlinedActionButton(
              label: 'Open Project',
              onPressed: () => _openProject(context, d),
            ),
            const SizedBox(height: 16),
            if (d.notes.trim().isNotEmpty && d.notes.trim() != '-') ...[
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
              const SizedBox(height: 14),
            ],
            RequestStatusBar(status: d.status),
          ],
        ),
      ),
    );
  }

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
          Row(
            children: [
              _HeaderBadge(text: expenseFormTypeLabel(d.formType)),
              const SizedBox(width: 8),
              NotifStatusBadge(status: d.status, dense: true),
            ],
          ),
          const SizedBox(height: 10),
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

  Widget _buildDetailInformationCard(ExpenseRequestDetail d) {
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
            value: d.requestDate,
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
            RequestInfoRow(
              icon: Icons.business_outlined,
              label: 'Client:',
              value: d.client.name,
            ),
          RequestInfoRow(
            icon: Icons.folder_outlined,
            label: 'Project:',
            value: d.project.name,
          ),
          RequestInfoRow(
            icon: Icons.check_circle_outline_rounded,
            label: 'Status:',
            value: d.status,
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

  Widget _buildPhaseCard(ExpenseRequestDetail d) {
    final phases = [...d.phaseOfRequest]
      ..sort((a, b) => a.phaseOrder.compareTo(b.phaseOrder));

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

  Widget _buildItemsCard(ExpenseRequestDetail d) {
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
}

class _HeaderBadge extends StatelessWidget {
  final String text;

  const _HeaderBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: Colors.white,
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
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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