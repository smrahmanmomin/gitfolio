import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/contribution.dart';
import '../../../core/constants/app_constants.dart';

/// Enhanced GitHub-style contribution heatmap
class EnhancedContributionHeatmap extends StatefulWidget {
  final ContributionYear contributionData;
  final Function(int year)? onYearChanged;

  const EnhancedContributionHeatmap({
    super.key,
    required this.contributionData,
    this.onYearChanged,
  });

  @override
  State<EnhancedContributionHeatmap> createState() =>
      _EnhancedContributionHeatmapState();
}

class _EnhancedContributionHeatmapState
    extends State<EnhancedContributionHeatmap> {
  ContributionDay? _hoveredDay;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with year navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${widget.contributionData.totalContributions} contributions in ${widget.contributionData.year}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (widget.onYearChanged != null)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => widget.onYearChanged!(
                          widget.contributionData.year - 1,
                        ),
                        tooltip: 'Previous year',
                      ),
                      Text(
                        widget.contributionData.year.toString(),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => widget.onYearChanged!(
                          widget.contributionData.year + 1,
                        ),
                        tooltip: 'Next year',
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),

            // Stats summary
            Wrap(
              spacing: 24,
              runSpacing: 8,
              children: [
                _buildStat(
                  'Current streak',
                  '${widget.contributionData.currentStreak} days',
                  Icons.local_fire_department,
                  Colors.orange,
                ),
                _buildStat(
                  'Longest streak',
                  '${widget.contributionData.longestStreak} days',
                  Icons.whatshot,
                  Colors.red,
                ),
                if (widget.contributionData.busiestDay != null)
                  _buildStat(
                    'Busiest day',
                    '${widget.contributionData.busiestDay!.count} contributions',
                    Icons.trending_up,
                    Colors.green,
                  ),
              ],
            ),
            const SizedBox(height: AppConstants.largePadding),

            // Contribution grid
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month labels
                  _buildMonthLabels(),
                  const SizedBox(height: 4),

                  // Contribution squares with day labels
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Day of week labels
                      _buildDayLabels(),
                      const SizedBox(width: 8),

                      // Contribution grid
                      _buildContributionGrid(isDark, colorScheme),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.defaultPadding),

            // Legend and hover info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLegend(isDark, colorScheme),
                if (_hoveredDay != null) _buildHoverInfo(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          '$value ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
        ),
      ],
    );
  }

  Widget _buildMonthLabels() {
    final months = <Widget>[];
    DateTime currentDate = DateTime(widget.contributionData.year, 1, 1);

    for (int i = 0; i < 12; i++) {
      months.add(
        SizedBox(
          width: 52, // Approximate width for 4-5 weeks
          child: Text(
            DateFormat('MMM').format(currentDate),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
      currentDate = DateTime(currentDate.year, currentDate.month + 1, 1);
    }

    return Row(
      children: [
        const SizedBox(width: 32), // Space for day labels
        ...months,
      ],
    );
  }

  Widget _buildDayLabels() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildDayLabel('Mon', 0),
        const SizedBox(height: 14),
        _buildDayLabel('Wed', 1),
        const SizedBox(height: 14),
        _buildDayLabel('Fri', 2),
      ],
    );
  }

  Widget _buildDayLabel(String label, int offset) {
    return SizedBox(
      height: 11,
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  Widget _buildContributionGrid(bool isDark, ColorScheme colorScheme) {
    return Column(
      children: List.generate(
        7, // Days of week
        (dayIndex) => Row(
          children: widget.contributionData.weeks.map((week) {
            if (dayIndex >= week.days.length) {
              return const SizedBox(width: 11, height: 11);
            }
            final day = week.days[dayIndex];
            return Padding(
              padding: const EdgeInsets.all(1.5),
              child: MouseRegion(
                onEnter: (_) => setState(() => _hoveredDay = day),
                onExit: (_) => setState(() => _hoveredDay = null),
                child: Tooltip(
                  message:
                      '${day.count} contributions on ${DateFormat('MMM d, y').format(day.date)}',
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color:
                          _getContributionColor(day.level, isDark, colorScheme),
                      borderRadius: BorderRadius.circular(2),
                      border: _hoveredDay == day
                          ? Border.all(
                              color: colorScheme.primary,
                              width: 1.5,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getContributionColor(
    ContributionLevel level,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    if (isDark) {
      switch (level) {
        case ContributionLevel.none:
          return const Color(0xFF161B22);
        case ContributionLevel.low:
          return const Color(0xFF0E4429);
        case ContributionLevel.medium:
          return const Color(0xFF006D32);
        case ContributionLevel.high:
          return const Color(0xFF26A641);
        case ContributionLevel.veryHigh:
          return const Color(0xFF39D353);
      }
    } else {
      switch (level) {
        case ContributionLevel.none:
          return const Color(0xFFEBEDF0);
        case ContributionLevel.low:
          return const Color(0xFF9BE9A8);
        case ContributionLevel.medium:
          return const Color(0xFF40C463);
        case ContributionLevel.high:
          return const Color(0xFF30A14E);
        case ContributionLevel.veryHigh:
          return const Color(0xFF216E39);
      }
    }
  }

  Widget _buildLegend(bool isDark, ColorScheme colorScheme) {
    return Row(
      children: [
        Text(
          'Less',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(width: 4),
        ...ContributionLevel.values.map(
          (level) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: _getContributionColor(level, isDark, colorScheme),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          'More',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildHoverInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${_hoveredDay!.count} contributions on ${DateFormat('MMM d, y').format(_hoveredDay!.date)}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
      ),
    );
  }
}
