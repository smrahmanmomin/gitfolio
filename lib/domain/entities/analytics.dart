import 'package:equatable/equatable.dart';

/// Analytics data for the portfolio
class PortfolioAnalytics extends Equatable {
  final LanguageStats languageStats;
  final StarHistory starHistory;
  final RepositoryStats repositoryStats;
  final ActivityMetrics activityMetrics;

  const PortfolioAnalytics({
    required this.languageStats,
    required this.starHistory,
    required this.repositoryStats,
    required this.activityMetrics,
  });

  @override
  List<Object?> get props => [
        languageStats,
        starHistory,
        repositoryStats,
        activityMetrics,
      ];
}

/// Language usage statistics
class LanguageStats extends Equatable {
  final Map<String, int> bytesByLanguage;
  final int totalBytes;

  const LanguageStats({
    required this.bytesByLanguage,
    required this.totalBytes,
  });

  /// Get percentage for each language
  Map<String, double> get percentages {
    if (totalBytes == 0) return {};
    return bytesByLanguage.map(
      (lang, bytes) => MapEntry(lang, (bytes / totalBytes) * 100),
    );
  }

  /// Get top N languages
  List<MapEntry<String, double>> getTopLanguages(int count) {
    final sorted = percentages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(count).toList();
  }

  @override
  List<Object?> get props => [bytesByLanguage, totalBytes];
}

/// Star history data point
class StarDataPoint extends Equatable {
  final DateTime date;
  final int stars;

  const StarDataPoint({
    required this.date,
    required this.stars,
  });

  @override
  List<Object?> get props => [date, stars];
}

/// Star history over time
class StarHistory extends Equatable {
  final List<StarDataPoint> dataPoints;
  final int totalStars;
  final int starsThisMonth;
  final int starsThisYear;

  const StarHistory({
    required this.dataPoints,
    required this.totalStars,
    required this.starsThisMonth,
    required this.starsThisYear,
  });

  @override
  List<Object?> get props => [
        dataPoints,
        totalStars,
        starsThisMonth,
        starsThisYear,
      ];
}

/// Repository statistics
class RepositoryStats extends Equatable {
  final int totalRepos;
  final int publicRepos;
  final int privateRepos;
  final int forkedRepos;
  final int originalRepos;
  final Map<String, int> reposByLanguage;

  const RepositoryStats({
    required this.totalRepos,
    required this.publicRepos,
    required this.privateRepos,
    required this.forkedRepos,
    required this.originalRepos,
    required this.reposByLanguage,
  });

  @override
  List<Object?> get props => [
        totalRepos,
        publicRepos,
        privateRepos,
        forkedRepos,
        originalRepos,
        reposByLanguage,
      ];
}

/// Activity metrics
class ActivityMetrics extends Equatable {
  final int totalCommits;
  final int totalPullRequests;
  final int totalIssues;
  final int totalReviews;
  final double averageCommitsPerDay;
  final int activeDays;
  final int currentStreak;
  final int longestStreak;

  const ActivityMetrics({
    required this.totalCommits,
    required this.totalPullRequests,
    required this.totalIssues,
    required this.totalReviews,
    required this.averageCommitsPerDay,
    required this.activeDays,
    required this.currentStreak,
    required this.longestStreak,
  });

  @override
  List<Object?> get props => [
        totalCommits,
        totalPullRequests,
        totalIssues,
        totalReviews,
        averageCommitsPerDay,
        activeDays,
        currentStreak,
        longestStreak,
      ];
}
