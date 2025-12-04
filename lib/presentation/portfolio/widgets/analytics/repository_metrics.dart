import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class RepositoryMetricsData {
  const RepositoryMetricsData({
    required this.totalStars,
    required this.totalForks,
    required this.totalContributors,
    required this.starTrend,
    required this.forkTrend,
    required this.contributorTrend,
    this.topRepository,
  });

  final int totalStars;
  final int totalForks;
  final int totalContributors;
  final List<double> starTrend;
  final List<double> forkTrend;
  final List<double> contributorTrend;
  final RepositoryHighlight? topRepository;
}

class RepositoryHighlight {
  const RepositoryHighlight({
    required this.name,
    required this.description,
    required this.stars,
    required this.language,
  });

  final String name;
  final String description;
  final int stars;
  final String language;
}

class RepositoryMetrics extends StatelessWidget {
  const RepositoryMetrics({super.key, required this.data});

  final RepositoryMetricsData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _MetricCard(
              title: 'Total stars',
              value: data.totalStars,
              values: data.starTrend,
              color: Theme.of(context).colorScheme.primary,
            ),
            _MetricCard(
              title: 'Forks',
              value: data.totalForks,
              values: data.forkTrend,
              color: Theme.of(context).colorScheme.tertiary,
            ),
            _MetricCard(
              title: 'Contributors',
              value: data.totalContributors,
              values: data.contributorTrend,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ],
        ),
        if (data.topRepository != null) ...[
          const SizedBox(height: 24),
          _PopularRepositoryCard(highlight: data.topRepository!),
        ],
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.values,
    required this.color,
  });

  final String title;
  final int value;
  final List<double> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title.toUpperCase(),
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(letterSpacing: 1.1)),
              const SizedBox(height: 8),
              Text(
                value.toString(),
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 64,
                child: _Sparkline(values: values, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PopularRepositoryCard extends StatelessWidget {
  const _PopularRepositoryCard({required this.highlight});

  final RepositoryHighlight highlight;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.trending_up,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    highlight.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(highlight.description,
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.star, size: 16),
                        label: Text('${highlight.stars} stars'),
                      ),
                      Chip(
                        avatar: const Icon(Icons.code, size: 16),
                        label: Text(highlight.language),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const SizedBox.shrink();
    }
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final normalized = maxValue - minValue == 0
        ? values.map((value) => 0.5).toList()
        : values
            .map((value) => (value - minValue) / (maxValue - minValue))
            .toList();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: normalized.length.toDouble() - 1,
        minY: 0,
        maxY: 1,
        lineTouchData: const LineTouchData(enabled: false),
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < normalized.length; i++)
                FlSpot(i.toDouble(), normalized[i]),
            ],
            isCurved: true,
            color: color,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}
