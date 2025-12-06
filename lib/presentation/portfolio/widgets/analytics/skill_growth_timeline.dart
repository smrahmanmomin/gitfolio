import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SkillGrowthPoint {
  const SkillGrowthPoint({required this.date, required this.value});

  final DateTime date;
  final double value;
}

class SkillTimelineMarker {
  const SkillTimelineMarker({
    required this.date,
    required this.label,
    this.color,
  });

  final DateTime date;
  final String label;
  final Color? color;
}

class SkillGrowthTimeline extends StatelessWidget {
  const SkillGrowthTimeline({
    super.key,
    required this.primarySeries,
    required this.benchmarkSeries,
    this.markers = const <SkillTimelineMarker>[],
  });

  final List<SkillGrowthPoint> primarySeries;
  final List<SkillGrowthPoint> benchmarkSeries;
  final List<SkillTimelineMarker> markers;

  @override
  Widget build(BuildContext context) {
    if (primarySeries.isEmpty || benchmarkSeries.isEmpty) {
      return Text(
        'Skill data will appear once you curate repositories.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    final combined = [...primarySeries, ...benchmarkSeries];
    combined.sort((a, b) => a.date.compareTo(b.date));
    final minX = combined.first.date.millisecondsSinceEpoch.toDouble();
    final maxX = combined.last.date.millisecondsSinceEpoch.toDouble();

    LineChartBarData buildSeries(List<SkillGrowthPoint> points, Color color) {
      return LineChartBarData(
        spots: [
          for (final point in points)
            FlSpot(
              point.date.millisecondsSinceEpoch.toDouble(),
              point.value,
            ),
        ],
        isCurved: true,
        color: color,
        barWidth: 3,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: color.withValues(alpha: 0.15),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final chart = SizedBox(
          height: 260,
          child: LineChart(
            LineChartData(
              minX: minX,
              maxX: maxX,
              minY: 0,
              maxY: 1.2,
              gridData: FlGridData(
                drawHorizontalLine: true,
                horizontalInterval: 0.2,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Theme.of(context).dividerColor,
                  strokeWidth: 0.4,
                ),
                drawVerticalLine: false,
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    interval: 0.2,
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) =>
                        Text('${(value * 100).round()}%'),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    interval: ((maxX - minX) / 4).clamp(1, double.infinity),
                    showTitles: true,
                    reservedSize: 42,
                    getTitlesWidget: (value, meta) {
                      final date =
                          DateTime.fromMillisecondsSinceEpoch(value.toInt());
                      return Text('${date.month}/${date.year % 100}');
                    },
                  ),
                ),
                rightTitles: const AxisTitles(),
                topTitles: const AxisTitles(),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                buildSeries(
                    primarySeries, Theme.of(context).colorScheme.primary),
                buildSeries(benchmarkSeries,
                    Theme.of(context).colorScheme.outlineVariant),
              ],
            ),
          ),
        );

        final markerWidgets = <Widget>[];
        for (final marker in markers) {
          if (marker.date.millisecondsSinceEpoch < minX ||
              marker.date.millisecondsSinceEpoch > maxX) {
            continue;
          }
          final ratio = (marker.date.millisecondsSinceEpoch - minX) /
              (maxX - minX == 0 ? 1 : maxX - minX);
          final rawLeft = ratio * constraints.maxWidth;
          final clampedLeft = rawLeft
              .clamp(0.0, math.max(0.0, constraints.maxWidth - 120))
              .toDouble();
          markerWidgets.add(
            Positioned(
              left: clampedLeft,
              top: 0,
              child: Tooltip(
                message: marker.label,
                child: Column(
                  children: [
                    Icon(Icons.circle,
                        size: 12,
                        color: marker.color ??
                            Theme.of(context).colorScheme.secondary),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        marker.label,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SizedBox(
          height: 300,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: chart),
              ...markerWidgets,
            ],
          ),
        );
      },
    );
  }
}
