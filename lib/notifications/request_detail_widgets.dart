import 'package:corim/api/api.dart';
import 'package:corim/notifications/notification_style.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class RequestDetailHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const RequestDetailHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.black87,
          size: 18,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Request Detail',
        style: TextStyle(
          color: Colors.black87,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class RequestInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const RequestInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Same layout as [RequestInfoRow], but the value is a tappable link
/// (e.g. project or client name that navigates to its own detail page).
/// Falls back to plain, non-underlined text when [onTap] is null or the
/// value is empty/"-", so callers don't need to guard against missing data.
class RequestInfoLinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const RequestInfoLinkRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLink = onTap != null && value.trim().isNotEmpty && value != '-';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: isLink
                ? InkWell(
                    onTap: onTap,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF075985),
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFF075985),
                      ),
                    ),
                  )
                : Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Same layout as [RequestInfoRow], but the value slot renders an arbitrary
/// widget (e.g. a status badge) instead of plain text.
class RequestInfoWidgetRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;

  const RequestInfoWidgetRow({
    super.key,
    required this.icon,
    required this.label,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Align(alignment: Alignment.centerLeft, child: trailing),
        ],
      ),
    );
  }
}

class RequestFileTile extends StatelessWidget {
  final dynamic file;

  const RequestFileTile({super.key, required this.file});

  static const _urlKeys = [
    'url',
    'path',
    'fileUrl',
    'filePath',
    'documentUrl',
    'downloadUrl',
    'link',
    'src',
    'file',
    'fileName',
    'filename',
  ];

  static const _labelKeys = [
    'name',
    'fileName',
    'filename',
    'originalName',
    'originalFileName',
    'title',
  ];

  String get _label {
    if (file is Map) {
      final map = file as Map;
      for (final key in _labelKeys) {
        final v = map[key];
        if (v != null && v.toString().trim().isNotEmpty) return v.toString();
      }
      final raw = _rawUrlFromFile;
      return raw.isNotEmpty ? raw.split('/').last : 'file';
    }
    final raw = file.toString();
    return raw.isNotEmpty ? raw.split('/').last : 'file';
  }

  String get _rawUrlFromFile {
    if (file is String) return file;
    if (file is Map) {
      final map = file as Map;
      for (final key in _urlKeys) {
        final v = map[key];
        if (v != null && v.toString().trim().isNotEmpty) return v.toString();
      }
    }
    return '';
  }

  /// The backend often stores files as a bare relative path (e.g.
  /// "expenses/xxx.pdf") instead of a full URL. A schemeless path can't be
  /// opened directly, so it needs [ApiConfig.storageBaseUrl] prepended.
  /// Values that already have a scheme (http/https) are left as-is.
  String get _urlFromFile {
    final raw = _rawUrlFromFile;
    if (raw.isEmpty) return raw;
    final uri = Uri.tryParse(raw);
    if (uri != null && uri.hasScheme) return raw;
    return ApiConfig.storageBaseUrl + raw.replaceFirst(RegExp(r'^/'), '');
  }

  Future<void> _open(BuildContext context) async {
    final url = _urlFromFile;
    if (url.isEmpty) {
      // No known key held a usable value. Surface the raw keys so this is
      // debuggable from the device itself instead of failing silently.
      final debugInfo = file is Map
          ? ' (keys: ${(file as Map).keys.join(', ')})'
          : ' (value: "$file")';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('File location not available$debugInfo'),
        ),
      );
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Invalid file link for $_label'),
        ),
      );
      return;
    }

    final canOpen = await canLaunchUrl(uri);
    if (!context.mounted) return;

    if (canOpen) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Unable to open $_label ($url)'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _label,
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
            onPressed: () => _open(context),
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

class RequestOutlinedActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const RequestOutlinedActionButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.open_in_new_rounded, size: 17),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF075985),
          side: const BorderSide(color: Color(0xFF075985)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

class RequestNoteField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const RequestNoteField({
    super.key,
    required this.controller,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: TextField(
            controller: controller,
            enabled: enabled,
            minLines: 3,
            maxLines: 5,
            maxLength: 2000,
            style: const TextStyle(fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'place the note verification here...',
              hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
              border: InputBorder.none,
              counterText: '',
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) => Text(
              'Maximum character ${controller.text.length}/2000',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ),
        ),
      ],
    );
  }
}

class RequestStatusBar extends StatelessWidget {
  final String status;

  const RequestStatusBar({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final s = NotifStatus.fromApproval(status);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(s.icon, size: 18, color: s.fg),
          const SizedBox(width: 8),
          Text(
            s.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: s.fg,
            ),
          ),
        ],
      ),
    );
  }
}

class RequestApprovalButtons extends StatelessWidget {
  final bool isSubmitting;
  final bool enabled;
  final VoidCallback onReject;
  final VoidCallback onApprove;

  const RequestApprovalButtons({
    super.key,
    required this.isSubmitting,
    required this.onReject,
    required this.onApprove,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 46,
            child: OutlinedButton(
              onPressed: (enabled && !isSubmitting) ? onReject : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFB91C1C),
                side: const BorderSide(color: Color(0xFFB91C1C)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Reject',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 46,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B1C52), Color(0xFF075985)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ElevatedButton(
                onPressed: (enabled && !isSubmitting) ? onApprove : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Approve',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> showRequestRejectedDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFB91C1C),
              ),
              child: const Icon(
                Icons.cancel_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Request Rejected',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You have rejected the request.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB91C1C),
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Okay',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> showRequestAcceptedDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF1B1C52), Color(0xFF075985)],
                ),
              ),
              child: const Icon(
                Icons.assignment_turned_in_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Request Accepted',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You was approved the request. Thank you!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B1C52), Color(0xFF075985)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Okay',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
