import 'package:equatable/equatable.dart';

/// Enhanced contribution data matching GitHub's format
class ContributionDay extends Equatable {
  final DateTime date;
  final int count;
  final ContributionLevel level;

  const ContributionDay({
    required this.date,
    required this.count,
    required this.level,
  });

  @override
  List<Object?> get props => [date, count, level];
}

/// Contribution intensity levels matching GitHub
enum ContributionLevel {
  none, // 0 contributions
  low, // 1-3 contributions
  medium, // 4-6 contributions
  high, // 7-9 contributions
  veryHigh // 10+ contributions
}

/// Weekly contribution data
class ContributionWeek {
  final List<ContributionDay> days;

  const ContributionWeek({required this.days});

  int get total => days.fold(0, (sum, day) => sum + day.count);
}

/// Yearly contribution summary
class ContributionYear {
  final int year;
  final List<ContributionWeek> weeks;
  final int totalContributions;
  final Map<String, int> contributionsByType;

  const ContributionYear({
    required this.year,
    required this.weeks,
    required this.totalContributions,
    required this.contributionsByType,
  });

  /// Get contribution level for a specific date
  static ContributionLevel getLevel(int count) {
    if (count == 0) return ContributionLevel.none;
    if (count <= 3) return ContributionLevel.low;
    if (count <= 6) return ContributionLevel.medium;
    if (count <= 9) return ContributionLevel.high;
    return ContributionLevel.veryHigh;
  }

  /// Get all days in chronological order
  List<ContributionDay> get allDays =>
      weeks.expand((week) => week.days).toList();

  /// Get longest streak
  int get longestStreak {
    int current = 0;
    int max = 0;
    for (final day in allDays) {
      if (day.count > 0) {
        current++;
        if (current > max) max = current;
      } else {
        current = 0;
      }
    }
    return max;
  }

  /// Get current streak
  int get currentStreak {
    int streak = 0;
    final reversed = allDays.reversed.toList();
    for (final day in reversed) {
      if (day.count > 0) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// Get busiest day
  ContributionDay? get busiestDay {
    if (allDays.isEmpty) return null;
    return allDays.reduce(
      (a, b) => a.count > b.count ? a : b,
    );
  }
}
