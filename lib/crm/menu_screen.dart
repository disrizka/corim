
import 'package:corim/crm/client_list/client_screen.dart';
import 'package:corim/crm/project/project_list_screen.dart.dart';
import 'package:flutter/material.dart';

class CrmMenuScreen extends StatelessWidget {
  const CrmMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.people_alt_outlined,
                    label: 'Client',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ClientListScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFFEFEFF3)),
                  _buildMenuItem(
                    context,
                    icon: Icons.description_outlined,
                    label: 'Project',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProjectListScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Expanded(child: SizedBox()),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F3F7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: Colors.black87,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'CRM Menu',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
          const SizedBox(width: 34),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: const Color(0xFF2563EB)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
