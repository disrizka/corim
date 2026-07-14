import 'package:flutter/material.dart';

class NotifColors {
  NotifColors._();

  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textFaint = Color(0xFF9CA3AF);
  static const Color background = Color(0xFFF5F6FA);
  static const Color divider = Color(0xFFE9EAF0);
  static const Color cardBorder = Color(0xFFF0F1F5);

  static const Color gradientStart = Color(0xFF1B1C52);
  static const Color gradientEnd = Color(0xFF075985);

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [gradientStart, gradientEnd],
  );
}

class NotifStatus {
  final Color bg;
  final Color fg;
  final Color accent;
  final String label;
  final IconData icon;

  const NotifStatus({
    required this.bg,
    required this.fg,
    required this.accent,
    required this.label,
    required this.icon,
  });

  static const _pending = NotifStatus(
    bg: Color(0xFFFEF3C7),
    fg: Color(0xFF92400E),
    accent: Color(0xFFF59E0B),
    label: 'TERTUNDA',
    icon: Icons.hourglass_top_rounded,
  );

  static const _approved = NotifStatus(
    bg: Color(0xFFDCFCE7),
    fg: Color(0xFF166534),
    accent: Color(0xFF16A34A),
    label: 'DISETUJUI',
    icon: Icons.check_circle_rounded,
  );

  static const _rejected = NotifStatus(
    bg: Color(0xFFFEE2E2),
    fg: Color(0xFF991B1B),
    accent: Color(0xFFDC2626),
    label: 'DITOLAK',
    icon: Icons.cancel_rounded,
  );

  factory NotifStatus.fromApproval(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return _approved;
      case 'REJECTED':
        return _rejected;
      default:
        return _pending;
    }
  }
}

class NotifStatusBadge extends StatelessWidget {
  final String status;
  final bool dense;

  const NotifStatusBadge({super.key, required this.status, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final s = NotifStatus.fromApproval(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 9 : 12,
        vertical: dense ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        s.label,
        style: TextStyle(
          fontSize: dense ? 10 : 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: s.fg,
        ),
      ),
    );
  }
}

class NotifIconChip extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color foreground;
  final double size;

  const NotifIconChip({
    super.key,
    required this.icon,
    required this.background,
    required this.foreground,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(icon, size: size * 0.5, color: foreground),
    );
  }
}
