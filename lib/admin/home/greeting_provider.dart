import 'package:flutter_riverpod/flutter_riverpod.dart';

final greetingProvider = Provider<String>((ref) {
  final hour = DateTime.now().hour;

  if (hour >= 4 && hour < 11) return 'Good Morning';
  if (hour >= 11 && hour < 15) return 'Good Afternoon';
  if (hour >= 15 && hour < 19) return 'Good Evening';
  return 'Good Night';
});
