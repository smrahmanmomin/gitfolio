import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../../domain/entities/analytics.dart';
import '../../../core/constants/app_constants.dart';

/// Star history line chart widget
class StarHistoryChart extends StatelessWidget {
  final StarHistory starHistory;

  const StarHistoryChart({
    super.key,
    required this.starHistory,
  });

  @override
  Widget build(BuildContext context) {
    if (starHistory.dataPoints.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Center(
            child: Text(
              'No star history data available',
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Star History',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 20,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${starHistory.totalStars} total',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStat(
                  context,
                  'This month',
                  '+${starHistory.starsThisMonth}',
                  Colors.green,
                ),
                const SizedBox(width: 24),
                _buildStat(
                  context,
                  'This year',
                  '+${starHistory.starsThisYear}',
                  Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: AppConstants.largePadding),
            // Chart
            SizedBox(
              height: 200,
              child: CustomPaint(
                painter: _StarHistoryPainter(
                  dataPoints: starHistory.dataPoints,
                  color: Theme.of(context).colorScheme.primary,
                  gridColor:
                      Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
                child: Container(),
              ),
            ),
            const SizedBox(height: 8),
            // Time axis labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _buildTimeLabels(starHistory.dataPoints),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(
      BuildContext context, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
        ),
      ],
    );
  }

  List<Widget> _buildTimeLabels(List<StarDataPoint> dataPoints) {
    if (dataPoints.isEmpty) return [];

    final dateFormat = DateFormat('MMM yyyy');
    final points = [
      dataPoints.first,
      if (dataPoints.length > 2) dataPoints[dataPoints.length ~/ 2],
      dataPoints.last,
    ];

    return points
        .map((p) => Text(
              dateFormat.format(p.date),
              style: const TextStyle(fontSize: 11),
            ))
        .toList();
  }
}

class _StarHistoryPainter extends CustomPainter {
  final List<StarDataPoint> dataPoints;
  final Color color;
  final Color gridColor;

  _StarHistoryPainter({
    required this.dataPoints,
    required this.color,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    // Draw grid lines
    _drawGrid(canvas, size);

    // Calculate scaling
    final maxStars = dataPoints.map((p) => p.stars).reduce(math.max);
    final minStars = dataPoints.map((p) => p.stars).reduce(math.min);
    final starRange = maxStars - minStars;

    if (starRange == 0) return;

    // Draw area under the line
    final areaPath = Path();
    final linePath = Path();

    for (int i = 0; i < dataPoints.length; i++) {
      final x = (i / (dataPoints.length - 1)) * size.width;
      final normalizedValue = (dataPoints[i].stars - minStars) / starRange;
      final y = size.height - (normalizedValue * size.height);

      if (i == 0) {
        areaPath.moveTo(x, size.height);
        areaPath.lineTo(x, y);
        linePath.moveTo(x, y);
      } else {
        areaPath.lineTo(x, y);
        linePath.lineTo(x, y);
      }
    }

    areaPath.lineTo(size.width, size.height);
    areaPath.close();

    // Draw gradient area
    final gradient = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.3),
          color.withOpacity(0.05),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(areaPath, gradient);

    // Draw line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, linePaint);

    // Draw points
    for (int i = 0; i < dataPoints.length; i++) {
      final x = (i / (dataPoints.length - 1)) * size.width;
      final normalizedValue = (dataPoints[i].stars - minStars) / starRange;
      final y = size.height - (normalizedValue * size.height);

      final pointPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), 3, pointPaint);

      // Draw white border
      final borderPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(Offset(x, y), 3, borderPaint);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    // Horizontal grid lines
    for (int i = 0; i <= 4; i++) {
      final y = (i / 4) * size.height;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // Vertical grid lines
    for (int i = 0; i <= 6; i++) {
      final x = (i / 6) * size.width;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarHistoryPainter oldDelegate) =>
      oldDelegate.dataPoints != dataPoints ||
      oldDelegate.color != color ||
      oldDelegate.gridColor != gridColor;
}
