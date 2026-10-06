import 'package:corim/crm/client_detail/client_detail_screen.dart';
import 'package:corim/crm/client_list/client_model.dart';
import 'package:corim/crm/client_list/client_provider.dart';
import 'package:corim/main_button_nav.dart';
import 'package:corim/notifications/notifcation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClientListScreen extends ConsumerStatefulWidget {
  const ClientListScreen({super.key});

  @override
  ConsumerState<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends ConsumerState<ClientListScreen> {
  ClientPhase _selectedPhase = ClientPhase.leads;
  String _query = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    // Panggil loadMore ketika scroll mendekati bagian bawah (sisa 300px)
    if (position.pixels >= position.maxScrollExtent - 300) {
      ref.read(clientListPagingProvider(_selectedPhase).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Membaca summary total row per phase secara individual
    final leadsCount = ref.watch(clientPhaseSummaryProvider(ClientPhase.leads));
    final accountCount = ref.watch(
      clientPhaseSummaryProvider(ClientPhase.account),
    );
    final stagesCount = ref.watch(
      clientPhaseSummaryProvider(ClientPhase.stages),
    );

    // Membaca paging state untuk list phase yang aktif
    final pagingState = ref.watch(clientListPagingProvider(_selectedPhase));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => ref
                .read(clientListPagingProvider(_selectedPhase).notifier)
                .refresh(),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHeader(
                    context,
                    leadsCount: leadsCount,
                    accountCount: accountCount,
                    stagesCount: stagesCount,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _buildPhaseTabs(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Client List Data',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildSearchBar(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                _buildBodySliver(pagingState),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
          const Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: MainBottomNav(currentItem: MainNavItem.folder),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required int? leadsCount,
    required int? accountCount,
    required int? stagesCount,
  }) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B1030), Color(0xFF1C2B63)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Clients',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationScreen(),
                        ),
                      );
                    },
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  top: 12,
                  right: 16,
                  bottom: 12,
                  left: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(255, 255, 255, 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'DATA PHASE CLIENT',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(leadsCount, 'LEADS'),
                        _buildStatDivider(),
                        _buildStatItem(accountCount, 'ACCOUNT'),
                        _buildStatDivider(),
                        _buildStatItem(stagesCount, 'STAGES'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, height: 36, color: Colors.white24);
  }

  Widget _buildStatItem(int? value, String label) {
    return Column(
      children: [
        Text(
          value == null ? '-' : '$value',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPhaseTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: ClientPhase.values.map((phase) {
          final isActive = phase == _selectedPhase;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedPhase = phase),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF1B1C52) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF1B1C52)
                          : const Color(0xFF1B1C52).withOpacity(0.4),
                    ),
                  ),
                  child: Text(
                    phase.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : const Color(0xFF1B1C52),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBodySliver(ClientPagingState state) {
    if (state.isInitialLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (state.error != null && state.items.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
          child: Center(
            child: Text(
              'Gagal memuat data: ${state.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ),
        ),
      );
    }

    final filtered = _query.isEmpty
        ? state.items
        : state.items
              .where(
                (c) =>
                    c.companyName.toLowerCase().contains(_query.toLowerCase()),
              )
              .toList();

    if (filtered.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Text(
              'Tidak ada data ditemukan',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
        ),
      );
    }

    final showTrailingLoader =
        _query.isEmpty && (state.isLoadingMore || state.hasMore);
    final itemCount = filtered.length + (showTrailingLoader ? 1 : 0);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index >= filtered.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          final client = filtered[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ClientDetailScreen(
                      clientId: client.id,
                      companyName: client.companyName,
                    ),
                  ),
                );
              },
              child: _buildClientCard(client),
            ),
          );
        }, childCount: itemCount),
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
              style: const TextStyle(fontSize: 13),
              onChanged: (val) => setState(() => _query = val),
              decoration: const InputDecoration(
                hintText: 'Search client company name...',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.search, color: Colors.grey, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(ClientModel client) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFDDE2EE), width: 1),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'CORIM',
                      style: TextStyle(
                        color: Color(0xFF3B4A77),
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.companyName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Jakarta, Indonesia',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildInfoColumn(
                  label: 'Status',
                  icon: Icons.person_outline,
                  value: client.phase,
                  valueColor: _statusColor(client.phase),
                ),
              ),
              Expanded(
                child: _buildInfoColumn(
                  label: 'Industry',
                  icon: Icons.apartment_outlined,
                  value: client.industry,
                ),
              ),
              Expanded(
                child: _buildInfoColumn(
                  label: 'PIC Name',
                  icon: Icons.badge_outlined,
                  value: client.picName,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(String phase) {
    switch (phase.toLowerCase()) {
      case 'leads':
        return const Color(0xFFF59E0B);
      case 'account':
        return const Color(0xFF2563EB);
      case 'stages':
        return const Color(0xFF16A34A);
      default:
        return const Color(0xFF222222);
    }
  }

  Widget _buildInfoColumn({
    required String label,
    required IconData icon,
    required String value,
    Color valueColor = const Color(0xFF222222),
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, size: 13, color: const Color(0xFF555555)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
