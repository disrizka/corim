import 'package:corim/admin/project/project_model.dart';
import 'package:corim/admin/project/project_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

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
    _tabController = TabController(length: 3, vsync: this);
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
              _buildSalesStatusTab(p),
              _buildDeliveryTab(),
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
            width: 96,
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
          _infoRow(
            Icons.description_outlined,
            'Scope of work:',
            p.scopeOfWorkLabel,
          ),
          _infoRow(
            Icons.percent_rounded,
            'Percentage pro:',
            '${p.probabilityPercentage}%',
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
            Icons.payments_outlined,
            'Deal Value:',
            p.formattedDealValue,
          ),

          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFE9EAF0)),
          const SizedBox(height: 16),

          _sectionTitle('Client Data'),
          const SizedBox(height: 6),
          _infoRow(Icons.person_outline, 'Name:', p.client.name),
          _infoRow(Icons.email_outlined, 'Email:', p.client.email),
          _infoRow(Icons.location_on_outlined, 'Location:', p.client.location),
          _infoRow(Icons.business_outlined, 'Industry:', p.client.industry),

          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFE9EAF0)),
          const SizedBox(height: 16),

          _sectionTitle('Project Progress'),
          const SizedBox(height: 6),
          _infoRow(
            Icons.groups_outlined,
            'Involve Entity:',
            p.involvedEntityLabel,
          ),
          _infoRow(
            Icons.category_outlined,
            'Opportunity Type:',
            p.opportunityTypeLabel,
          ),
          _infoRow(
            Icons.calendar_today_outlined,
            'Expected Start:',
            p.expectedStartLabel,
          ),
          _infoRow(Icons.event_outlined, 'Expected End:', p.expectedEndLabel),
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

  Widget _buildSalesStatusTab(ProjectDetail p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Sales Status'),
          const SizedBox(height: 6),
          _infoRow(Icons.trending_up_rounded, 'Status:', p.salesStatus),
          _infoRow(
            Icons.percent_rounded,
            'Probability:',
            '${p.probabilityDetail.finalPercentage}%',
          ),
          _infoRow(Icons.warning_amber_rounded, 'Risk Level:', p.riskLevel),
          _infoRow(Icons.flag_outlined, 'Risk Status:', p.riskStatus),

          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFE9EAF0)),
          const SizedBox(height: 16),

          _sectionTitle('Probability Breakdown'),
          const SizedBox(height: 10),
          if (p.probabilityDetail.indicators.isEmpty)
            Text(
              'No breakdown available',
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
            )
          else
            for (final ind in p.probabilityDetail.indicators)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(10),
                ),
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
                          const SizedBox(height: 2),
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
  }

  Widget _buildDeliveryTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              'No delivery data available',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
