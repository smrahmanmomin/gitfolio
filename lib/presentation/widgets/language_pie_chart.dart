import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../domain/entities/analytics.dart';
import '../../../core/constants/app_constants.dart';

/// Language distribution pie chart widget
class LanguagePieChart extends StatelessWidget {
  final LanguageStats stats;
  final int maxLanguages;

  const LanguagePieChart({
    super.key,
    required this.stats,
    this.maxLanguages = 6,
  });

  @override
  Widget build(BuildContext context) {
    final topLanguages = stats.getTopLanguages(maxLanguages);
    if (topLanguages.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Center(
            child: Text(
              'No language data available',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Language Distribution',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Row(
              children: [
                // Pie chart
                Expanded(
                  flex: 2,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: CustomPaint(
                      painter: _PieChartPainter(
                        languages: topLanguages,
                        colors: _getLanguageColors(topLanguages.length),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.defaultPadding),
                // Legend
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: topLanguages.asMap().entries.map((entry) {
                      final index = entry.key;
                      final lang = entry.value;
                      final color =
                          _getLanguageColors(topLanguages.length)[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                lang.key,
                                style: Theme.of(context).textTheme.bodyMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${lang.value.toStringAsFixed(1)}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getLanguageColors(int count) {
    return [
      const Color(0xFF3178C6), // TypeScript blue
      const Color(0xFFF1E05A), // JavaScript yellow
      const Color(0xFFE44D26), // HTML orange
      const Color(0xFF563D7C), // CSS purple
      const Color(0xFF178600), // C# green
      const Color(0xFFB07219), // Java brown
      const Color(0xFFFFD700), // Kotlin gold
      const Color(0xFF000080), // Swift navy
    ].take(count).toList();
  }
}

class _PieChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> languages;
  final List<Color> colors;

  _PieChartPainter({
    required this.languages,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    double startAngle = -math.pi / 2; // Start from top

    for (int i = 0; i < languages.length; i++) {
      final percentage = languages[i].value;
      final sweepAngle = (percentage / 100) * 2 * math.pi;

      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Draw border between segments
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(_PieChartPainter oldDelegate) =>
      oldDelegate.languages != languages || oldDelegate.colors != colors;
}
