import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/portfolio/datasources/export_service.dart';
import '../../../domain/portfolio/portfolio_entity.dart';
import '../utils/artifact_saver.dart';

class ExportModal extends StatefulWidget {
  const ExportModal({
    super.key,
    required this.config,
    this.exportService = const PortfolioExportService(),
  });

  final PortfolioConfig config;
  final PortfolioExportService exportService;

  @override
  State<ExportModal> createState() => _ExportModalState();
}

class _ExportModalState extends State<ExportModal> {
  ExportFormat _selectedFormat = ExportFormat.pdf;
  bool _isExporting = false;
  String? _error;
  Uint8List? _latestBytes;
  String? _lastSavedPath;
  String? _cachedFileName;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Export portfolio',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final format in ExportFormat.values)
                      RadioListTile<ExportFormat>(
                        title: Text(format.name.toUpperCase()),
                        subtitle: Text(_formatDescription(format)),
                        value: format,
                        // ignore: deprecated_member_use
                        groupValue: _selectedFormat,
                        // ignore: deprecated_member_use
                        onChanged: _isExporting
                            ? null
                            : (value) =>
                                setState(() => _selectedFormat = value!),
                      ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.red),
                      ),
                    ],
                    const SizedBox(height: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _isExporting
                          ? const _ExportProgress()
                          : FilledButton.icon(
                              onPressed: _startExport,
                              icon: const Icon(Icons.ios_share),
                              label: const Text('Generate export'),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startExport() async {
    setState(() {
      _isExporting = true;
      _error = null;
      _lastSavedPath = null;
      _cachedFileName = null;
    });

    try {
      final bytes = await _runExport();
      if (!mounted) return;
      _latestBytes = bytes;
      _cachedFileName = _cachedFileName ?? _buildFileName();
      await _showSuccessDialog();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Export failed: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<Uint8List> _runExport() {
    switch (_selectedFormat) {
      case ExportFormat.pdf:
        return widget.exportService.exportToPdf(widget.config);
      case ExportFormat.markdown:
        return widget.exportService.exportToMarkdown(widget.config);
      case ExportFormat.html:
        return widget.exportService.exportToHtml(widget.config);
      case ExportFormat.json:
        return widget.exportService.exportToJson(widget.config);
    }
  }

  Future<void> _showSuccessDialog() async {
    final size = _latestBytes?.length ?? 0;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Export ready'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_selectedFormat.name.toUpperCase()} file generated ($size bytes).',
              ),
              const SizedBox(height: 16),
              Text(
                'Share options',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _ShareOption(
                icon: Icons.save_alt,
                label: 'Save locally',
                onTap: () => _handleSaveLocally(dialogContext),
              ),
              _ShareOption(
                icon: Icons.link,
                label: 'Copy link',
                onTap: () => _handleCopyLink(dialogContext),
              ),
              _ShareOption(
                icon: Icons.send_outlined,
                label: 'Share with contacts',
                onTap: () => _handleShareWithContacts(dialogContext),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleSaveLocally(BuildContext dialogContext) async {
    Navigator.of(dialogContext).pop();
    final savedPath = await _persistArtifact();
    if (!mounted) return;
    final message = savedPath == null
        ? 'Unable to save the export. Please try again.'
        : 'Saved export to $savedPath';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _handleCopyLink(BuildContext dialogContext) async {
    Navigator.of(dialogContext).pop();
    final path = await _persistArtifact();
    if (!mounted) return;
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Nothing to copy. Generate an export first.')),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: path));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export location copied to clipboard.')),
    );
  }

  Future<void> _handleShareWithContacts(BuildContext dialogContext) async {
    Navigator.of(dialogContext).pop();
    final bytes = _latestBytes;
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No export artifact to share.')),
      );
      return;
    }
    final fileName = _resolveFileName();
    final mimeType = _mimeTypeForFormat(_selectedFormat);
    try {
      await Share.shareXFiles(
        [XFile.fromData(bytes, name: fileName, mimeType: mimeType)],
        text: 'GitFolio export for ${widget.config.userId}',
        subject: 'Portfolio export',
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to invoke share sheet: $error')),
      );
    }
  }

  Future<String?> _persistArtifact() async {
    final bytes = _latestBytes;
    if (bytes == null) {
      return null;
    }
    if (_lastSavedPath != null) {
      return _lastSavedPath;
    }
    final fileName = _resolveFileName();
    final savedPath = await saveArtifactBytes(bytes, fileName);
    _lastSavedPath = savedPath ?? fileName;
    return _lastSavedPath;
  }

  String _resolveFileName() {
    return _cachedFileName ??= _buildFileName();
  }

  String _buildFileName() {
    final sanitizedId = widget.config.userId.replaceAll(
      RegExp(r'[^a-zA-Z0-9_-]'),
      '-',
    );
    final stamp = DateTime.now().millisecondsSinceEpoch;
    return 'gitfolio_${sanitizedId}_$stamp.${_selectedFormat.name}';
  }

  String _mimeTypeForFormat(ExportFormat format) {
    switch (format) {
      case ExportFormat.pdf:
        return 'application/pdf';
      case ExportFormat.markdown:
        return 'text/markdown';
      case ExportFormat.html:
        return 'text/html';
      case ExportFormat.json:
        return 'application/json';
    }
  }

  String _formatDescription(ExportFormat format) {
    switch (format) {
      case ExportFormat.pdf:
        return 'Best for printing or sending as a document.';
      case ExportFormat.markdown:
        return 'Ideal for README or GitHub pages.';
      case ExportFormat.html:
        return 'Responsive single-page website output.';
      case ExportFormat.json:
        return 'Machine-readable data export with metadata.';
    }
  }
}

class _ShareOption extends StatelessWidget {
  const _ShareOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Future<void> Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap == null ? null : () => onTap!.call(),
    );
  }
}

class _ExportProgress extends StatelessWidget {
  const _ExportProgress();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: 12),
        Text('Working on your export...'),
      ],
    );
  }
}
