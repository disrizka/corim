import 'package:corim/admin/home/activity_list_view.dart';
import 'package:corim/admin/home/greeting_provider.dart';
import 'package:corim/auth/auth_provider.dart';
import 'package:corim/crm/menu_screen.dart';
import 'package:corim/finance/finance_menu_screen.dart';
import 'package:corim/main_button_nav.dart';
import 'package:corim/notifications/notifcation_screen.dart';
import 'package:corim/notifications/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const double _bottomNavReservedHeight = 16 + 60 + 16;

  void _showComingSoon(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Coming Soon'),
        content: Text('This feature $feature is comming soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(context, ref),
              _buildMenuRow(context),
              _buildActivityHeader(),
              Expanded(
                child: ActivityInfiniteListView(
                  listPadding: const EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    _bottomNavReservedHeight + 8,
                  ),
                ),
              ),
            ],
          ),
          const Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: MainBottomNav(currentItem: MainNavItem.home),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Update Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingNotificationCountProvider);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF1B1C52), Color(0xFF075985)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white38, width: 2),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/logo.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${ref.watch(authProvider).name ?? 'User'}!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      ref.watch(greetingProvider),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationScreen(),
                    ),
                  );
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 26,
                    ),
                    if (pending > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$pending',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                            ),
                          ),
                        ),
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

  Widget _buildMenuRow(BuildContext context) {
    final menus = [
      {
        'asset': 'assets/images/home/crm.png',
        'label': 'CRM',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CrmMenuScreen()),
        ),
      },
      {
        'asset': 'assets/images/home/finance.png',
        'label': 'FINANCE',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FinanceMenuScreen()),
        ),
      },
      {
        'asset': 'assets/images/home/hr.png',
        'label': 'HR',
        'onTap': () => _showComingSoon('HR'),
      },
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: menus.map((m) {
          return GestureDetector(
            onTap: m['onTap'] as VoidCallback,
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B3A6B),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Image.asset(m['asset'] as String, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  m['label'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
