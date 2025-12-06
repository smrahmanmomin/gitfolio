import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../data/models/github_user_model.dart';
import '../../../../data/models/repository_model.dart';
import 'contribution_heatmap.dart';
import 'language_distribution_chart.dart';
import 'repository_metrics.dart';
import 'skill_growth_timeline.dart';

class PortfolioAnalyticsSection extends StatelessWidget {
  const PortfolioAnalyticsSection({
    super.key,
    required this.user,
    required this.repos,
    this.title,
    this.description,
  });

  final GithubUserModel user;
  final List<RepositoryModel> repos;
  final String? title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final contributions = _generateContributionDays(repos);
    final years = contributions.isEmpty
        ? <int>[DateTime.now().year]
        : (contributions.map((day) => day.date.year).toSet().toList()..sort());
    final languageWeights = _languageDistributionFromRepos(repos);
    final metricsData = _buildRepositoryMetricsData(repos);
    final skillSeries = _buildSkillGrowthSeries(repos);
    final benchmarkSeries = _buildBenchmarkSeries(skillSeries);
    final markers = _buildSkillMarkers(repos);

    final heading = title ?? 'GitHub analytics';
    final subtitle = description ??
        'Visualize how ${user.name ?? user.login} shows up on GitHub across contributions, languages, and repository momentum.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(heading, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        ContributionHeatmap(
          days: contributions,
          availableYears: years,
          initialYear: years.isEmpty ? null : years.last,
        ),
        const SizedBox(height: 24),
        LanguageDistributionChart(languageWeights: languageWeights),
        const SizedBox(height: 24),
        RepositoryMetrics(data: metricsData),
        const SizedBox(height: 24),
        SkillGrowthTimeline(
          primarySeries: skillSeries,
          benchmarkSeries: benchmarkSeries,
          markers: markers,
        ),
      ],
    );
  }
}

List<ContributionDayData> _generateContributionDays(
  List<RepositoryModel> repos,
) {
  if (repos.isEmpty) {
    return const <ContributionDayData>[];
  }
  final now = DateTime.now();
  final start = DateTime(now.year - 1, now.month, now.day);
  final totalDays = now.difference(start).inDays;
  final contributions = <DateTime, int>{};
  for (final repo in repos) {
    final normalized =
        DateTime(repo.updatedAt.year, repo.updatedAt.month, repo.updatedAt.day);
    contributions[normalized] =
        (contributions[normalized] ?? 0) + 1 + repo.stargazersCount ~/ 75;
  }
  final days = <ContributionDayData>[];
  for (var i = 0; i <= totalDays; i++) {
    final date = DateTime(start.year, start.month, start.day + i);
    final normalized = DateTime(date.year, date.month, date.day);
    days.add(
      ContributionDayData(
        date: normalized,
        count: contributions[normalized] ?? 0,
      ),
    );
  }
  return days;
}

Map<String, double> _languageDistributionFromRepos(
  List<RepositoryModel> repos,
) {
  if (repos.isEmpty) return const <String, double>{};
  final totals = <String, double>{};
  for (final repo in repos) {
    final language =
        repo.language?.trim().isEmpty ?? true ? 'Other' : repo.language!.trim();
    totals[language] = (totals[language] ?? 0) + repo.stargazersCount + 1;
  }
  final total = totals.values.fold<double>(0, (sum, value) => sum + value);
  if (total == 0) {
    return totals;
  }
  return totals.map((key, value) => MapEntry(key, value / total));
}

RepositoryMetricsData _buildRepositoryMetricsData(
  List<RepositoryModel> repos,
) {
  final totalStars =
      repos.fold<int>(0, (sum, repo) => sum + repo.stargazersCount);
  final totalForks = repos.fold<int>(0, (sum, repo) => sum + repo.forksCount);
  final totalContributors = repos.fold<int>(
    0,
    (sum, repo) => sum + math.max(1, (repo.watchersCount ~/ 4) + 1),
  );
  final starTrend = _buildMonthlyTrend(
    repos,
    (repo) => repo.stargazersCount.toDouble(),
  );
  final forkTrend = _buildMonthlyTrend(
    repos,
    (repo) => repo.forksCount.toDouble(),
  );
  final contributorTrend = _buildMonthlyTrend(
    repos,
    (repo) => math.max(1, repo.watchersCount / 5),
  );
  final topRepo = repos.isEmpty ? null : _topRepositoriesByStars(repos).first;

  return RepositoryMetricsData(
    totalStars: totalStars,
    totalForks: totalForks,
    totalContributors: totalContributors,
    starTrend: starTrend,
    forkTrend: forkTrend,
    contributorTrend: contributorTrend,
    topRepository: topRepo == null
        ? null
        : RepositoryHighlight(
            name: topRepo.name,
            description: topRepo.description ?? 'Open source initiative',
            stars: topRepo.stargazersCount,
            language: topRepo.language ?? 'Unknown',
          ),
  );
}

List<double> _buildMonthlyTrend(
  List<RepositoryModel> repos,
  double Function(RepositoryModel repo) extractor,
) {
  final buckets = List<double>.filled(12, 0);
  if (repos.isEmpty) {
    for (var i = 0; i < buckets.length; i++) {
      buckets[i] = (i + 1).toDouble();
    }
    return buckets;
  }
  final now = DateTime.now();
  for (final repo in repos) {
    final diffMonths = (now.year - repo.updatedAt.year) * 12 +
        (now.month - repo.updatedAt.month);
    if (diffMonths < 0 || diffMonths > 11) continue;
    final bucketIndex = 11 - diffMonths;
    buckets[bucketIndex] += extractor(repo);
  }
  if (buckets.every((value) => value == 0)) {
    for (var i = 0; i < buckets.length; i++) {
      buckets[i] = (i + 1).toDouble();
    }
  }
  return buckets;
}

List<SkillGrowthPoint> _buildSkillGrowthSeries(List<RepositoryModel> repos) {
  final now = DateTime.now();
  final points = <SkillGrowthPoint>[];
  for (var i = 11; i >= 0; i--) {
    final monthDate = DateTime(now.year, now.month - i, 1);
    final monthlyRepos = repos
        .where(
          (repo) =>
              repo.updatedAt.year == monthDate.year &&
              repo.updatedAt.month == monthDate.month,
        )
        .toList();
    final momentum = monthlyRepos.fold<double>(
      0,
      (sum, repo) =>
          sum +
          repo.stargazersCount / 75 +
          (repo.topics.isEmpty ? 0.2 : repo.topics.length * 0.05),
    );
    final normalized = monthlyRepos.isEmpty
        ? 0.2
        : (momentum / (monthlyRepos.length * 1.5)).clamp(0.0, 1.0);
    points.add(SkillGrowthPoint(date: monthDate, value: normalized));
  }
  return points;
}

List<SkillGrowthPoint> _buildBenchmarkSeries(List<SkillGrowthPoint> primary) {
  if (primary.isEmpty) {
    return const <SkillGrowthPoint>[];
  }
  return primary
      .map(
        (point) => SkillGrowthPoint(
          date: point.date,
          value: (point.value * 0.85).clamp(0.0, 1.0),
        ),
      )
      .toList();
}

List<SkillTimelineMarker> _buildSkillMarkers(List<RepositoryModel> repos) {
  final topRepos = _topRepositoriesByStars(repos, limit: 3);
  return topRepos
      .map(
        (repo) => SkillTimelineMarker(
          date: repo.createdAt,
          label: repo.name,
        ),
      )
      .toList();
}

List<RepositoryModel> _topRepositoriesByStars(
  List<RepositoryModel> repos, {
  int limit = 5,
}) {
  final sorted = List<RepositoryModel>.from(repos);
  sorted.sort((a, b) => b.stargazersCount.compareTo(a.stargazersCount));
  return sorted.take(limit).toList();
}
