import 'package:corim/admin/project/project_model.dart';
import 'package:corim/admin/project/project_provider.dart';
import 'package:corim/shared/file_open_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final String projectId;

  final int initialTab;

  const ProjectDetailScreen({
    super.key,
    required this.projectId,
    this.initialTab = 0,
  });

  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    final initial = (widget.initialTab < 0 || widget.initialTab > 2)
        ? 0
        : widget.initialTab;
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: initial,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(projectDetailProvider(widget.projectId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Project Detail',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: detailAsync.when(
        data: (p) => _buildBody(p),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => _buildError(err),
      ),
    );
  }

  Widget _buildError(Object err) {
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
            const Text('Failed to load project detail'),
            const SizedBox(height: 6),
            Text(
              err.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref
                  .read(projectDetailProvider(widget.projectId).notifier)
                  .fetch(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ProjectDetail p) {
    return Column(
      children: [
        _buildHeaderCard(p),
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
              Tab(text: 'Information'),
              Tab(text: 'Sales Status'),
              Tab(text: 'Delivery'),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE9EAF0)),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildInformationTab(p),
              _buildSalesStatusTab(widget.projectId),
              _buildDeliveryTab(widget.projectId),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCard(ProjectDetail p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.apartment_rounded,
              color: Color(0xFF0824A0),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              p.projectName,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A1A2E),
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          SizedBox(
            width: 138,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildInformationTab(ProjectDetail p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Project Information'),
          const SizedBox(height: 6),
          _infoRow(Icons.badge_outlined, 'Project Name:', p.projectName),
          _infoRow(
            Icons.payments_outlined,
            'Deal Value:',
            p.formattedDealValue,
          ),
          _infoRow(
            Icons.scale_outlined,
            'Weight Value:',
            p.formattedWeightValue,
          ),
          _infoRow(Icons.person_outline, 'Created by:', p.createdBy),
          _infoRow(Icons.calendar_today_outlined, 'Created at:', p.createdAt),

          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFE9EAF0)),
          const SizedBox(height: 16),

          _sectionTitle('Client Data'),
          const SizedBox(height: 6),
          _infoRow(Icons.person_outline, 'Name:', p.client.name),
          _infoRow(Icons.support_agent_outlined, 'PIC:', p.picLabel),
          _infoRow(Icons.sell_outlined, 'Category:', p.client.industry),
          _infoRow(Icons.flag_outlined, 'Status:', p.client.phase),

          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFE9EAF0)),
          const SizedBox(height: 16),

          _sectionTitle('Project Progress'),
          const SizedBox(height: 6),
          _infoRow(
            Icons.groups_outlined,
            'Involved Entity:',
            p.involvedEntityLabel,
          ),
          _infoRow(Icons.design_services_outlined, 'Service:', p.serviceLabel),
          _infoRow(Icons.layers_outlined, 'Sub Service:', p.subServiceLabel),
          _infoRow(
            Icons.category_outlined,
            'Opportunity Type:',
            p.opportunityTypeLabel,
          ),
          _infoRow(
            Icons.percent_rounded,
            'Probability Percentage:',
            p.probabilityStatusLabel,
            trailing: IconButton(
              icon: const Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: Color(0xFF075985),
              ),
              onPressed: () => _showProbabilityBreakdown(p),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 16,
            ),
          ),
          _infoRow(
            Icons.calendar_today_outlined,
            'Expected Start Date:',
            p.expectedStartLabel,
          ),
          _infoRow(
            Icons.event_outlined,
            'Expected End Date:',
            p.expectedEndLabel,
          ),

          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFE9EAF0)),
          const SizedBox(height: 16),

          _sectionTitle('Scope of Work'),
          const SizedBox(height: 8),
          Text(
            p.scopeOfWorkLabel,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF444444),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showProbabilityBreakdown(ProjectDetail p) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Probability Breakdown',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                  Text(
                    '${p.probabilityDetail.finalPercentage}%',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF075985),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (p.probabilityDetail.indicators.isEmpty)
                Text(
                  'No breakdown available',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
                )
              else
                for (final ind in p.probabilityDetail.indicators)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ind.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A2E),
                                ),
                              ),
                              Text(
                                ind.value,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '+${ind.contribution}%',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabError(Object err, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 32,
              color: Color(0xFFB91C1C),
            ),
            const SizedBox(height: 8),
            Text(
              err.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  /// Badge status approval di samping judul (Pending Approval, dst).
  Widget? _approvalBadge(String status) {
    final String label;
    final Color bg;
    final Color fg;
    switch (status.trim().toUpperCase()) {
      case 'PENDING':
        label = 'Pending Approval';
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        break;
      case 'APPROVED':
        label = 'Approved';
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        break;
      case 'REJECTED':
        label = 'Rejected';
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
        break;
      default:
        return null;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  /// Kotak dokumen (seperti "Document" di web). Tap = lihat/buka file.
  Widget _buildFileTile(dynamic file) {
    final info = FileOpenHelper.fileInfo(file);
    final isImage = FileOpenHelper.isImageUrl(info.url);
    final isPdf = FileOpenHelper.isPdfUrl(info.url);
    final icon = isImage
        ? Icons.image_outlined
        : isPdf
        ? Icons.picture_as_pdf_outlined
        : Icons.insert_drive_file_outlined;
    final label = info.label.trim().isEmpty ? 'Document' : info.label;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => FileOpenHelper.openFile(context, file),
      child: Container(
        width: 92,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: const Color(0xFF6B7280)),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineTile({
    required Color dotColor,
    required String dateLabel,
    required String title,
    required String createdByName,
    String? description,
    List<Widget> extraLines = const [],
    List<dynamic> files = const [],
    Widget? titleBadge,
    String? escalatedTo,
    String? approvalNote,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: const Color(0xFFE9EAF0)),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 4 : 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateLabel,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      if (titleBadge != null) titleBadge,
                    ],
                  ),
                  const SizedBox(height: 3),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade600,
                      ),
                      children: [
                        const TextSpan(text: 'Created by '),
                        TextSpan(
                          text: createdByName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF444444),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (description != null && description.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  if (escalatedTo != null && escalatedTo.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFFB45309),
                        ),
                        children: [
                          const TextSpan(text: 'Escalated to '),
                          TextSpan(
                            text: escalatedTo,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (approvalNote != null &&
                      approvalNote.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF374151),
                          ),
                          children: [
                            const TextSpan(
                              text: 'Approval Note: ',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            TextSpan(text: approvalNote),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (extraLines.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    ...extraLines,
                  ],
                  if (files.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [for (final f in files) _buildFileTile(f)],
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

  Widget _buildSalesStatusTab(String projectId) {
    final salesStatusAsync = ref.watch(projectSalesStatusProvider(projectId));

    return salesStatusAsync.when(
      data: (events) {
        if (events.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timeline_rounded,
                    size: 40,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No sales status updates yet',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Sales Status'),
              const SizedBox(height: 14),
              for (var i = 0; i < events.length; i++)
                _buildSalesStatusTile(
                  events[i],
                  isLast: i == events.length - 1,
                ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => _buildTabError(
        err,
        () => ref.read(projectSalesStatusProvider(projectId).notifier).fetch(),
      ),
    );
  }

  Widget _buildSalesStatusTile(SalesStatusEvent e, {required bool isLast}) {
    final Color dotColor;
    if (e.isQuotation) {
      dotColor = e.isSigned ? const Color(0xFF16A34A) : const Color(0xFF9CA3AF);
    } else {
      switch (e.approvalStatus.trim().toUpperCase()) {
        case 'PENDING':
          dotColor = const Color(0xFFF59E0B);
          break;
        case 'APPROVED':
          dotColor = const Color(0xFF16A34A);
          break;
        case 'REJECTED':
          dotColor = const Color(0xFFDC2626);
          break;
        default:
          dotColor = const Color(0xFF2563EB);
      }
    }

    final extraLines = <Widget>[];
    if (e.isQuotation) {
      extraLines.add(
        Text(
          'Value: ${e.formattedValue}',
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
        ),
      );
      extraLines.add(const SizedBox(height: 2));
      extraLines.add(
        Text(
          'Expected: ${e.expectedRangeLabel}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      );
      if (e.isSigned) {
        extraLines.add(const SizedBox(height: 4));
        extraLines.add(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 14,
                color: Color(0xFF16A34A),
              ),
              const SizedBox(width: 4),
              Text(
                'Signed: ${e.signedAtLabel}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF16A34A),
                ),
              ),
            ],
          ),
        );
      }
    }

    return _buildTimelineTile(
      dotColor: dotColor,
      dateLabel: e.createdAtLabel,
      title: e.title,
      createdByName: e.createdByName,
      description: e.description,
      extraLines: extraLines,
      files: e.files,
      titleBadge: e.isQuotation ? null : _approvalBadge(e.approvalStatus),
      escalatedTo: e.isEscalate ? e.escalateToName : null,
      approvalNote: e.approvalNote,
      isLast: isLast,
    );
  }

  Widget _buildDeliveryTab(String projectId) {
    final deliveryAsync = ref.watch(projectDeliveryStatusProvider(projectId));

    return deliveryAsync.when(
      data: (events) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _sectionTitle('Delivery Status')),
                  // _buildSortChip(),
                ],
              ),
              const SizedBox(height: 16),
              if (events.isEmpty)
                _buildEmptyDelivery()
              else
                for (var i = 0; i < events.length; i++)
                  _buildTimelineTile(
                    dotColor: events[i].isPending
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF2563EB),
                    dateLabel: events[i].createdAtLabel,
                    title: events[i].title,
                    createdByName: events[i].createdByName,
                    description: events[i].description,
                    files: events[i].files,
                    titleBadge: _approvalBadge(events[i].status),
                    escalatedTo: events[i].isEscalate
                        ? events[i].escalateToName
                        : null,
                    isLast: i == events.length - 1,
                  ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => _buildTabError(
        err,
        () =>
            ref.read(projectDeliveryStatusProvider(projectId).notifier).fetch(),
      ),
    );
  }



  Widget _buildEmptyDelivery() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 40,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'No delivery updates yet.',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Click Update Delivery Status to add the first update.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}
