import 'package:corim/admin/project/project_detail_screen.dart';
import 'package:corim/admin/project/project_model.dart' show formatRupiah;
import 'package:corim/crm/client_detail/project_model.dart';
import 'package:corim/crm/project/project_list_provider.dart';
import 'package:corim/main_button_nav.dart';
import 'package:corim/notifications/notifcation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProjectListScreen extends ConsumerStatefulWidget {
  const ProjectListScreen({super.key});

  @override
  ConsumerState<ProjectListScreen> createState() => _ProjectListScreenState();
}

enum _ProbabilityFilter { all, under50, above50 }

extension on _ProbabilityFilter {
  String get label {
    switch (this) {
      case _ProbabilityFilter.all:
        return 'All';
      case _ProbabilityFilter.under50:
        return 'Under 50%';
      case _ProbabilityFilter.above50:
        return 'Above 50%';
    }
  }
}

class _ProjectListScreenState extends ConsumerState<ProjectListScreen> {
  static const _gradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF1B1C52), Color(0xFF075985)],
  );

  String _query = '';
  String? _clientFilter; // nama client
  String? _entityFilter; // kode entity
  String? _userFilter; // createdBy
  _ProbabilityFilter _probFilter = _ProbabilityFilter.all;

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
    if (position.pixels >= position.maxScrollExtent - 300) {
      ref.read(projectListPagingProvider.notifier).loadMore();
    }
  }

  int get _activeFilterCount =>
      (_clientFilter != null ? 1 : 0) +
      (_entityFilter != null ? 1 : 0) +
      (_userFilter != null ? 1 : 0) +
      (_probFilter != _ProbabilityFilter.all ? 1 : 0);

  bool get _hasActiveFilter => _activeFilterCount > 0;

  bool _matchesFilters(ProjectListItem p) {
    if (_clientFilter != null && p.clientName != _clientFilter) return false;
    if (_userFilter != null && p.createdBy != _userFilter) return false;
    if (_entityFilter != null &&
        !p.involvedEntity.any((e) => e.code == _entityFilter)) {
      return false;
    }
    switch (_probFilter) {
      case _ProbabilityFilter.all:
        break;
      case _ProbabilityFilter.under50:
        if (p.probabilityPercentage >= 50) return false;
        break;
      case _ProbabilityFilter.above50:
        if (p.probabilityPercentage < 50) return false;
        break;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final pagingState = ref.watch(projectListPagingProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () =>
                ref.read(projectListPagingProvider.notifier).refresh(),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHeader(context, pagingState.stats),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSearchRow(pagingState),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                _buildSliverBody(pagingState),
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

  Widget _buildHeader(BuildContext context, ProjectStats? stats) {
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
                    'Projects',
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
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(255, 255, 255, 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem(stats?.newProject, 'New Project'),
                    _buildStatDivider(),
                    _buildStatItem(stats?.wonProject, 'Project Won'),
                    _buildStatDivider(),
                    _buildStatItem(stats?.lossProject, 'Project Loss'),
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
          value?.toString() ?? '-',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Search + tombol filter
  // ---------------------------------------------------------------------------

  Widget _buildSearchRow(ProjectListPagingState state) {
    return Row(
      children: [
        Expanded(child: _buildSearchBar()),
        const SizedBox(width: 10),
        _buildFilterButton(state),
      ],
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
                hintText: 'Search client name, project name, status...',
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

  Widget _buildFilterButton(ProjectListPagingState state) {
    final active = _hasActiveFilter;
    return GestureDetector(
      onTap: () => _openFilterSheet(state),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: active ? null : Colors.white,
              gradient: active ? _gradient : null,
              shape: BoxShape.circle,
              border: Border.all(
                color: active ? Colors.transparent : const Color(0xFFE0E0E0),
              ),
            ),
            child: Icon(
              Icons.tune_rounded,
              size: 20,
              color: active ? Colors.white : const Color(0xFF475569),
            ),
          ),
          if (active)
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  '$_activeFilterCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Modal filter
  // ---------------------------------------------------------------------------

  Future<void> _openFilterSheet(ProjectListPagingState state) async {
    // Opsi diambil dari data project yang sudah ter-load.
    final clients =
        state.items
            .map((p) => p.clientName)
            .where((e) => e.trim().isNotEmpty && e != '-')
            .toSet()
            .toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final entityNames = <String, String>{}; // code -> name
    for (final p in state.items) {
      for (final e in p.involvedEntity) {
        if (e.code.trim().isEmpty || e.code == '-') continue;
        entityNames.putIfAbsent(e.code, () => e.name);
      }
    }
    final entityCodes = entityNames.keys.toList()..sort();

    final users =
        state.items
            .map((p) => p.createdBy)
            .where((e) => e.trim().isNotEmpty && e != '-')
            .toSet()
            .toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    var tClient = _clientFilter;
    var tEntity = _entityFilter;
    var tUser = _userFilter;
    var tProb = _probFilter;

    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheet) {
            Future<void> pick({
              required String title,
              required List<String> values,
              required String? selected,
              required ValueChanged<String?> onPicked,
              String Function(String)? labelOf,
            }) async {
              final result = await showModalBottomSheet<_PickResult>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _PickerSheet(
                  title: title,
                  values: values,
                  selected: selected,
                  labelOf: labelOf,
                ),
              );
              if (result == null) return;
              setSheet(() => onPicked(result.value));
            }

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                20 + MediaQuery.of(context).viewPadding.bottom,
              ),
              child: SafeArea(
                top: false,
                bottom: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Filter Project',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(sheetContext, false),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _filterLabel('Client'),
                    _FilterField(
                      icon: Icons.apartment_outlined,
                      value: tClient ?? 'All',
                      isPlaceholder: tClient == null,
                      onTap: () => pick(
                        title: 'Select Client',
                        values: clients,
                        selected: tClient,
                        onPicked: (v) => tClient = v,
                      ),
                    ),
                    const SizedBox(height: 14),

                    _filterLabel('Entity'),
                    _FilterField(
                      icon: Icons.account_tree_outlined,
                      value: tEntity == null
                          ? 'All'
                          : '$tEntity - ${entityNames[tEntity] ?? ''}',
                      isPlaceholder: tEntity == null,
                      onTap: () => pick(
                        title: 'Select Entity',
                        values: entityCodes,
                        selected: tEntity,
                        labelOf: (c) => '$c - ${entityNames[c] ?? ''}',
                        onPicked: (v) => tEntity = v,
                      ),
                    ),
                    const SizedBox(height: 14),

                    _filterLabel('Probability'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final p in _ProbabilityFilter.values)
                          _ProbChip(
                            label: p.label,
                            selected: tProb == p,
                            onTap: () => setSheet(() => tProb = p),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    _filterLabel('User'),
                    _FilterField(
                      icon: Icons.person_outline_rounded,
                      value: tUser ?? 'All',
                      isPlaceholder: tUser == null,
                      onTap: () => pick(
                        title: 'Select User',
                        values: users,
                        selected: tUser,
                        onPicked: (v) => tUser = v,
                      ),
                    ),
                    const SizedBox(height: 22),

                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: OutlinedButton(
                              onPressed: () => setSheet(() {
                                tClient = null;
                                tEntity = null;
                                tUser = null;
                                tProb = _ProbabilityFilter.all;
                              }),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF075985),
                                side: const BorderSide(
                                  color: Color(0xFF075985),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Reset',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 46,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: _gradient,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ElevatedButton(
                                onPressed: () =>
                                    Navigator.pop(sheetContext, true),
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
                                  'Apply',
                                  style: TextStyle(fontWeight: FontWeight.w600),
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
            );
          },
        );
      },
    );

    if (applied == true && mounted) {
      setState(() {
        _clientFilter = tClient;
        _entityFilter = tEntity;
        _userFilter = tUser;
        _probFilter = tProb;
      });
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
    }
  }

  Widget _filterLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF374151),
        ),
      ),
    );
  }

  Widget _buildSliverBody(ProjectListPagingState state) {
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

    final q = _query.trim().toLowerCase();
    final filtered = state.items.where((p) {
      if (!_matchesFilters(p)) return false;
      if (q.isEmpty) return true;
      return p.clientName.toLowerCase().contains(q) ||
          p.projectName.toLowerCase().contains(q) ||
          p.projectStatus.toLowerCase().contains(q) ||
          p.salesStatus.toLowerCase().contains(q);
    }).toList();

    // Filter bekerja dari data yang sudah ter-load, jadi selama filter aktif
    // halaman berikutnya dimuat otomatis supaya hasilnya lengkap.
    final autoLoadMore =
        _hasActiveFilter && state.hasMore && !state.isLoadingMore;
    if (autoLoadMore) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(projectListPagingProvider.notifier).loadMore();
        }
      });
    }

    if (filtered.isEmpty) {
      if (_hasActiveFilter && (state.hasMore || state.isLoadingMore)) {
        return const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      }
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

    // Loader "load more": saat search saja tidak relevan (search hanya
    // menyaring data yang sudah ter-load), tapi saat filter aktif tetap tampil.
    final showTrailingLoader =
        (_hasActiveFilter && (state.hasMore || state.isLoadingMore)) ||
        (_query.isEmpty && (state.isLoadingMore || state.hasMore));
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

          final project = filtered[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProjectDetailScreen(projectId: project.id),
                  ),
                );
              },
              child: _buildProjectCard(project),
            ),
          );
        }, childCount: itemCount),
      ),
    );
  }

  Widget _buildProjectCard(ProjectListItem project) {
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
                      project.projectName,
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
                          Icons.apartment_outlined,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            project.clientName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    _buildStatusBadge(project.salesStatus),
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
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${project.expectedStartDate} - ${project.expectedEndDate}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF222222),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF0F1F5)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildCardInfo(
                  icon: Icons.account_tree_outlined,
                  label: 'Involved Entity',
                  value: project.involvedEntity.isEmpty
                      ? '-'
                      : project.involvedEntity.map((e) => e.code).join(', '),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCardInfo(
                  icon: Icons.payments_outlined,
                  label: 'Deal Value',
                  value: formatRupiah(project.dealValue),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 15, color: const Color(0xFF6B7280)),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final label = _normalizeStatusLabel(status);
    final color = _statusColor(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  String _normalizeStatusLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case 'won':
        return 'WON';
      case 'lost':
        return 'LOST';
      case 'done':
      case 'completed':
      case 'complete':
      case 'finished':
        return 'DONE';
      case 'pending':
      case 'ongoing':
      case 'on going':
      case 'in progress':
        return 'PENDING';
      default:
        return '-';
    }
  }

  Color _statusColor(String label) {
    switch (label) {
      case 'WON':
        return const Color(0xFF16A34A);
      case 'LOST':
        return const Color(0xFFDC2626);
      case 'DONE':
        return const Color(0xFF2563EB);
      case 'PENDING':
        return const Color(0xFFF59E0B);
      case '-':
      default:
        return const Color(0xFF9CA3AF);
    }
  }
}

// =============================================================================
// Widget pendukung modal filter
// =============================================================================

/// Hasil pilihan dari picker. `value == null` artinya "All".
class _PickResult {
  final String? value;
  const _PickResult(this.value);
}

class _FilterField extends StatelessWidget {
  final IconData icon;
  final String value;
  final bool isPlaceholder;
  final VoidCallback onTap;

  const _FilterField({
    required this.icon,
    required this.value,
    required this.isPlaceholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF6B7280)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: isPlaceholder ? FontWeight.w400 : FontWeight.w600,
                  color: isPlaceholder
                      ? const Color(0xFF6B7280)
                      : const Color(0xFF1A1A2E),
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF6B7280),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProbChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ProbChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF93C5FD) : const Color(0xFFE0E0E0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? const Color(0xFF1D4ED8) : const Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }
}

/// Picker satu pilihan dengan kolom pencarian. Item pertama selalu "All".
class _PickerSheet extends StatefulWidget {
  final String title;
  final List<String> values;
  final String? selected;
  final String Function(String)? labelOf;

  const _PickerSheet({
    required this.title,
    required this.values,
    required this.selected,
    this.labelOf,
  });

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  String _search = '';

  String _label(String v) => widget.labelOf?.call(v) ?? v;

  @override
  Widget build(BuildContext context) {
    final q = _search.trim().toLowerCase();
    final visible = widget.values
        .where((v) => q.isEmpty || _label(v).toLowerCase().contains(q))
        .toList();
    final height = MediaQuery.of(context).size.height * 0.7;
    final keyboard = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _search = v),
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'Search...',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  if (q.isEmpty)
                    _tile(
                      label: 'All',
                      selected: widget.selected == null,
                      onTap: () =>
                          Navigator.pop(context, const _PickResult(null)),
                    ),
                  for (final v in visible)
                    _tile(
                      label: _label(v),
                      selected: widget.selected == v,
                      onTap: () => Navigator.pop(context, _PickResult(v)),
                    ),
                  if (visible.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'Tidak ada data',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected
                      ? const Color(0xFF075985)
                      : const Color(0xFF1A1A2E),
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_rounded,
                size: 20,
                color: Color(0xFF075985),
              ),
          ],
        ),
      ),
    );
  }
}
