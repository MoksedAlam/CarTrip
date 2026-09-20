import 'package:flutter/material.dart';
import '../../../core/widgets/app_button.dart';
import '../data/update_service.dart';
import '../models/app_update_info.dart';

class UpdateDialog extends StatefulWidget {
  final AppUpdateInfo updateInfo;
  final UpdateService updateService;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
    required this.updateService,
  });

  static Future<void> show(
    BuildContext context, {
    required AppUpdateInfo updateInfo,
    required UpdateService updateService,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: !updateInfo.isMandatory,
      builder: (ctx) => UpdateDialog(
        updateInfo: updateInfo,
        updateService: updateService,
      ),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String? _errorMessage;

  Future<void> _handleDownload() async {
    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _errorMessage = null;
    });

    final success = await widget.updateService.downloadAndInstall(
      downloadUrl: widget.updateInfo.downloadUrl,
      onProgress: (pct) {
        if (mounted) {
          setState(() => _progress = pct);
        }
      },
    );

    if (mounted) {
      setState(() => _isDownloading = false);
      if (!success) {
        setState(() {
          _errorMessage = 'Failed to download or install update. Please try again.';
        });
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !widget.updateInfo.isMandatory && !_isDownloading,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.system_update_rounded,
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Update Available',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'v${widget.updateInfo.latestVersion}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              "What's New:",
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 140),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: SingleChildScrollView(
                child: Text(
                  widget.updateInfo.releaseNotes,
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                ),
              ),
            ),
            if (_isDownloading) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Downloading APK...', style: theme.textTheme.bodySmall),
                  Text(
                    '${(_progress * 100).toStringAsFixed(0)}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                borderRadius: BorderRadius.circular(8),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          if (!_isDownloading && !widget.updateInfo.isMandatory)
            TextButton(
              onPressed: () {
                if (widget.updateInfo.updateId.isNotEmpty) {
                  widget.updateService.dismissUpdate(widget.updateInfo.updateId);
                }
                Navigator.of(context).pop();
              },
              child: const Text('Later'),
            ),
          if (!_isDownloading)
            AppButton(
              label: 'Update Now',
              onPressed: _handleDownload,
            ),
        ],
      ),
    );
  }
}
