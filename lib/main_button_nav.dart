import 'package:corim/admin/home/home_screen.dart';
import 'package:corim/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MainNavItem { home, folder, contact, list }

class MainBottomNav extends ConsumerWidget {
  final MainNavItem currentItem;

  const MainBottomNav({super.key, required this.currentItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return UnconstrainedBox(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Container(
          width: 160, 
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 12),
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
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                asset: 'assets/images/home/nav/contact.png',
                item: MainNavItem.contact,
                onTap: () {
                  if (currentItem != MainNavItem.contact) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
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
        padding: const EdgeInsets.all(8),
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
