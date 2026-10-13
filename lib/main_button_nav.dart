import 'package:corim/admin/home/home_screen.dart';
import 'package:corim/profile/profile_screen.dart';
import 'package:corim/request/request_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MainNavItem { home, folder, contact, list, request }

class MainBottomNav extends ConsumerWidget {
  final MainNavItem currentItem;

  const MainBottomNav({super.key, required this.currentItem});

  void _go(BuildContext context, MainNavItem target, Widget page) {
    if (currentItem == target) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return UnconstrainedBox(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Container(
          width: 220,
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
              _navItem(
                item: MainNavItem.home,
                image: 'assets/images/home/nav/home.png',
                onTap: () => _go(context, MainNavItem.home, const HomeScreen()),
              ),
              _navItem(
                item: MainNavItem.request,
                icon: Icons.assignment_outlined,
                onTap: () =>
                    _go(context, MainNavItem.request, const RequestScreen()),
              ),
              _navItem(
                item: MainNavItem.contact,
                image: 'assets/images/home/nav/contact.png',
                onTap: () =>
                    _go(context, MainNavItem.contact, const ProfileScreen()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required MainNavItem item,
    String? image,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    final color = item == currentItem ? Colors.white : Colors.white60;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: image != null
            ? Image.asset(image, width: 26, height: 26, color: color)
            : Icon(icon, size: 26, color: color),
      ),
    );
  }
}
