import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:visibility_detector/visibility_detector.dart';

class LazyProjectImage extends HookWidget {
  const LazyProjectImage({
    super.key,
    required this.imageUrl,
    required this.semanticLabel,
  });

  final String imageUrl;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final shouldLoad = useState(false);
    final highContrast = MediaQuery.highContrastOf(context);

    return Semantics(
      label: semanticLabel,
      child: VisibilityDetector(
        key: key ?? ValueKey(imageUrl),
        onVisibilityChanged: (info) {
          if (!shouldLoad.value && info.visibleFraction > 0.2) {
            shouldLoad.value = true;
          }
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: shouldLoad.value
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    height: 120,
                    width: double.infinity,
                    filterQuality: FilterQuality.medium,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      }
                      return _PlaceholderTile(highContrast: highContrast);
                    },
                    errorBuilder: (context, _, __) => _PlaceholderTile(
                      highContrast: highContrast,
                      label: 'Preview unavailable',
                    ),
                  ),
                )
              : _PlaceholderTile(highContrast: highContrast),
        ),
      ),
    );
  }
}

class _PlaceholderTile extends StatelessWidget {
  const _PlaceholderTile({this.highContrast = false, this.label});

  final bool highContrast;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: highContrast
            ? colorScheme.onSurface
            : colorScheme.surfaceVariant.withOpacity(0.4),
      ),
      alignment: Alignment.center,
      child: label == null
          ? const CircularProgressIndicator(strokeWidth: 1.5)
          : Text(
              label!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colorScheme.onSurface),
            ),
    );
  }
}
