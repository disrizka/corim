import 'dart:io';
import 'dart:typed_data';

import 'package:corim/admin/project/project_detail_screen.dart';
import 'package:corim/api/api.dart';
import 'package:corim/notifications/notification_model.dart';
import 'package:corim/notifications/notification_provider.dart';
import 'package:corim/notifications/notification_style.dart';
import 'package:corim/notifications/request_detail_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationDetailScreen extends ConsumerStatefulWidget {
  final String notificationId;

  const NotificationDetailScreen({super.key, required this.notificationId});

  @override
  ConsumerState<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState
    extends ConsumerState<NotificationDetailScreen> {
  final _noteController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit(bool approve) async {
    setState(() => _isSubmitting = true);
    final ok = await ref
        .read(notificationListProvider.notifier)
        .sendAction(
          widget.notificationId,
          approve: approve,
          note: _noteController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (ok) {
      if (approve) {
        await showRequestAcceptedDialog(context);
      } else {
        await showRequestRejectedDialog(context);
      }
      if (mounted) Navigator.pop(context);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.grey.shade800,
        content: const Text('Failed to process request, please try again'),
      ),
    );
  }

  String _resolveFileUrl(String raw) {
    if (raw.isEmpty) return raw;
    final uri = Uri.tryParse(raw);
    if (uri != null && uri.hasScheme) return raw;
    return ApiConfig.storageBaseUrl + raw.replaceFirst(RegExp(r'^/'), '');
  }

  ({String url, String label}) _fileInfo(dynamic file) {
    if (file is String) {
      return (url: _resolveFileUrl(file), label: file.split('/').last);
    } else if (file is Map) {
      final rawUrl = (file['url'] ?? file['path'] ?? '').toString();
      final label = (file['name'] ?? file['fileName'] ?? rawUrl.split('/').last)
          .toString();
      return (url: _resolveFileUrl(rawUrl), label: label);
    }
    return (url: '', label: 'file');
  }

  bool _isImageUrl(String url) {
    final clean = url.split('?').first.toLowerCase();
    return clean.endsWith('.png') ||
        clean.endsWith('.jpg') ||
        clean.endsWith('.jpeg') ||
        clean.endsWith('.gif') ||
        clean.endsWith('.webp') ||
        clean.endsWith('.bmp');
  }

  bool _isPdfUrl(String url) {
    return url.split('?').first.toLowerCase().endsWith('.pdf');
  }

  Future<void> _openFile(dynamic file) async {
    final info = _fileInfo(file);
    final url = info.url;
    final label = info.label;

    if (url.isEmpty) return;

    if (_isImageUrl(url)) {
      _showImagePreview(url, label);
      return;
    }

    if (_isPdfUrl(url)) {
      _showPdfPreview(url, label);
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final canOpen = await canLaunchUrl(uri);
    if (!mounted) return;

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
    await _downloadAndShareFile(url, label);
  }

  Future<void> _downloadAndShareFile(String url, String label) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Gagal mengunduh file (${response.statusCode})');
      }

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$label';
      final localFile = File(filePath);
      await localFile.writeAsBytes(response.bodyBytes);

      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(files: [XFile(filePath)], text: label),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Gagal mengunduh $label: $e'),
        ),
      );
    }
  }

  void _showImagePreview(String url, String label) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) =>
            _ImagePreviewScreen(url: url, label: label),
      ),
    );
  }

  void _showPdfPreview(String url, String label) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PdfPreviewScreen(url: url, label: label),
      ),
    );
  }

  void _openProject(NotificationItem n) {
    if (n.projectId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('No project linked to this request'),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectDetailScreen(projectId: n.projectId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(
      notificationDetailProvider(widget.notificationId),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const RequestDetailHeader(),
      body: detailAsync.when(
        data: (n) => _buildBody(context, n),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => _buildError(err),
      ),
    );
  }

  Widget _buildError(Object err) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 40,
              color: Color(0xFFB91C1C),
            ),
            const SizedBox(height: 12),
            const Text('Failed to load request detail'),
            const SizedBox(height: 6),
            Text(
              err.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref
                  .read(
                    notificationDetailProvider(widget.notificationId).notifier,
                  )
                  .fetch(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, NotificationItem n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            n.title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            n.desc,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: Color(0xFF444444),
            ),
          ),
          const SizedBox(height: 18),

          RequestInfoRow(
            icon: Icons.person_outline,
            label: 'Request By:',
            value: n.requestedBy,
          ),
          RequestInfoRow(
            icon: Icons.access_time_rounded,
            label: 'Request At:',
            value: '${n.activityDateId}, ${n.activityTime}',
          ),
          RequestInfoRow(
            icon: Icons.apartment_outlined,
            label: 'Entity:',
            value: n.entity,
          ),
          RequestInfoRow(
            icon: Icons.business_outlined,
            label: 'Client Name:',
            value: n.clientName,
          ),
          RequestInfoRow(
            icon: Icons.folder_outlined,
            label: 'Project Name:',
            value: n.projectName,
          ),

          const SizedBox(height: 16),
          const Text(
            'File Document:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 4),
          if (n.files.isEmpty)
            Text(
              'No documents attached',
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
            )
          else
            for (final f in n.files) _buildFileTile(f),

          const SizedBox(height: 18),
          RequestOutlinedActionButton(
            label: 'View Project Detail',
            onPressed: () => _openProject(n),
          ),

          const SizedBox(height: 20),
          if (n.isPending) ...[
            RequestNoteField(controller: _noteController, enabled: true),
            const SizedBox(height: 18),
            RequestApprovalButtons(
              isSubmitting: _isSubmitting,
              enabled: true,
              onReject: () => _submit(false),
              onApprove: () => _submit(true),
            ),
          ] else ...[
            if (n.note != null && n.note!.trim().isNotEmpty) ...[
              Text(
                'Note:',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  n.note!,
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
                ),
              ),
              const SizedBox(height: 14),
            ],
            RequestStatusBar(status: n.approvalStatus),
          ],
        ],
      ),
    );
  }

  Widget _buildFileTile(dynamic file) {
    final info = _fileInfo(file);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              info.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF075985),
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () => _openFile(file),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF075985),
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.insert_drive_file_outlined, size: 15),
            label: const Text('Open File', style: TextStyle(fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}

class _ImagePreviewScreen extends StatefulWidget {
  final String url;
  final String label;

  const _ImagePreviewScreen({required this.url, required this.label});

  @override
  State<_ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<_ImagePreviewScreen> {
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

class _PdfPreviewScreen extends StatefulWidget {
  final String url;
  final String label;

  const _PdfPreviewScreen({required this.url, required this.label});

  @override
  State<_PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<_PdfPreviewScreen> {
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
