import 'package:corim/crm/client_detail/client_detail_model.dart';
import 'package:corim/crm/client_detail/client_detail_provider.dart';
import 'package:corim/crm/client_detail/project_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClientDetailScreen extends ConsumerStatefulWidget {
  final String clientId;
  final String companyName;

  const ClientDetailScreen({
    super.key,
    required this.clientId,
    required this.companyName,
  });

  @override
  ConsumerState<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends ConsumerState<ClientDetailScreen> {
  bool _showActivity = false;

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(clientDetailProvider(widget.clientId));

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
          'Client Detail',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      body: detailAsync.when(
        data: (detail) => _buildBody(detail),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Gagal memuat data: $err')),
      ),
    );
  }

  Widget _buildBody(ClientDetailModel detail) {
    final projectsAsync = ref.watch(
      clientProjectListProvider(detail.companyName),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFDDE2EE)),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: EdgeInsets.all(4),
                    child: Text(
                      'CORIM',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  detail.companyName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _infoBox(
                  bg: const Color(0xFF1B1C52),
                  labelColor: Colors.white70,
                  valueColor: Colors.white,
                  label: 'Health Score',
                  value: detail.healthPointsDetail != null
                      ? '${detail.healthPointsDetail!.percentage.round()}/100'
                      : '-',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _infoBox(
                  bg: const Color(0xFFFFF6D8),
                  labelColor: Colors.grey.shade700,
                  valueColor: const Color(0xFFB08900),
                  label: 'Phase',
                  value: detail.phase,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _infoBox(
                  bg: const Color(0xFFD6F5E8),
                  labelColor: Colors.grey.shade700,
                  valueColor: const Color(0xFF17825A),
                  label: 'Entity',
                  value: detail.entityCode.isEmpty ? '-' : detail.entityCode,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _contactRow(Icons.mail_outline, 'Email:', detail.email),
          _contactRow(
            Icons.phone_outlined,
            'Phone Number:',
            detail.phoneNumber,
          ),
          _contactRow(Icons.location_on_outlined, 'Location:', detail.address),
          _contactRow(Icons.badge_outlined, 'Industry:', detail.industry),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF2563EB)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'See PIC',
                style: TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _tabItem(
                'List Project',
                !_showActivity,
                () => setState(() => _showActivity = false),
              ),
              const SizedBox(width: 24),
              _tabItem(
                'Activity',
                _showActivity,
                () => setState(() => _showActivity = true),
              ),
            ],
          ),
          const Divider(height: 24),
          if (!_showActivity)
            projectsAsync.when(
              data: (projects) {
                if (projects.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Belum ada project',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }
                return Column(
                  children: projects
                      .map(
                        (p) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _projectCard(p),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, st) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('Gagal memuat project: $err')),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Activity belum tersedia',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoBox({
    required Color bg,
    required Color labelColor,
    required Color valueColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabItem(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: active ? const Color(0xFF2563EB) : Colors.grey,
            ),
          ),
          const SizedBox(height: 6),
          if (active)
            Container(height: 2, width: 60, color: const Color(0xFF2563EB)),
        ],
      ),
    );
  }

  Widget _projectCard(ProjectListItem p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEFEFEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.projectName,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _statusBg(p.projectStatus),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        p.projectStatus,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _statusColor(p.projectStatus),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Expected Start-End',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${p.expectedStartDate} - ${p.expectedEndDate}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusBg(String status) {
    switch (status.toUpperCase()) {
      case 'WON':
        return const Color(0xFFE0F5E9);
      case 'LOST':
        return const Color(0xFFFDE8E8);
      default:
        return const Color(0xFFF0F0F0);
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'WON':
        return const Color(0xFF16A34A);
      case 'LOST':
        return const Color(0xFFDC2626);
      default:
        return Colors.grey.shade700;
    }
  }
}
