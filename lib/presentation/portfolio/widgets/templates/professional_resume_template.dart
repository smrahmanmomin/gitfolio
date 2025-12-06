import 'package:flutter/material.dart';

import '../../../../core/themes/app_theme.dart';
import '../../../../data/models/github_user_model.dart';
import '../../../../data/models/repository_model.dart';
import '../../../../domain/portfolio/portfolio_entity.dart';
import '../analytics/portfolio_analytics_section.dart';
import '../lazy_project_image.dart';

class ProfessionalResumeTemplate extends StatelessWidget {
  const ProfessionalResumeTemplate({
    super.key,
    required this.user,
    required this.repos,
    required this.config,
  });

  final GithubUserModel user;
  final List<RepositoryModel> repos;
  final PortfolioConfig config;

  bool _show(PortfolioSection section) => config.sections.contains(section);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dividerColor = theme.dividerColor.withAlpha((0.4 * 255).round());

    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.05 * 255).round()),
                    blurRadius: 28,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(theme),
                    const SizedBox(height: 24),
                    _buildSummaryRow(theme),
                    if (_show(PortfolioSection.skills)) ...[
                      const SizedBox(height: 32),
                      _SectionTitle(label: 'Expertise'),
                      const SizedBox(height: 12),
                      _buildSkillGrid(theme),
                    ],
                    if (_show(PortfolioSection.timeline)) ...[
                      const SizedBox(height: 32),
                      _SectionTitle(label: 'Experience timeline'),
                      const SizedBox(height: 12),
                      _buildTimeline(theme),
                    ],
                    if (_show(PortfolioSection.projects)) ...[
                      const SizedBox(height: 32),
                      _SectionTitle(label: 'Selected projects'),
                      const SizedBox(height: 12),
                      _buildProjectList(theme),
                    ],
                    if (config.analyticsEnabled) ...[
                      const SizedBox(height: 32),
                      _SectionTitle(label: 'GitHub analytics'),
                      const SizedBox(height: 12),
                      _buildAnalyticsSection(theme),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
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
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                user.bio ?? 'Software engineer',
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: theme.colorScheme.secondary),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (user.location != null)
                    _ContactPill(icon: Icons.place, label: user.location!),
                  if (user.email != null)
                    _ContactPill(
                        icon: Icons.email_outlined, label: user.email!),
                  _ContactPill(icon: Icons.link, label: user.htmlUrl),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(ThemeData theme) {
    final items = [
      _SummaryItem('Repositories', user.publicRepos.toString()),
      _SummaryItem('Followers', user.followers.toString()),
      _SummaryItem('Following', user.following.toString()),
      _SummaryItem('Member since', user.createdAt.year.toString()),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 500;
        return Flex(
          direction: isCompact ? Axis.vertical : Axis.horizontal,
          crossAxisAlignment:
              isCompact ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final item in items)
              Padding(
                padding: EdgeInsets.only(bottom: isCompact ? 12 : 0, right: 24),
                child: item,
              ),
          ],
        );
      },
    );
  }

  Widget _buildSkillGrid(ThemeData theme) {
    final skills = _languageDistribution(repos).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final visible = skills.take(6).toList();
    if (visible.isEmpty) {
      return Text(
        'Languages and stacks will appear after syncing repositories.',
        style: theme.textTheme.bodyMedium,
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final entry in visible)
          _SkillChip(
            label: entry.key,
            value: entry.value,
          ),
      ],
    );
  }

  Widget _buildTimeline(ThemeData theme) {
    final timeline = _timelineEntries(user, repos);
    return Column(
      children: [
        for (final entry in timeline)
          _TimelineRow(
            title: entry.title,
            subtitle: entry.subtitle,
            accent: entry.accent,
          ),
      ],
    );
  }

  Widget _buildProjectList(ThemeData theme) {
    final featured = [...repos]
      ..sort((a, b) => b.stargazersCount.compareTo(a.stargazersCount));
    final items = featured.take(5).toList();
    if (items.isEmpty) {
      return Text(
        'No repositories were found for this profile.',
        style: theme.textTheme.bodyMedium,
      );
    }

    return Column(
      children: [
        for (final repo in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.dividerColor.withAlpha((0.6 * 255).round()),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LazyProjectImage(
                      imageUrl: _projectPreview(repo),
                      semanticLabel: '${repo.name} preview image',
                    ),
                    const SizedBox(height: 12),
                    Text(
                      repo.name,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      repo.description ?? 'Repository description pending.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _RepoMeta(
                            icon: Icons.star_border,
                            label: '${repo.stargazersCount} stars'),
                        _RepoMeta(
                            icon: Icons.fork_left,
                            label: '${repo.forksCount} forks'),
                        _RepoMeta(
                            icon: Icons.code,
                            label: repo.language ?? 'Various'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAnalyticsSection(ThemeData theme) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: PortfolioAnalyticsSection(
          user: user,
          repos: repos,
        ),
      ),
    );
  }
}

String _projectPreview(RepositoryModel repo) {
  final slug = repo.fullName.isNotEmpty
      ? repo.fullName
      : '${repo.ownerLogin ?? 'user'}/${repo.name}';
  return 'https://opengraph.githubassets.com/resume/$slug';
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            letterSpacing: 1.4,
            color: Theme.of(context).colorScheme.secondary,
          ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.secondary),
        ),
      ],
    );
  }
}

class _ContactPill extends StatelessWidget {
  const _ContactPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.dividerColor.withAlpha((0.5 * 255).round()),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.secondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (value * 100).clamp(1, 100).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withAlpha((0.6 * 255).round()),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 4,
            backgroundColor: AppTheme.gitHubPurple,
          ),
          const SizedBox(width: 8),
          Text(label, style: theme.textTheme.bodyMedium),
          const SizedBox(width: 12),
          Text('$percent%', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 4, right: 12),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RepoMeta extends StatelessWidget {
  const _RepoMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.secondary),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _TimelineEntry {
  const _TimelineEntry({
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final Color accent;
}

Map<String, double> _languageDistribution(List<RepositoryModel> repos) {
  final counts = <String, double>{};
  for (final repo in repos) {
    final language = repo.language ?? 'Other';
    counts.update(language, (value) => value + 1, ifAbsent: () => 1);
  }
  if (counts.isEmpty) return {};
  final total = counts.values.reduce((a, b) => a + b);
  return counts.map((key, value) => MapEntry(key, value / total));
}

List<_TimelineEntry> _timelineEntries(
  GithubUserModel user,
  List<RepositoryModel> repos,
) {
  final sorted = [...repos]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  final latest = sorted.isEmpty ? null : sorted.first;
  final firstRepo = sorted.isEmpty ? null : sorted.last;
  final notable = sorted.isEmpty
      ? null
      : sorted.reduce(
          (a, b) => a.stargazersCount >= b.stargazersCount ? a : b,
        );

  return [
    _TimelineEntry(
      title: 'Joined GitHub',
      subtitle: 'Account created in ${user.createdAt.year}',
      accent: AppTheme.gitHubPurple,
    ),
    if (firstRepo != null)
      _TimelineEntry(
        title: 'First repository',
        subtitle: '${firstRepo.name} · since ${firstRepo.createdAt.year}',
        accent: AppTheme.gitHubYellow,
      ),
    if (notable != null)
      _TimelineEntry(
        title: 'Most starred',
        subtitle: '${notable.name} · ${notable.stargazersCount} stars',
        accent: AppTheme.gitHubOrange,
      ),
    if (latest != null)
      _TimelineEntry(
        title: 'Recent activity',
        subtitle: '${latest.name} updated ${latest.updatedAt.year}',
        accent: AppTheme.gitHubPurple,
      ),
  ];
}
