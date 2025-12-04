import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

class SharePortfolioSheet extends StatelessWidget {
  const SharePortfolioSheet({
    super.key,
    required this.shareUrl,
    this.previewBytes,
    this.onSavePreview,
  });

  final String shareUrl;
  final Uint8List? previewBytes;
  final Future<void> Function()? onSavePreview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Share your portfolio', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Use the generated link, QR code, or preview asset to share '
              'your portfolio anywhere.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _ShareRow(
              label: 'Unique URL',
              value: shareUrl,
              onCopy: () async {
                await Clipboard.setData(ClipboardData(text: shareUrl));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied to clipboard.')),
                );
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: 'QR code for portfolio link',
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: QrImageView(
                        data: shareUrl,
                        size: 160,
                        gapless: true,
                        eyeStyle: QrEyeStyle(color: scheme.primary),
                        dataModuleStyle:
                            QrDataModuleStyle(color: scheme.onSurface),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: previewBytes == null
                      ? _PreviewPlaceholder(color: scheme)
                      : _PreviewImage(bytes: previewBytes!),
                ),
              ],
            ),
            if (onSavePreview != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  await onSavePreview!.call();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Preview saved for sharing.')),
                  );
                },
                icon: const Icon(Icons.download_outlined),
                label: const Text('Save social preview'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShareRow extends StatelessWidget {
  const _ShareRow({
    required this.label,
    required this.value,
    required this.onCopy,
  });

  final String label;
  final String value;
  final Future<void> Function() onCopy;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: 'Copy link',
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_all,
                      semanticLabel: 'Copy share link'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewPlaceholder extends StatelessWidget {
  const _PreviewPlaceholder({required this.color});

  final ColorScheme color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.surfaceContainerHigh,
      ),
      alignment: Alignment.center,
      child: Text(
        'Generate a preview to share on social media.',
        textAlign: TextAlign.center,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: color.onSurfaceVariant),
      ),
    );
  }
}

class _PreviewImage extends StatelessWidget {
  const _PreviewImage({required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.memory(
        bytes,
        height: 200,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        semanticLabel: 'Portfolio social media preview image',
      ),
    );
  }
}
