import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/github_user_model.dart';
import '../../../data/models/repository_model.dart';
import '../../../domain/portfolio/portfolio_entity.dart';
import '../bloc/portfolio_bloc.dart';
import '../bloc/portfolio_state.dart';
import 'sections/contact_section.dart' as contact;
import 'sections/hero_section.dart' as hero;
import 'sections/projects_section.dart' as projects;
import 'sections/skills_section.dart' as skills;
import 'sections/timeline_section.dart' as timeline;

class PreviewController {
  PreviewController({double initialZoom = 1.0})
      : zoom = ValueNotifier<double>(
          initialZoom.clamp(_minZoom, _maxZoom),
        ),
        highlightedSection = ValueNotifier<PortfolioSection?>(null);

  static const double _minZoom = 0.8;
  static const double _maxZoom = 1.2;

  final ValueNotifier<double> zoom;
  final ValueNotifier<PortfolioSection?> highlightedSection;
  final GlobalKey rootBoundaryKey = GlobalKey();
  final Map<PortfolioSection, GlobalKey> _sectionBoundaryKeys = {};

  double get zoomValue => zoom.value;

  void setZoom(double value) {
    zoom.value = value.clamp(_minZoom, _maxZoom);
  }

  void stepZoom(double delta) => setZoom(zoom.value + delta);

  void highlightSection(PortfolioSection? section) {
    highlightedSection.value = section;
  }

  void registerSectionBoundary(
    PortfolioSection section,
    GlobalKey boundaryKey,
  ) {
    _sectionBoundaryKeys[section] = boundaryKey;
  }

  GlobalKey? boundaryKeyFor(PortfolioSection section) =>
      _sectionBoundaryKeys[section];

  Future<Uint8List?> captureScreenshot({double pixelRatio = 2.0}) async {
    final renderObject = rootBoundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (renderObject == null) return null;
    final image = await renderObject.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  void dispose() {
    zoom.dispose();
    highlightedSection.dispose();
  }
}

class LivePreviewPane extends StatefulWidget {
  const LivePreviewPane({
    super.key,
    required this.user,
    this.repos = const <RepositoryModel>[],
    required this.controller,
    this.onScreenshotCaptured,
    this.desktopBreakpoint = 1100,
    this.tabletBreakpoint = 720,
  });

  final GithubUserModel? user;
  final List<RepositoryModel> repos;
  final PreviewController controller;
  final ValueChanged<Uint8List>? onScreenshotCaptured;
  final double desktopBreakpoint;
  final double tabletBreakpoint;

  @override
  State<LivePreviewPane> createState() => _LivePreviewPaneState();
}

class _LivePreviewPaneState extends State<LivePreviewPane> {
  PortfolioState? _debouncedState;
  Timer? _debounce;
  bool _tabletVisible = true;

  @override
  void initState() {
    super.initState();
    _debouncedState = context.read<PortfolioBloc>().state;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PortfolioBloc, PortfolioState>(
      listenWhen: (previous, current) => previous != current,
      listener: (context, state) {
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 200), () {
          if (!mounted) return;
          setState(() => _debouncedState = state);
        });
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final state = _debouncedState ?? context.read<PortfolioBloc>().state;
          if (width >= widget.desktopBreakpoint) {
            return _PreviewSurface(
              state: state,
              user: widget.user,
              repos: widget.repos,
              controller: widget.controller,
              onScreenshotCaptured: widget.onScreenshotCaptured,
            );
          }
          if (width >= widget.tabletBreakpoint) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: _tabletVisible ? 'Hide preview' : 'Show preview',
                    onPressed: () =>
                        setState(() => _tabletVisible = !_tabletVisible),
                    icon: Icon(
                      _tabletVisible ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _tabletVisible
                      ? _PreviewSurface(
                          key: const ValueKey('tablet-preview'),
                          state: state,
                          user: widget.user,
                          repos: widget.repos,
                          controller: widget.controller,
                          onScreenshotCaptured: widget.onScreenshotCaptured,
                        )
                      : const _TabletPreviewPlaceholder(),
                ),
              ],
            );
          }
          return Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => _openMobileModal(context),
              icon: const Icon(Icons.phone_android),
              label: const Text('Open preview'),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openMobileModal(BuildContext context) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close preview',
      pageBuilder: (dialogContext, _, __) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: const Text('Live preview'),
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(dialogContext).maybePop(),
              ),
            ],
          ),
          body: SafeArea(
            child: BlocBuilder<PortfolioBloc, PortfolioState>(
              builder: (context, state) {
                return _PreviewSurface(
                  state: state,
                  user: widget.user,
                  repos: widget.repos,
                  controller: widget.controller,
                  onScreenshotCaptured: widget.onScreenshotCaptured,
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _PreviewSurface extends StatelessWidget {
  const _PreviewSurface({
    super.key,
    required this.state,
    required this.user,
    required this.repos,
    required this.controller,
    this.onScreenshotCaptured,
  });

  final PortfolioState state;
  final GithubUserModel? user;
  final List<RepositoryModel> repos;
  final PreviewController controller;
  final ValueChanged<Uint8List>? onScreenshotCaptured;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _PreviewToolbar(
            controller: controller,
            sections: state.config?.sections ?? const <PortfolioSection>[],
            onScreenshotCaptured: onScreenshotCaptured,
          ),
          const Divider(height: 1),
          Expanded(
            child: PortfolioPreview(
              state: state,
              user: user,
              repos: repos,
              controller: controller,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewToolbar extends StatelessWidget {
  const _PreviewToolbar({
    required this.controller,
    required this.sections,
    this.onScreenshotCaptured,
  });

  final PreviewController controller;
  final List<PortfolioSection> sections;
  final ValueChanged<Uint8List>? onScreenshotCaptured;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text('Preview', style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          IconButton(
            tooltip: 'Zoom out',
            onPressed: () => controller.stepZoom(-0.05),
            icon: const Icon(Icons.zoom_out_map),
          ),
          SizedBox(
            width: 160,
            child: ValueListenableBuilder<double>(
              valueListenable: controller.zoom,
              builder: (context, value, _) {
                return Slider(
                  min: 0.8,
                  max: 1.2,
                  divisions: 8,
                  label: '${(value * 100).round()}%',
                  value: value,
                  onChanged: controller.setZoom,
                );
              },
            ),
          ),
          IconButton(
            tooltip: 'Zoom in',
            onPressed: () => controller.stepZoom(0.05),
            icon: const Icon(Icons.zoom_in_map),
          ),
          if (sections.isNotEmpty)
            ValueListenableBuilder<PortfolioSection?>(
              valueListenable: controller.highlightedSection,
              builder: (context, highlighted, _) {
                return PopupMenuButton<PortfolioSection?>(
                  tooltip: 'Highlight section',
                  icon: Icon(
                    highlighted == null ? Icons.layers_outlined : Icons.layers,
                  ),
                  onSelected: controller.highlightSection,
                  itemBuilder: (context) {
                    return [
                      const PopupMenuItem<PortfolioSection?>(
                        value: null,
                        child: Text('Clear highlight'),
                      ),
                      const PopupMenuDivider(),
                      ...sections.map(
                        (section) => PopupMenuItem<PortfolioSection?>(
                          value: section,
                          child: Text(_sectionLabel(section)),
                        ),
                      ),
                    ];
                  },
                );
              },
            ),
          IconButton(
            tooltip: 'Capture screenshot',
            onPressed: () async {
              final messenger = ScaffoldMessenger.maybeOf(context);
              final bytes = await controller.captureScreenshot();
              if (bytes == null) return;
              onScreenshotCaptured?.call(bytes);
              messenger?.showSnackBar(
                const SnackBar(content: Text('Preview captured')),
              );
            },
            icon: const Icon(Icons.camera_alt_outlined),
          ),
        ],
      ),
    );
  }

  static String _sectionLabel(PortfolioSection section) {
    switch (section) {
      case PortfolioSection.hero:
        return 'Hero';
      case PortfolioSection.skills:
        return 'Skills';
      case PortfolioSection.projects:
        return 'Projects';
      case PortfolioSection.timeline:
        return 'Timeline';
      case PortfolioSection.contact:
        return 'Contact';
    }
  }
}

class _TabletPreviewPlaceholder extends StatelessWidget {
  const _TabletPreviewPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Text(
        'Preview hidden to save space.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class PortfolioPreview extends StatefulWidget {
  const PortfolioPreview({
    super.key,
    required this.state,
    required this.user,
    required this.repos,
    required this.controller,
  });

  final PortfolioState state;
  final GithubUserModel? user;
  final List<RepositoryModel> repos;
  final PreviewController controller;

  @override
  State<PortfolioPreview> createState() => _PortfolioPreviewState();
}

class _PortfolioPreviewState extends State<PortfolioPreview> {
  static const int _maxCacheEntries = 3;
  final Map<int, Widget> _templateCache = <int, Widget>{};
  final ListQueue<int> _cacheOrder = ListQueue<int>();
  final Map<PortfolioSection, GlobalKey> _sectionKeys = {};

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final user = widget.user;
    if (user == null) {
      return const _PreviewMessage(
        icon: Icons.person_add_alt,
        message: 'Connect your GitHub account to start the preview.',
      );
    }

    if (state is PortfolioError) {
      return _PreviewMessage(
        icon: Icons.error_outline,
        message: state.message,
      );
    }

    final config = state.config;
    if (config == null) {
      return const _PreviewShimmer();
    }

    final template = _resolveTemplate(context, config, user, widget.repos);
    final templateKey = _cacheKey(config, user, widget.repos);
    final templateSwitcher = AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: KeyedSubtree(
        key: ValueKey<int>(templateKey),
        child: template,
      ),
    );

    final stack = Stack(
      children: [
        RepaintBoundary(
          key: widget.controller.rootBoundaryKey,
          child: ValueListenableBuilder<double>(
            valueListenable: widget.controller.zoom,
            child: templateSwitcher,
            builder: (context, zoom, child) {
              return Transform.scale(
                scale: zoom,
                alignment: Alignment.topCenter,
                child: child,
              );
            },
          ),
        ),
        if (state is PortfolioLoading)
          const Positioned.fill(
            child: IgnorePointer(child: _PreviewShimmer(opacity: 0.6)),
          ),
      ],
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).colorScheme.surface,
      child: stack,
    );
  }

  Widget _resolveTemplate(
    BuildContext context,
    PortfolioConfig config,
    GithubUserModel user,
    List<RepositoryModel> repos,
  ) {
    final cacheKey = _cacheKey(config, user, repos);
    final cached = _templateCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final sections = _buildSections(context, config, user, repos);
    final layout = _TemplateLayout(
      template: config.template,
      sections: sections,
    );
    _templateCache[cacheKey] = layout;
    _cacheOrder.add(cacheKey);
    if (_cacheOrder.length > _maxCacheEntries) {
      final oldest = _cacheOrder.removeFirst();
      _templateCache.remove(oldest);
    }
    return layout;
  }

  List<Widget> _buildSections(
    BuildContext context,
    PortfolioConfig config,
    GithubUserModel user,
    List<RepositoryModel> repos,
  ) {
    final widgets = <Widget>[];
    for (final section in config.sections) {
      final sectionWidget = _buildSectionWidget(section, user, repos);
      if (sectionWidget == null) continue;
      final boundaryKey = _sectionKeys.putIfAbsent(
          section, () => GlobalKey(debugLabel: section.name));
      widget.controller.registerSectionBoundary(section, boundaryKey);
      widgets.add(
        _SectionBoundary(
          section: section,
          controller: widget.controller,
          boundaryKey: boundaryKey,
          child: sectionWidget,
        ),
      );
    }
    if (widgets.isEmpty) {
      return const [
        _PreviewMessage(
          icon: Icons.inbox_outlined,
          message: 'Enable a section to see it here.',
        ),
      ];
    }
    return widgets;
  }

  Widget? _buildSectionWidget(
    PortfolioSection section,
    GithubUserModel user,
    List<RepositoryModel> repos,
  ) {
    switch (section) {
      case PortfolioSection.hero:
        return hero.HeroSectionWidget(
          data: hero.HeroSectionData(
            avatarUrl: user.avatarUrl,
            name: user.name ?? user.login,
            title: user.company ?? 'Independent developer',
            bio: user.bio ?? 'Building for the open source community.',
            socialLinks: _heroLinks(user),
          ),
        );
      case PortfolioSection.skills:
        final languageWeights = _languageWeights(repos);
        return skills.SkillsSectionWidget(
          data: skills.SkillsSectionData(
            languages: languageWeights,
            skills: languageWeights.entries
                .take(5)
                .map(
                  (entry) =>
                      skills.SkillEntry(label: entry.key, level: entry.value),
                )
                .toList(),
          ),
        );
      case PortfolioSection.projects:
        final cards = repos
            .sortedByStars()
            .take(6)
            .map(
              (repo) => projects.ProjectCardData(
                name: repo.name,
                description: repo.description ?? 'No description yet.',
                language: repo.language ?? 'Unknown',
                stars: repo.stargazersCount,
                updatedAt: repo.updatedAt,
              ),
            )
            .toList();
        final languages = repos
            .map((repo) => repo.language)
            .whereType<String>()
            .toSet()
            .toList();
        return projects.ProjectsSectionWidget(
          data: projects.ProjectsSectionData(
            projects: cards,
            languages: languages,
          ),
        );
      case PortfolioSection.timeline:
        final contributions = _buildContributions(repos);
        final events = _timelineEvents(user, repos);
        final years = contributions.map((day) => day.date.year).toSet().toList()
          ..sort();
        return timeline.TimelineSectionWidget(
          data: timeline.TimelineSectionData(
            contributions: contributions,
            events: events,
            availableYears: years.isEmpty ? [DateTime.now().year] : years,
            initialYear: years.isEmpty ? DateTime.now().year : years.last,
          ),
        );
      case PortfolioSection.contact:
        return contact.ContactSectionWidget(
          data: contact.ContactSectionData(
            socialLinks: _contactLinks(user),
            locationImageUrl: _mapPreview(user.location),
          ),
        );
    }
  }

  int _cacheKey(
    PortfolioConfig config,
    GithubUserModel user,
    List<RepositoryModel> repos,
  ) {
    return Object.hashAll([
      config.template,
      Object.hashAll(config.sections),
      user.updatedAt.millisecondsSinceEpoch,
      repos.length,
      repos.isEmpty ? 0 : repos.first.updatedAt.millisecondsSinceEpoch,
    ]);
  }
}

extension on List<RepositoryModel> {
  List<RepositoryModel> sortedByStars() {
    final clones = List<RepositoryModel>.from(this);
    clones.sort((a, b) => b.stargazersCount.compareTo(a.stargazersCount));
    return clones;
  }
}

class _SectionBoundary extends StatelessWidget {
  const _SectionBoundary({
    required this.section,
    required this.controller,
    required this.boundaryKey,
    required this.child,
  });

  final PortfolioSection section;
  final PreviewController controller;
  final GlobalKey boundaryKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PortfolioSection?>(
      valueListenable: controller.highlightedSection,
      builder: (context, highlighted, _) {
        final isHighlighted = highlighted == section;
        return RepaintBoundary(
          key: boundaryKey,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isHighlighted
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: isHighlighted ? 2.5 : 0,
              ),
              boxShadow: isHighlighted
                  ? [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.25),
                        blurRadius: 18,
                        spreadRadius: 4,
                      ),
                    ]
                  : null,
            ),
            child: child,
          ),
        );
      },
    );
  }
}

class _TemplateLayout extends StatelessWidget {
  const _TemplateLayout({
    required this.template,
    required this.sections,
  });

  final PortfolioTemplate template;
  final List<Widget> sections;

  @override
  Widget build(BuildContext context) {
    final padding = EdgeInsets.symmetric(
      horizontal: template == PortfolioTemplate.creative ? 32 : 24,
      vertical: 24,
    );
    Color background;
    switch (template) {
      case PortfolioTemplate.modern:
        background = Theme.of(context).colorScheme.surfaceContainerHighest;
        break;
      case PortfolioTemplate.creative:
        background =
            Theme.of(context).colorScheme.surfaceTint.withValues(alpha: 0.08);
        break;
      case PortfolioTemplate.professional:
        background = Theme.of(context).colorScheme.surface;
        break;
    }
    final spacing = template == PortfolioTemplate.creative ? 36.0 : 24.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        gradient: template == PortfolioTemplate.creative
            ? LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                  Theme.of(context).colorScheme.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
      ),
      child: ListView.separated(
        key: PageStorageKey<String>('preview-${template.name}'),
        padding: padding,
        physics: const BouncingScrollPhysics(),
        itemCount: sections.length,
        itemBuilder: (context, index) => sections[index],
        separatorBuilder: (context, index) => SizedBox(height: spacing),
      ),
    );
  }
}

class _PreviewMessage extends StatelessWidget {
  const _PreviewMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _PreviewShimmer extends StatefulWidget {
  const _PreviewShimmer({this.opacity = 1.0});

  final double opacity;

  @override
  State<_PreviewShimmer> createState() => _PreviewShimmerState();
}

class _PreviewShimmerState extends State<_PreviewShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Opacity(
          opacity: widget.opacity,
          child: ShaderMask(
            shaderCallback: (rect) {
              return LinearGradient(
                colors: [
                  Colors.grey.shade300,
                  Colors.grey.shade100,
                  Colors.grey.shade300,
                ],
                stops: const [0.1, 0.3, 0.4],
                begin: Alignment(-1 - _controller.value, -0.3),
                end: Alignment(1.0 - _controller.value, 0.3),
              ).createShader(rect);
            },
            child: const DecoratedBox(
              decoration: BoxDecoration(color: Colors.white),
              child: SizedBox.expand(),
            ),
          ),
        );
      },
    );
  }
}

List<hero.SocialLinkData> _heroLinks(GithubUserModel user) {
  final links = <hero.SocialLinkData>[];
  if (user.blog != null && user.blog!.isNotEmpty) {
    links.add(hero.SocialLinkData(label: 'Website', url: user.blog!));
  }
  links.add(hero.SocialLinkData(label: 'GitHub', url: user.htmlUrl));
  if (user.twitterUsername != null && user.twitterUsername!.isNotEmpty) {
    links.add(
      hero.SocialLinkData(
        label: '@${user.twitterUsername}',
        url: 'https://twitter.com/${user.twitterUsername}',
      ),
    );
  }
  return links;
}

Map<String, double> _languageWeights(List<RepositoryModel> repos) {
  if (repos.isEmpty) return {};
  final counts = <String, double>{};
  for (final repo in repos) {
    final language = repo.language ?? 'Other';
    counts[language] = (counts[language] ?? 0) + repo.stargazersCount + 1;
  }
  final total = counts.values.fold<double>(0, (a, b) => a + b);
  if (total == 0) return counts;
  return counts.map((key, value) => MapEntry(key, value / total));
}

List<timeline.ContributionDay> _buildContributions(
    List<RepositoryModel> repos) {
  final now = DateTime.now();
  final start = now.subtract(const Duration(days: 365));
  final contributions = <DateTime, int>{};
  for (final repo in repos) {
    final day =
        DateTime(repo.updatedAt.year, repo.updatedAt.month, repo.updatedAt.day);
    contributions[day] =
        (contributions[day] ?? 0) + 1 + repo.stargazersCount ~/ 50;
  }
  final days = <timeline.ContributionDay>[];
  for (int i = 0; i < 365; i++) {
    final date = start.add(Duration(days: i));
    final normalized = DateTime(date.year, date.month, date.day);
    days.add(
      timeline.ContributionDay(
        date: normalized,
        count: contributions[normalized] ?? (i % 6 == 0 ? 1 : 0),
      ),
    );
  }
  return days;
}

List<timeline.TimelineEventData> _timelineEvents(
  GithubUserModel user,
  List<RepositoryModel> repos,
) {
  final events = <timeline.TimelineEventData>[
    timeline.TimelineEventData(
      title: 'Joined GitHub',
      subtitle: 'Account created',
      date: user.createdAt,
    ),
  ];
  final topRepos = repos.sortedByStars().take(3);
  for (final repo in topRepos) {
    events.add(
      timeline.TimelineEventData(
        title: repo.name,
        subtitle: repo.description ?? 'Repository milestone',
        date: repo.createdAt,
      ),
    );
  }
  return events;
}

List<contact.SocialLinkData> _contactLinks(GithubUserModel user) {
  final links = <contact.SocialLinkData>[
    contact.SocialLinkData(label: 'GitHub', url: user.htmlUrl),
  ];
  if (user.email != null && user.email!.isNotEmpty) {
    links.add(contact.SocialLinkData(
        label: user.email!, url: 'mailto:${user.email}'));
  }
  if (user.blog != null && user.blog!.isNotEmpty) {
    links.add(contact.SocialLinkData(label: 'Website', url: user.blog!));
  }
  if (user.location != null && user.location!.isNotEmpty) {
    links.add(contact.SocialLinkData(label: user.location!, url: '#location'));
  }
  return links;
}

String _mapPreview(String? location) {
  final encoded = Uri.encodeComponent(location ?? 'San Francisco');
  return 'https://static-maps.yandex.ru/1.x/?ll=0,0&size=650,450&z=3&l=map&pt=0,0,pm2rdm~0,0,pm2blm&text=$encoded';
}
