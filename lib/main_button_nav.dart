import 'package:corim/admin/home/home_screen.dart';
import 'package:corim/auth/auth_provider.dart';
import 'package:corim/auth/login_screen.dart';
import 'package:corim/crm/client/client_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MainNavItem { home, folder, contact, list }

class MainBottomNav extends ConsumerWidget {
  final MainNavItem currentItem;

  const MainBottomNav({super.key, required this.currentItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D52),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navImageItem(
              context,
              asset: 'assets/images/home/nav/home.png',
              item: MainNavItem.home,
              onTap: () {
                if (currentItem != MainNavItem.home) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                }
              },
            ),
            _navImageItem(
              context,
              asset: 'assets/images/home/nav/folder.png',
              item: MainNavItem.folder,
              onTap: () {
                if (currentItem != MainNavItem.folder) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const ClientListScreen()),
                  );
                }
              },
            ),
            GestureDetector(
              onTap: () => _handleLogout(context, ref),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Image.asset(
                  'assets/images/home/nav/contact.png',
                  width: 26,
                  height: 26,
                  color: Colors.white60,
                ),
              ),
            ),
            _navImageItem(
              context,
              asset: 'assets/images/home/nav/list.png',
              item: MainNavItem.list,
              onTap: () {
                // TODO: arahkan ke halaman list kalau sudah ada screen-nya
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Keluar Aplikasi',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari aplikasi?',
          style: TextStyle(fontSize: 14, color: Color(0xFF555555)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Batal',
              style: TextStyle(color: Color(0xFF555555)),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B1C52), Color(0xFF075985)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Keluar'),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await ref.read(authProvider.notifier).forceLogout();
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  Widget _navImageItem(
    BuildContext context, {
    required String asset,
    required MainNavItem item,
    required VoidCallback onTap,
  }) {
    final isActive = item == currentItem;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Image.asset(
          asset,
          width: 26,
          height: 26,
          color: isActive ? Colors.white : Colors.white60,
        ),
      ),
    );
  }
}
