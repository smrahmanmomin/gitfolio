import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// Basic contribution heatmap visualization.
///
/// Displays a simplified GitHub-style contribution calendar.
class ContributionHeatmap extends StatelessWidget {
  final Map<String, dynamic>? contributionData;

  const ContributionHeatmap({super.key, this.contributionData});

  @override
  Widget build(BuildContext context) {
    if (contributionData == null) {
      return const Center(child: Text('No contribution data available'));
    }

    // Extract contribution data
    final userData = contributionData!['user'] as Map<String, dynamic>?;
    if (userData == null) {
      return const Center(child: Text('Invalid contribution data'));
    }

    final contributionsCollection =
        userData['contributionsCollection'] as Map<String, dynamic>?;
    if (contributionsCollection == null) {
      return const Center(child: Text('No contributions found'));
    }

    final calendar = contributionsCollection['contributionCalendar']
        as Map<String, dynamic>?;
    if (calendar == null) {
      return const Center(child: Text('No calendar data'));
    }

    final totalContributions = calendar['totalContributions'] as int? ?? 0;
    final weeks = calendar['weeks'] as List<dynamic>? ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contributions',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              '$totalContributions contributions in the last year',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppConstants.defaultPadding),

            // Contribution grid
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: weeks.map<Widget>((week) {
                  final days =
                      (week['contributionDays'] as List<dynamic>?) ?? [];
                  return Column(
                    children: days.map<Widget>((day) {
                      final count = day['contributionCount'] as int? ?? 0;
                      return Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.all(1.5),
                        decoration: BoxDecoration(
                          color: _getContributionColor(context, count),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),

            // Legend
            Row(
              children: [
                Text('Less', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 8),
                ...List.generate(5, (index) {
                  return Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: _getContributionColor(context, index * 5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
                const SizedBox(width: 8),
                Text('More', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getContributionColor(BuildContext context, int count) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = Theme.of(context).colorScheme.primary;

    if (count == 0) {
      return isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    } else if (count < 5) {
      return baseColor.withOpacity(0.3);
    } else if (count < 10) {
      return baseColor.withOpacity(0.5);
    } else if (count < 15) {
      return baseColor.withOpacity(0.7);
    } else {
      return baseColor;
    }
  }
}
