import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/themes/app_theme.dart';
import '../../../../data/models/github_user_model.dart';
import '../../../../data/models/repository_model.dart';
import '../../../../domain/portfolio/portfolio_entity.dart';
import '../analytics/portfolio_analytics_section.dart';
import '../lazy_project_image.dart';

class ModernDeveloperTemplate extends StatelessWidget {
  const ModernDeveloperTemplate({
    super.key,
    required this.user,
    required this.repos,
    required this.config,
  });

  final GithubUserModel user;
  final List<RepositoryModel> repos;
  final PortfolioConfig config;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;
        final gridColumns = isDesktop ? 2 : 1;
        final languages = _languageWeights(repos);
        final theme = Theme.of(context);

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 48 : 16,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeroCard(theme),
              const SizedBox(height: 24),
              if (_shouldShow(PortfolioSection.skills))
                _SkillsAndStatsRow(
                  languages: languages,
                  theme: theme,
                ),
              if (_shouldShow(PortfolioSection.skills))
                const SizedBox(height: 24),
              if (_shouldShow(PortfolioSection.projects))
                _ProjectsGrid(
                  repos: repos,
                  columns: gridColumns,
                ),
              if (config.analyticsEnabled) const SizedBox(height: 24),
              if (config.analyticsEnabled) _buildAnalyticsCard(theme),
              if (_shouldShow(PortfolioSection.contact))
                const SizedBox(height: 24),
              if (_shouldShow(PortfolioSection.contact))
                _buildContactCard(theme),
            ],
          ),
        );
      },
    );
  }

  bool _shouldShow(PortfolioSection section) =>
      config.sections.contains(section);

  Widget _buildHeroCard(ThemeData theme) {
    return Card(
      elevation: 6,
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundImage: NetworkImage(user.avatarUrl),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name ?? user.login,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.bio ?? 'GitHub developer',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _StatChip(label: 'Followers', value: user.followers),
                      _StatChip(label: 'Following', value: user.following),
                      _StatChip(label: 'Repositories', value: user.publicRepos),
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

  Widget _buildContactCard(ThemeData theme) {
    final items = [
      if (user.email != null)
        _ContactItem(icon: Icons.email_outlined, label: user.email!),
      if (user.location != null)
        _ContactItem(icon: Icons.location_on_outlined, label: user.location!),
      if (user.blog != null && user.blog!.isNotEmpty)
        _ContactItem(icon: Icons.link, label: user.blog!),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(ThemeData theme) {
    return Card(
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: PortfolioAnalyticsSection(
          user: user,
          repos: repos,
          title: 'GitHub insights',
        ),
      ),
    );
  }
}

class _SkillsAndStatsRow extends StatelessWidget {
  const _SkillsAndStatsRow({required this.languages, required this.theme});

  final Map<String, double> languages;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    if (languages.isEmpty) {
      return Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No language data available yet.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    return Card(
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Skill radar',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            AspectRatio(
              aspectRatio: 1.6,
              child: RadarChart(
                RadarChartData(
                  dataSets: [
                    RadarDataSet(
                      dataEntries: languages.values
                          .map((value) => RadarEntry(value: value))
                          .toList(),
                      borderColor: theme.colorScheme.primary,
                      fillColor: theme.colorScheme.primary.withOpacity(0.15),
                      entryRadius: 3,
                      borderWidth: 3,
                    ),
                  ],
                  radarTouchData: RadarTouchData(enabled: false),
                  radarBackgroundColor: theme.colorScheme.surface,
                  radarBorderData: const BorderSide(color: Color(0xFFD0D7DE)),
                  titleTextStyle: theme.textTheme.labelMedium,
                  getTitle: (index, angle) {
                    final labels = languages.keys.toList();
                    return RadarChartTitle(text: labels[index]);
                  },
                  gridBorderData: BorderSide(
                    color: theme.brightness == Brightness.dark
                        ? AppTheme.gitHubPurple.withOpacity(0.4)
                        : AppTheme.gitHubOrange.withOpacity(0.4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectsGrid extends StatelessWidget {
  const _ProjectsGrid({required this.repos, required this.columns});

  final List<RepositoryModel> repos;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final featured = repos.take(4).toList();
    if (featured.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Highlighted Projects', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: columns > 1 ? 1.6 : 1.9,
              ),
              itemCount: featured.length,
              itemBuilder: (context, index) {
                final repo = featured[index];
                return Card(
                  elevation: 3,
                  color: theme.colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LazyProjectImage(
                          imageUrl: _previewImage(repo),
                          semanticLabel: '${repo.name} social preview',
                        ),
                        const SizedBox(height: 12),
                        Text(
                          repo.name,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Text(
                            repo.description ?? 'No description provided.',
                            style: theme.textTheme.bodyMedium,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.star_border,
                                size: 18, color: theme.colorScheme.secondary),
                            const SizedBox(width: 4),
                            Text(repo.stargazersCount.toString()),
                            const SizedBox(width: 12),
                            Icon(Icons.call_split,
                                size: 18, color: theme.colorScheme.secondary),
                            const SizedBox(width: 4),
                            Text(repo.forksCount.toString()),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

String _previewImage(RepositoryModel repo) {
  final slug = repo.fullName.isNotEmpty
      ? repo.fullName
      : '${repo.ownerLogin ?? 'user'}/${repo.name}';
  return 'https://opengraph.githubassets.com/preview/$slug';
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      backgroundColor: theme.colorScheme.surface,
      side: BorderSide(color: theme.colorScheme.secondary.withOpacity(0.3)),
      avatar: CircleAvatar(
        backgroundColor: theme.colorScheme.primary.withOpacity(.15),
        child: Text(
          value.toString(),
          style: theme.textTheme.labelSmall,
        ),
      ),
      label: Text(label),
    );
  }
}

class _ContactItem extends StatelessWidget {
  const _ContactItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

Map<String, double> _languageWeights(List<RepositoryModel> repos) {
  final counts = <String, double>{};
  for (final repo in repos) {
    final language = repo.language ?? 'Other';
    counts.update(language, (value) => value + 1, ifAbsent: () => 1);
  }
  if (counts.isEmpty) return counts;
  final max = counts.values.reduce((a, b) => a > b ? a : b);
  return counts.map((key, value) => MapEntry(key, (value / max) * 5));
}
