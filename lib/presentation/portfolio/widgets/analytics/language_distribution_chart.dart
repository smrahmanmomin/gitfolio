import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Interactive pie chart summarizing language distribution.
class LanguageDistributionChart extends StatefulWidget {
  const LanguageDistributionChart({
    super.key,
    required this.languageWeights,
    this.onLanguageSelected,
  });

  final Map<String, double> languageWeights;
  final ValueChanged<String?>? onLanguageSelected;

  @override
  State<LanguageDistributionChart> createState() =>
      _LanguageDistributionChartState();
}

class _LanguageDistributionChartState extends State<LanguageDistributionChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.languageWeights.isEmpty) {
      return Text(
        'Add repositories with languages to see this chart.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    final entries = widget.languageWeights.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final colors = _generatePalette(entries.length);
    final total = entries.fold<double>(0, (sum, entry) => sum + entry.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 260,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              startDegreeOffset: -90,
              centerSpaceRadius: 62,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  if (!event.isInterestedForInteractions ||
                      response == null ||
                      response.touchedSection == null) {
                    _updateTouch(null);
                    widget.onLanguageSelected?.call(null);
                    return;
                  }
                  final touchedIndex =
                      response.touchedSection!.touchedSectionIndex;
                  _updateTouch(
                    touchedIndex == _touchedIndex ? null : touchedIndex,
                  );
                  if (touchedIndex < entries.length) {
                    widget.onLanguageSelected?.call(
                      entries[touchedIndex].key,
                    );
                  }
                },
              ),
              sections: [
                for (var i = 0; i < entries.length; i++)
                  PieChartSectionData(
                    value: entries[i].value,
                    radius: i == _touchedIndex ? 90 : 72,
                    color: colors[i],
                    title: '${((entries[i].value / total) * 100).round()}%',
                    titleStyle:
                        Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            for (var i = 0; i < entries.length; i++)
              _LegendEntry(
                color: colors[i],
                label: entries[i].key,
                percentage: entries[i].value / total,
                isSelected: i == _touchedIndex,
              ),
          ],
        ),
      ],
    );
  }

  void _updateTouch(int? index) {
    setState(() {
      _touchedIndex = index;
    });
  }

  List<Color> _generatePalette(int count) {
    if (count <= Colors.primaries.length) {
      return Colors.primaries.take(count).toList();
    }
    final random = math.Random(42);
    return List<Color>.generate(
      count,
      (_) => Color.fromARGB(
        255,
        80 + random.nextInt(150),
        80 + random.nextInt(150),
        80 + random.nextInt(150),
      ),
    );
  }
}

class _LegendEntry extends StatelessWidget {
  const _LegendEntry({
    required this.color,
    required this.label,
    required this.percentage,
    required this.isSelected,
  });

  final Color color;
  final String label;
  final double percentage;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? color.withValues(alpha: 0.12)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text('$label ${(percentage * 100).toStringAsFixed(1)}%'),
        ],
      ),
    );
  }
}
