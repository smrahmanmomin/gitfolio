import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/themes/app_theme.dart';
import '../../../../data/models/github_user_model.dart';
import '../../../../data/models/repository_model.dart';
import '../../../../domain/portfolio/portfolio_entity.dart';
import '../analytics/portfolio_analytics_section.dart';
import '../lazy_project_image.dart';

class CreativePortfolioTemplate extends StatefulWidget {
  const CreativePortfolioTemplate({
    super.key,
    required this.user,
    required this.repos,
    required this.config,
  });

  final GithubUserModel user;
  final List<RepositoryModel> repos;
  final PortfolioConfig config;

  @override
  State<CreativePortfolioTemplate> createState() =>
      _CreativePortfolioTemplateState();
}

class _CreativePortfolioTemplateState extends State<CreativePortfolioTemplate> {
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        final gradient = LinearGradient(
          colors: [
            Theme.of(context)
                .colorScheme
                .primary
                .withAlpha((0.85 * 255).round()),
            AppTheme.gitHubPurple.withAlpha((0.85 * 255).round()),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );

        final horizontalPadding = isWide ? 48.0 : 20.0;
        final contentWidth = constraints.maxWidth - (horizontalPadding * 2);

        return Container(
          decoration: BoxDecoration(gradient: gradient),
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _NebulaPainter())),
              SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeroCard(context, isWide),
                    const SizedBox(height: 24),
                    if (_show(PortfolioSection.skills))
                      _buildSkillBars(context),
                    if (_show(PortfolioSection.skills))
                      const SizedBox(height: 32),
                    if (_show(PortfolioSection.timeline))
                      _buildTimeline(context, isWide),
                    if (_show(PortfolioSection.projects))
                      const SizedBox(height: 32),
                    if (_show(PortfolioSection.projects))
                      _buildCreativeProjects(context, isWide, contentWidth),
                    if (widget.config.analyticsEnabled)
                      const SizedBox(height: 32),
                    if (widget.config.analyticsEnabled)
                      _buildAnalyticsSection(context),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _show(PortfolioSection section) =>
      widget.config.sections.contains(section);

  Widget _buildHeroCard(BuildContext context, bool isWide) {
    final theme = Theme.of(context);
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.user.name ?? widget.user.login,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.user.bio ?? 'Exploring creativity through code.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.white70,
          ),
        ),
      ],
    );

    return Card(
      color: Colors.white.withAlpha((0.08 * 255).round()),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Flex(
          direction: isWide ? Axis.horizontal : Axis.vertical,
          crossAxisAlignment:
              isWide ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 56,
              backgroundImage: NetworkImage(widget.user.avatarUrl),
            ),
            SizedBox(width: isWide ? 24 : 0, height: isWide ? 0 : 16),
            if (isWide) Expanded(child: details) else details,
          ],
        ),
      ),
    );
  }

  Widget _buildSkillBars(BuildContext context) {
    final skillData =
        _languageDistribution(widget.repos).entries.take(5).toList();
    final theme = Theme.of(context);
    return Card(
      color: Colors.white.withAlpha((0.1 * 255).round()),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Creative stack',
              style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 16),
            for (final entry in skillData)
              _AnimatedSkillBar(
                label: entry.key,
                value: entry.value,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, bool isWide) {
    final items = _timelineItems(widget.user, widget.repos);
    final stepper = Stepper(
      type: isWide ? StepperType.horizontal : StepperType.vertical,
      currentStep: _currentStep,
      onStepTapped: (index) => setState(() => _currentStep = index),
      controlsBuilder: (context, details) => const SizedBox.shrink(),
      steps: [
        for (final item in items)
          Step(
            title: Text(
              item.title,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: Colors.white),
            ),
            content: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                item.subtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.white70),
              ),
            ),
            state: StepState.indexed,
            isActive: items.indexOf(item) <= _currentStep,
          ),
      ],
    );

    return Card(
      color: Colors.white.withAlpha((0.1 * 255).round()),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: isWide
          ? SizedBox(height: 320, child: stepper)
          : Padding(
              padding: const EdgeInsets.all(8),
              child: stepper,
            ),
    );
  }

  Widget _buildCreativeProjects(
    BuildContext context,
    bool isWide,
    double contentWidth,
  ) {
    final projects = widget.repos.take(4).toList();
    if (projects.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final cardWidth = isWide
        ? math.max((contentWidth - 16) / 2, 240).toDouble()
        : double.infinity;
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        for (final project in projects)
          SizedBox(
            width: cardWidth,
            child: Card(
              color: Colors.white.withAlpha((0.12 * 255).round()),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LazyProjectImage(
                      imageUrl: _repoPreviewUrl(project),
                      semanticLabel: '${project.name} preview',
                    ),
                    const SizedBox(height: 12),
                    Text(
                      project.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      project.description ?? 'A creative experiment.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.palette_outlined,
                            color: Colors.white70, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          project.language ?? 'Multi-stack',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
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

  Widget _buildAnalyticsSection(BuildContext context) {
    return Card(
      color: Colors.white.withAlpha((0.1 * 255).round()),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: PortfolioAnalyticsSection(
          user: widget.user,
          repos: widget.repos,
          title: 'Pulse report',
          description:
              'Contribution streaks, languages, and repo momentum in one glance.',
        ),
      ),
    );
  }
}

String _repoPreviewUrl(RepositoryModel repo) {
  final slug = repo.fullName.isNotEmpty
      ? repo.fullName
      : '${repo.ownerLogin ?? 'user'}/${repo.name}';
  return 'https://opengraph.githubassets.com/share/$slug';
}

class _AnimatedSkillBar extends StatelessWidget {
  const _AnimatedSkillBar({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final percent = value.clamp(0.0, 1.0);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.15 * 255).round()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: percent),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (context, animated, child) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: constraints.maxWidth * animated,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppTheme.gitHubYellow,
                              AppTheme.gitHubPurple
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem {
  const _TimelineItem({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}

List<_TimelineItem> _timelineItems(
  GithubUserModel user,
  List<RepositoryModel> repos,
) {
  final mostStarred = repos.isEmpty
      ? null
      : repos.reduce((a, b) => a.stargazersCount >= b.stargazersCount ? a : b);
  final latest = repos.isEmpty
      ? null
      : repos.reduce((a, b) => a.updatedAt.isAfter(b.updatedAt) ? a : b);

  return [
    _TimelineItem(
      title: 'Joined',
      subtitle: 'Since ${user.createdAt.year}',
    ),
    if (mostStarred != null)
      _TimelineItem(
        title: 'Breakthrough',
        subtitle:
            '${mostStarred.name} reached ${mostStarred.stargazersCount} stars',
      ),
    if (latest != null)
      _TimelineItem(
        title: 'Latest drop',
        subtitle: '${latest.name} updated ${latest.updatedAt.year}',
      ),
  ];
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

class _NebulaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..blendMode = BlendMode.srcOver;
    final random = math.Random(8);
    for (var i = 0; i < 12; i++) {
      final radius = random.nextDouble() * 200 + 80;
      final center = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      paint.shader = RadialGradient(
        colors: [
          Colors.white.withAlpha((0.08 * 255).round()),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
