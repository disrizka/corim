// lib/shared/file_open_helper.dart
//
// Extracted 1:1 from NotificationDetailScreen so any widget (e.g.
// RequestFileTile in expense_request_detail_screen.dart) can open a file
// with the SAME behavior: image -> in-app viewer, pdf -> in-app viewer,
// anything else -> external app, and download/share support everywhere.
//
// Nothing here changes existing logic — this is just the same functions,
// made static/reusable so they aren't duplicated per-screen.

import 'dart:io';
import 'dart:typed_data';

import 'package:corim/api/api.dart';
import 'package:corim/notifications/notification_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ResolvedFile {
  final String url;
  final String label;
  const ResolvedFile({required this.url, required this.label});
}

class FileOpenHelper {
  FileOpenHelper._();

  static String resolveFileUrl(String raw) {
    if (raw.isEmpty) return raw;
    final uri = Uri.tryParse(raw);
    if (uri != null && uri.hasScheme) return raw;
    return ApiConfig.storageBaseUrl + raw.replaceFirst(RegExp(r'^/'), '');
  }

  /// Accepts either a raw String path/url, or a Map like
  /// { "url"/"path": ..., "name"/"fileName": ... }.
  static ResolvedFile fileInfo(dynamic file) {
    if (file is String) {
      return ResolvedFile(url: resolveFileUrl(file), label: file.split('/').last);
    } else if (file is Map) {
      final rawUrl = (file['url'] ?? file['path'] ?? '').toString();
      final label = (file['name'] ?? file['fileName'] ?? rawUrl.split('/').last)
          .toString();
      return ResolvedFile(url: resolveFileUrl(rawUrl), label: label);
    }
    return const ResolvedFile(url: '', label: 'file');
  }

  static bool isImageUrl(String url) {
    final clean = url.split('?').first.toLowerCase();
    return clean.endsWith('.png') ||
        clean.endsWith('.jpg') ||
        clean.endsWith('.jpeg') ||
        clean.endsWith('.gif') ||
        clean.endsWith('.webp') ||
        clean.endsWith('.bmp');
  }

  static bool isPdfUrl(String url) {
    return url.split('?').first.toLowerCase().endsWith('.pdf');
  }

  /// Main entry point: call this from any file tile's onTap.
  /// Handles image/pdf in-app preview, otherwise tries external app,
  /// otherwise falls back to download+share.
  static Future<void> openFile(BuildContext context, dynamic file) async {
    final info = fileInfo(file);
    final url = info.url;
    final label = info.label;

    if (url.isEmpty) return;

    if (isImageUrl(url)) {
      showImagePreview(context, url, label);
      return;
    }

    if (isPdfUrl(url)) {
      showPdfPreview(context, url, label);
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final canOpen = await canLaunchUrl(uri);
    if (!context.mounted) return;

    if (canOpen) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Tidak ada aplikasi untuk membuka $label, mengunduh...'),
      ),
    );
    await downloadAndShareFile(context, url, label);
  }

  /// Public so other tiles (e.g. RequestFileTile) can reuse the exact same
  /// download+share fallback with their own url/label resolution.
  static Future<void> downloadAndShareFile(
    BuildContext context,
    String url,
    String label,
  ) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Gagal mengunduh file (${response.statusCode})');
      }

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$label';
      final localFile = File(filePath);
      await localFile.writeAsBytes(response.bodyBytes);

      if (!context.mounted) return;
      await SharePlus.instance.share(
        ShareParams(files: [XFile(filePath)], text: label),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Gagal mengunduh $label: $e'),
        ),
      );
    }
  }

  /// Public so other tiles (e.g. RequestFileTile) can reuse the exact same
  /// in-app image preview with their own url/label resolution.
  static void showImagePreview(BuildContext context, String url, String label) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => ImagePreviewScreen(url: url, label: label),
      ),
    );
  }

  /// Public so other tiles (e.g. RequestFileTile) can reuse the exact same
  /// in-app PDF preview with their own url/label resolution.
  static void showPdfPreview(BuildContext context, String url, String label) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(url: url, label: label),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Image preview (in-app) — identical to NotificationDetailScreen's
// _ImagePreviewScreen, just made public/reusable.
// ---------------------------------------------------------------------
class ImagePreviewScreen extends StatefulWidget {
  final String url;
  final String label;

  const ImagePreviewScreen({super.key, required this.url, required this.label});

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  bool _isDownloading = false;

  Future<void> _downloadImage() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      final response = await http.get(Uri.parse(widget.url));

      if (response.statusCode != 200) {
        throw Exception('Gagal mengunduh file (${response.statusCode})');
      }

      final Uint8List bytes = response.bodyBytes;
      await Gal.putImageBytes(bytes, name: widget.label);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Gambar berhasil disimpan ke galeri'),
        ),
      );
    } on GalException catch (e) {
      if (!mounted) return;
      final isAccessDenied = e.type == GalExceptionType.accessDenied;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            isAccessDenied
                ? 'Izin akses galeri ditolak. Aktifkan izin di pengaturan aplikasi.'
                : 'Gagal menyimpan gambar: ${e.type}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Gagal mengunduh gambar: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.4),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.label,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            onPressed: _isDownloading ? null : _downloadImage,
            icon: _isDownloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download_rounded),
            tooltip: 'Download',
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 5,
            child: Image.network(
              widget.url,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const CircularProgressIndicator(color: Colors.white);
              },
              errorBuilder: (context, error, stack) => const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 48,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Gagal memuat gambar',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// PDF preview (in-app) — identical to NotificationDetailScreen's
// _PdfPreviewScreen, just made public/reusable.
// ---------------------------------------------------------------------
class PdfPreviewScreen extends StatefulWidget {
  final String url;
  final String label;

  const PdfPreviewScreen({super.key, required this.url, required this.label});

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  bool _isDownloading = false;

  String? _localPath;
  String? _loadError;
  int? _totalPages;
  PDFViewController? _pdfController;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    setState(() {
      _loadError = null;
      _localPath = null;
      _totalPages = null;
    });
    try {
      final response = await http.get(
        Uri.parse(widget.url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0 Mobile Safari/537.36',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Server membalas status ${response.statusCode}');
      }

      final bytes = response.bodyBytes;
      if (bytes.isEmpty) {
        throw Exception('File kosong / tidak ada data yang diterima');
      }

      final isRealPdf =
          bytes.length >= 5 &&
          bytes[0] == 0x25 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x44 &&
          bytes[3] == 0x46 &&
          bytes[4] == 0x2D;

      if (!isRealPdf) {
        final preview = String.fromCharCodes(
          bytes.take(200).where((b) => b >= 32 && b < 127),
        );
        throw Exception(
          'Server tidak mengembalikan file PDF yang valid.\n'
          'Isi respons (preview): ${preview.isEmpty ? '(tidak bisa ditampilkan)' : preview}',
        );
      }

      final dir = await getTemporaryDirectory();
      final safeName = widget.label.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final file = File('${dir.path}/$safeName');
      await file.writeAsBytes(bytes, flush: true);

      if (!mounted) return;
      setState(() => _localPath = file.path);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e.toString());
    }
  }

  Future<void> _downloadPdf() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      final String filePath;
      if (_localPath != null) {
        filePath = _localPath!;
      } else {
        final response = await http.get(Uri.parse(widget.url));
        final dir = await getApplicationDocumentsDirectory();
        filePath = '${dir.path}/${widget.label}';
        await File(filePath).writeAsBytes(response.bodyBytes);
      }

      if (!mounted) return;

      await SharePlus.instance.share(
        ShareParams(files: [XFile(filePath)], text: widget.label),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Gagal mengunduh ${widget.label}: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: NotifColors.gradientStart,
        foregroundColor: Colors.white,
        title: Text(
          widget.label,
          style: const TextStyle(fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_totalPages != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  '$_totalPages hlm',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
            ),
          IconButton(
            onPressed: (_isDownloading || _localPath == null)
                ? null
                : _downloadPdf,
            icon: _isDownloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download_rounded),
            tooltip: 'Download',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.white54, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Gagal memuat PDF',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _loadError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _loadPdf,
                    child: const Text('Coba lagi'),
                  ),
                  if (_localPath != null)
                    OutlinedButton(
                      onPressed: _isDownloading ? null : _downloadPdf,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                      ),
                      child: const Text('Buka dengan app lain'),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (_localPath == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return PDFView(
      filePath: _localPath!,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: true,
      pageFling: true,
      pageSnap: true,
      fitPolicy: FitPolicy.BOTH,
      onRender: (pages) {
        if (!mounted) return;
        setState(() => _totalPages = pages);
      },
      onError: (error) {
        if (!mounted) return;
        setState(() => _loadError = error.toString());
      },
      onPageError: (page, error) {
        if (!mounted) return;
        setState(() => _loadError = 'Gagal render halaman $page: $error');
      },
      onViewCreated: (controller) {
        _pdfController = controller;
      },
    );
  }
}