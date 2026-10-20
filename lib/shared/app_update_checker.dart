import 'dart:convert';
import 'dart:io';

import 'package:corim/api/api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class _VersionResult {
  final String latest;
  final bool mustUpdate;
  final String? storeUrl;
  final String? message;
  final bool hasNewVersion;
  final String skipId;
  final String appId;
  final int? code;
  _VersionResult({
    this.code,
    required this.skipId,
    required this.appId,
    required this.latest,
    required this.mustUpdate,
    required this.storeUrl,
    required this.hasNewVersion,
    this.message,
  });
}

class AppUpdateChecker {
  AppUpdateChecker._();

  static const _storage = FlutterSecureStorage();
  static const _skippedKey = 'skipped_update_version';
  static const String androidStoreUrl =
      'https://play.google.com/store/apps/details?id=com.corim.apex';

  static const String iosStoreUrl = '';
  static String? _serverMsg;
  static Future<void> check(BuildContext context, {bool manual = false}) async {
    PackageInfo? info;
    try {
      info = await PackageInfo.fromPlatform();

      if (manual) {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const PopScope(
            canPop: false,
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      }

      _serverMsg = null;
      final result = await _fetch(info);

      if (manual && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // tutup loading
      }
      if (!context.mounted) return;

      if (result == null) {
        if (manual) {
          await _showInfoDialog(
            context,
            title: 'Gagal Memeriksa Pembaruan',
            message: _serverMsg != null
                ? 'Informasi versi belum tersedia dari server ($_serverMsg).'
                : 'Tidak dapat memeriksa versi terbaru. Periksa koneksi internet Anda.',
            current: info.version,
            icon: Icons.error_outline_rounded,
          );
        }
        return;
      }

      if (!result.hasNewVersion && !result.mustUpdate) {
        if (manual) {
          await _showInfoDialog(
            context,
            title: 'Sudah Versi Terbaru',
            message: 'Aplikasi Anda sudah menggunakan versi terbaru.',
            current: info.version,
            latest: result.latest,
            icon: Icons.check_circle_outline_rounded,
          );
        }
        return;
      }

      if (!manual && !result.mustUpdate) {
        final skipped = await _storage.read(key: _skippedKey);
        if (skipped == result.skipId) return;
      }

      if (!context.mounted) return;
      await _showDialog(
        context,
        current: info.version,
        latest: result.latest,
        skipId: result.skipId,
        mustUpdate: result.mustUpdate,
        storeUrl: result.storeUrl,
        message: result.message,
        saveSkip: !manual,
      );
    } catch (e) {
      debugPrint('APP UPDATE CHECK ERROR >> $e');
      if (manual && context.mounted) {
        // pastikan loading tertutup kalau error setelah dibuka
        Navigator.of(context, rootNavigator: true).maybePop();
      }
    }
  }

  static Future<String?> fetchVersionLabel() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final r = await _fetch(info);
      if (r == null) return null;
      return 'v${r.latest}'; // sama dengan "Versi terbaru" di pop up update
    } catch (e) {
      debugPrint('FETCH VERSION LABEL ERROR >> $e');
      return null;
    }
  }

  static Future<_VersionResult?> _fetch(PackageInfo info) async {
    try {
      // Contoh: app/version?app=com.corim.apex
      var result = await _request(info, info.packageName);

      if (result == null && info.packageName.endsWith('dev')) {
        final prodId = info.packageName.substring(
          0,
          info.packageName.length - 3,
        );
        result = await _request(info, prodId);
      }
      return result;
    } catch (e) {
      debugPrint('APP VERSION FETCH ERROR >> $e');
      return null;
    }
  }

  static Future<_VersionResult?> _request(
    PackageInfo info,
    String appId,
  ) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}${Endpoints.appVersion}',
      ).replace(queryParameters: {'app': appId});

      final response = await http
          .get(uri, headers: {'Accept': ApiConfig.contentTypeJson})
          .timeout(const Duration(seconds: 8));

      debugPrint(
        'APP VERSION RESPONSE >> url=$uri, status=${response.statusCode}, body=${response.body}',
      );

      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return null;
      final root = Map<String, dynamic>.from(decoded);
      final data = root['data'] is Map
          ? Map<String, dynamic>.from(root['data'] as Map)
          : root;

      // Ambil data sesuai platform: data.android / data.ios
      final platformKey = Platform.isIOS ? 'ios' : 'android';
      final node = data[platformKey] is Map
          ? Map<String, dynamic>.from(data[platformKey] as Map)
          : null;

      final versionName = node == null
          ? null
          : _firstString(node, const ['versionName', 'version_name']);
      if (node == null || versionName == null) {
        _serverMsg =
            _firstString(root, const ['msg', 'message']) ??
            'data $platformKey tidak ditemukan';
        debugPrint(
          'APP VERSION >> data versi tidak ditemukan. keys=${data.keys.toList()}',
        );
        return null;
      }

      final serverCode = int.tryParse(
        _firstString(node, const ['versionCode', 'version_code']) ?? '',
      );
      final currentCode = int.tryParse(info.buildNumber) ?? 0;

      // Versi baru kalau versionCode server > build number di HP,
      // atau versionName server lebih tinggi dari versi di HP.
      final hasNew =
          (serverCode != null && serverCode > currentCode) ||
          _compare(info.version, versionName) < 0;

      final mustUpdate = _firstBool(node, const [
        'mustUpdate',
        'must_update',
        'forceUpdate',
        'force_update',
      ]);

      final serverAppId = _firstString(data, const ['app']) ?? appId;

      // Link store dari server (opsional). Kalau kosong, dibuat otomatis saat
      // tombol Update ditekan (Play Store / App Store).
      final storeUrl = _firstString(node, const [
        'storeUrl',
        'store_url',
        'url',
      ]);

      return _VersionResult(
        code: serverCode,
        skipId: '$versionName+${serverCode ?? ''}',
        appId: serverAppId,
        latest: versionName,
        mustUpdate: mustUpdate,
        storeUrl: storeUrl,
        hasNewVersion: hasNew,
        message: _firstString(node, const ['message', 'msg', 'description']),
      );
    } catch (e) {
      debugPrint('APP VERSION REQUEST ERROR >> $e');
      return null;
    }
  }

  static Future<void> _showInfoDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String current,
    String? latest,
    required IconData icon,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: const Color(0xFF1B1C52)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: const TextStyle(fontSize: 13.5)),
            const SizedBox(height: 12),
            Text(
              latest == null
                  ? 'Versi Anda: v$current'
                  : 'Versi Anda: v$current\nVersi terbaru: v$latest',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ],
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1B1C52),
            ),
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static Future<void> _showDialog(
    BuildContext context, {
    required String current,
    required String latest,
    required String skipId,
    required bool mustUpdate,
    String? storeUrl,
    String? message,
    bool saveSkip = true,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false, // tidak bisa ditutup dengan tap di luar
      builder: (dialogContext) {
        return PopScope(
          // must update: tombol back juga diblokir
          canPop: !mustUpdate,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.system_update_rounded,
                  color: Color(0xFF1B1C52),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    mustUpdate ? 'Update Diperlukan' : 'Versi Baru Tersedia',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message ??
                      (mustUpdate
                          ? 'Anda harus memperbarui aplikasi ke versi terbaru untuk melanjutkan.'
                          : 'Versi terbaru aplikasi sudah tersedia. Perbarui sekarang untuk fitur dan perbaikan terbaru.'),
                  style: const TextStyle(fontSize: 13.5),
                ),
                const SizedBox(height: 12),
                Text(
                  'Versi Anda: v$current\nVersi terbaru: v$latest',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            actions: [
              if (!mustUpdate)
                TextButton(
                  onPressed: () async {
                    if (saveSkip) {
                      await _storage.write(key: _skippedKey, value: skipId);
                    }
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  },
                  child: const Text('Nanti'),
                ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1B1C52),
                ),
                onPressed: () => _openStore(storeUrl),
                child: const Text('Update'),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Android -> Play Store, iOS -> App Store.
  static Future<void> _openStore(String? serverStoreUrl) async {
    try {
      String? url;
      if (Platform.isAndroid) {
        url = androidStoreUrl;
      } else if (Platform.isIOS) {
        // Pakai link iOS di atas; kalau kosong, pakai link dari server (jika ada)
        url = iosStoreUrl.isNotEmpty ? iosStoreUrl : serverStoreUrl;
      }

      if (url == null || url.isEmpty) {
        debugPrint(
          'OPEN STORE >> link store belum tersedia untuk platform ini',
        );
        return;
      }
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('OPEN STORE ERROR >> $e');
    }
  }

  // ---------- helpers ----------

  static String? _firstString(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }
    return null;
  }

  static bool _firstBool(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v == null) continue;
      if (v is bool) return v;
      if (v is num) return v != 0;
      final s = v.toString().toLowerCase().trim();
      return s == 'true' || s == '1' || s == 'yes';
    }
    return false;
  }

  /// Bandingkan "1.0.0+5" vs "1.0.1". Hasil: <0 (a lebih lama), 0, >0.
  static int _compare(String a, String b) {
    List<int> parse(String v) {
      final parts = v.replaceFirst(RegExp(r'^[vV]'), '').split('+');
      final nums = parts[0]
          .split('.')
          .map((e) => int.tryParse(e.trim()) ?? 0)
          .toList();
      while (nums.length < 3) {
        nums.add(0);
      }
      final build = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      return [...nums.take(3), build];
    }

    final pa = parse(a);
    final pb = parse(b);
    // build number hanya dibandingkan kalau server mengirimnya ("+N")
    final compareBuild = b.contains('+') && a.contains('+');
    final len = compareBuild ? 4 : 3;
    for (var i = 0; i < len; i++) {
      if (pa[i] != pb[i]) return pa[i].compareTo(pb[i]);
    }
    return 0;
  }
}
