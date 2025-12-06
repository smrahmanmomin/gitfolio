import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../data/models/github_user_model.dart';
import '../../../data/models/repository_model.dart';
import '../../../domain/portfolio/portfolio_entity.dart';

/// Service responsible for exporting [PortfolioConfig] data to various formats.
class PortfolioExportService {
  const PortfolioExportService();

  /// Generates a PDF document containing the portfolio summary.
  Future<Uint8List> exportToPdf(
    PortfolioConfig config, {
    GithubUserModel? user,
    List<RepositoryModel>? repositories,
    String? bioOverride,
  }) async {
    final data = _buildExportData(config, user, repositories, bioOverride);
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        build: (context) => _buildPdfContent(data),
      ),
    );
    return document.save();
  }

  /// Generates a GitHub-flavored Markdown export.
  Future<Uint8List> exportToMarkdown(
    PortfolioConfig config, {
    GithubUserModel? user,
    List<RepositoryModel>? repositories,
    String? bioOverride,
  }) async {
    final data = _buildExportData(config, user, repositories, bioOverride);
    final buffer = StringBuffer()
      ..writeln('# ${data.displayName}')
      ..writeln('> ${data.headline}')
      ..writeln()
      ..writeln('- Template: **${data.config.template.name}**')
      ..writeln('- Updated: ${_formatDate(data.config.updatedAt)}')
      ..writeln('- GitHub: ${data.contact.github}')
      ..writeln();

    for (final section in data.config.sections) {
      buffer
        ..writeln('## ${_sectionLabel(section)}')
        ..writeln(_markdownSection(section, data))
        ..writeln();
    }

    if (_shouldIncludeAnalytics(data.config)) {
      buffer
        ..writeln('## Analytics overview')
        ..writeln(_markdownAnalyticsSection(data));
    }

    return Uint8List.fromList(utf8.encode(buffer.toString()));
  }

  /// Generates a responsive single-file HTML export.
  Future<Uint8List> exportToHtml(
    PortfolioConfig config, {
    GithubUserModel? user,
    List<RepositoryModel>? repositories,
    String? bioOverride,
  }) async {
    final data = _buildExportData(config, user, repositories, bioOverride);
    final html = _buildHtmlDocument(data);
    return Uint8List.fromList(utf8.encode(html));
  }

  /// Serializes the full portfolio payload as pretty-printed JSON.
  Future<Uint8List> exportToJson(
    PortfolioConfig config, {
    GithubUserModel? user,
    List<RepositoryModel>? repositories,
    String? bioOverride,
  }) async {
    final data = _buildExportData(config, user, repositories, bioOverride);
    final encoder = const JsonEncoder.withIndent('  ');
    final payload = <String, dynamic>{
      'version': '2.0.0',
      'generatedAt': DateTime.now().toIso8601String(),
      'template': data.config.template.name,
      'sectionsOrder': data.config.sections.map((s) => s.name).toList(),
      'user': {
        'id': data.config.userId,
        'displayName': data.displayName,
        'headline': data.headline,
        'avatarUrl': data.avatarUrl,
      },
      'sections': _jsonSections(data),
      'contact': data.contact.toJson(),
      if (_shouldIncludeAnalytics(data.config))
        'analytics': data.analytics.toJson(),
    };
    return Uint8List.fromList(utf8.encode(encoder.convert(payload)));
  }

  List<pw.Widget> _buildPdfContent(_ExportData data) {
    final content = <pw.Widget>[
      _buildPdfHeader(data),
      pw.SizedBox(height: 16),
    ];

    for (final section in data.config.sections) {
      final sectionBody = _pdfSectionBody(section, data);
      if (sectionBody == null) continue;
      content.add(
        _pdfSectionContainer(
          _sectionLabel(section),
          sectionBody,
        ),
      );
    }

    if (_shouldIncludeAnalytics(data.config)) {
      content.add(
        _pdfSectionContainer(
          'Analytics overview',
          _buildPdfAnalytics(data),
        ),
      );
    }

    return content;
  }

  pw.Widget _buildPdfHeader(_ExportData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          data.displayName,
          style: pw.TextStyle(
            fontSize: 26,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          data.headline,
          style: const pw.TextStyle(fontSize: 12),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Template: ${data.config.template.name}   |   Updated: ${_formatDate(data.config.updatedAt)}',
          style: const pw.TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  pw.Widget _pdfSectionContainer(String title, pw.Widget child) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 18),
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
            bottom: pw.BorderSide(width: 0.5, color: PdfColors.grey300)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  pw.Widget? _pdfSectionBody(PortfolioSection section, _ExportData data) {
    switch (section) {
      case PortfolioSection.hero:
        return _buildPdfHero(data);
      case PortfolioSection.skills:
        return _buildPdfSkills(data);
      case PortfolioSection.projects:
        return _buildPdfProjects(data);
      case PortfolioSection.timeline:
        return _buildPdfTimeline(data);
      case PortfolioSection.contact:
        return _buildPdfContact(data);
    }
  }

  pw.Widget _buildPdfHero(_ExportData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(data.headline),
        pw.SizedBox(height: 8),
        if (data.heroStats.isNotEmpty)
          pw.Wrap(
            spacing: 12,
            runSpacing: 6,
            children: data.heroStats
                .map(
                  (stat) => pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey200,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text('${stat.label}: ${stat.value}'),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  pw.Widget _buildPdfSkills(_ExportData data) {
    if (data.skills.isEmpty) {
      return pw.Text('No repository data available yet.');
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: data.skills
          .take(6)
          .map(
            (skill) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 3),
              child: pw.Text('${skill.label} - ${_formatPercent(skill.value)}'),
            ),
          )
          .toList(),
    );
  }

  pw.Widget _buildPdfProjects(_ExportData data) {
    if (data.projects.isEmpty) {
      return pw.Text('Add repositories to highlight your work.');
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: data.projects
          .map(
            (project) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    project.name,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(project.description),
                  pw.Text(
                    'Stack: ${project.language} - Stars: ${project.stars} - Forks: ${project.forks}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    'Updated ${_formatHumanDate(project.updatedAt)} - ${project.url}',
                    style:
                        const pw.TextStyle(fontSize: 9, color: PdfColors.blue),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  pw.Widget _buildPdfTimeline(_ExportData data) {
    if (data.timeline.isEmpty) {
      return pw.Text('Timeline data becomes available once repositories sync.');
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: data.timeline
          .map(
            (entry) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    entry.title,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(entry.subtitle),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  pw.Widget _buildPdfContact(_ExportData data) {
    final contacts = data.contact.asEntries();
    if (contacts.isEmpty) {
      return pw.Text('Contact details will appear once linked to GitHub.');
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: contacts
          .map((entry) => pw.Text('${entry.label}: ${entry.value}'))
          .toList(),
    );
  }

  pw.Widget _buildPdfAnalytics(_ExportData data) {
    final analytics = data.analytics;
    final totals = [
      'Repositories: ${analytics.totalRepos}',
      'Stars: ${analytics.totalStars}',
      'Forks: ${analytics.totalForks}',
      'Watchers: ${analytics.totalWatchers}',
    ];

    final languages = analytics.languageShare.entries
        .map((entry) => '${entry.key}: ${_formatPercent(entry.value)}')
        .join(', ');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(totals.join('   |   ')),
        if (languages.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          pw.Text('Top languages: $languages'),
        ],
        if (analytics.highlight != null) ...[
          pw.SizedBox(height: 8),
          pw.Text(
            'Standout repo: ${analytics.highlight!.name} (${analytics.highlight!.stars} stars) - ${analytics.highlight!.description}',
          ),
        ],
      ],
    );
  }

  String _markdownSection(PortfolioSection section, _ExportData data) {
    switch (section) {
      case PortfolioSection.hero:
        final stats = data.heroStats
            .map((stat) => '- **${stat.label}:** ${stat.value}')
            .join('\n');
        return '${data.headline}\n\n$stats';
      case PortfolioSection.skills:
        if (data.skills.isEmpty) {
          return 'No skills detected yet.';
        }
        return data.skills
            .take(6)
            .map((skill) =>
                '- ${skill.label}: ${_formatPercent(skill.value)} of recent work')
            .join('\n');
      case PortfolioSection.projects:
        if (data.projects.isEmpty) {
          return 'Connect repositories to highlight your work.';
        }
        return data.projects
            .map(
              (project) =>
                  '- **${project.name}** - ${project.description}\n  - ${project.language}: ${project.stars} stars / ${project.forks} forks\n  - Updated ${_formatHumanDate(project.updatedAt)} - [View repo](${project.url})',
            )
            .join('\n');
      case PortfolioSection.timeline:
        if (data.timeline.isEmpty) {
          return 'Timeline becomes available once repositories sync.';
        }
        return data.timeline
            .map((entry) => '- **${entry.title}:** ${entry.subtitle}')
            .join('\n');
      case PortfolioSection.contact:
        final contacts = data.contact.asEntries();
        if (contacts.isEmpty) {
          return 'No contact information available.';
        }
        return contacts
            .map((entry) => '- **${entry.label}:** ${entry.value}')
            .join('\n');
    }
  }

  String _markdownAnalyticsSection(_ExportData data) {
    final analytics = data.analytics;
    final buffer = StringBuffer()
      ..writeln('- **Total repos:** ${analytics.totalRepos}')
      ..writeln('- **Stars:** ${analytics.totalStars}')
      ..writeln('- **Forks:** ${analytics.totalForks}')
      ..writeln('- **Watchers:** ${analytics.totalWatchers}');
    if (analytics.languageShare.isNotEmpty) {
      buffer.writeln('- **Top languages:**');
      analytics.languageShare.entries.take(5).forEach((entry) {
        buffer.writeln(
            '  - ${entry.key}: ${_formatPercent(entry.value)} of repository activity');
      });
    }
    if (analytics.highlight != null) {
      buffer.writeln(
          '- **Breakout repo:** ${analytics.highlight!.name} (${analytics.highlight!.stars} stars)');
    }
    return buffer.toString();
  }

  String _buildHtmlDocument(_ExportData data) {
    final sectionHtml = StringBuffer();
    for (final section in data.config.sections) {
      sectionHtml.writeln(_htmlSection(section, data));
    }
    if (_shouldIncludeAnalytics(data.config)) {
      sectionHtml.writeln(_htmlAnalyticsSection(data));
    }

    return '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <meta name="title" content="${_escapeHtml(data.displayName)} Portfolio" />
  <meta name="description" content="Portfolio export for ${_escapeHtml(data.displayName)}" />
  <title>${_escapeHtml(data.displayName)} · Portfolio</title>
  <style>
    :root {
      font-family: 'Segoe UI', Helvetica, Arial, sans-serif;
      color: #0f172a;
      background: #f6f8fc;
    }
    body {
      margin: 0;
      padding: 0;
      background: #f6f8fc;
    }
    header {
      background: linear-gradient(135deg, #6f42c1, #0ea5e9);
      color: #fff;
      padding: 3rem 1.5rem;
      text-align: center;
    }
    header img {
      width: 88px;
      height: 88px;
      border-radius: 50%;
      border: 3px solid rgba(255,255,255,0.5);
      margin-bottom: 1rem;
    }
    main {
      max-width: 920px;
      margin: -3rem auto 3rem auto;
      padding: 0 1rem;
    }
    section {
      background: #fff;
      border-radius: 18px;
      padding: 1.75rem;
      margin-bottom: 1.25rem;
      box-shadow: 0 20px 40px rgba(15,23,42,0.08);
    }
    h2 {
      margin-top: 0;
      font-size: 1.4rem;
    }
    .headline {
      font-size: 1.1rem;
      color: #334155;
      line-height: 1.5;
    }
    .stat-grid {
      list-style: none;
      padding: 0;
      margin: 1.5rem 0 0;
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
      gap: 0.85rem;
    }
    .stat-grid li {
      padding: 0.85rem;
      border-radius: 12px;
      background: #f8fafc;
      border: 1px solid #e2e8f0;
    }
    .projects {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
      gap: 1rem;
      padding: 0;
      list-style: none;
    }
    .projects li {
      border: 1px solid #e2e8f0;
      border-radius: 12px;
      padding: 1rem;
      background: #fdfefe;
    }
    .skills li {
      margin-bottom: 0.6rem;
    }
    .skill-bar {
      width: 100%;
      height: 8px;
      border-radius: 999px;
      background: #e2e8f0;
      overflow: hidden;
      margin-top: 0.35rem;
    }
    .skill-bar span {
      display: block;
      height: 100%;
      background: linear-gradient(90deg, #f472b6, #8b5cf6);
      width: var(--value);
    }
    .timeline {
      list-style: none;
      padding: 0;
      margin: 0;
      border-left: 3px solid #e2e8f0;
    }
    .timeline li {
      margin-left: 1rem;
      padding-left: 1rem;
      position: relative;
      margin-bottom: 1rem;
    }
    .timeline li::before {
      content: '';
      position: absolute;
      left: -1.25rem;
      top: 0.3rem;
      width: 0.65rem;
      height: 0.65rem;
      border-radius: 50%;
      background: #6366f1;
      border: 2px solid #fff;
      box-shadow: 0 0 0 2px #e2e8f0;
    }
    @media (max-width: 640px) {
      header {
        padding: 2.5rem 1rem;
      }
      main {
        margin-top: -2rem;
      }
    }
  </style>
</head>
<body>
  <header>
    ${data.avatarUrl != null ? '<img src="${_escapeHtml(data.avatarUrl!)}" alt="${_escapeHtml(data.displayName)} avatar" />' : ''}
    <h1>${_escapeHtml(data.displayName)}</h1>
    <p>${_escapeHtml(data.headline)}</p>
    <p>Template · ${_escapeHtml(data.config.template.name)}</p>
  </header>
  <main>
    ${sectionHtml.toString()}
  </main>
</body>
</html>
''';
  }

  String _htmlSection(PortfolioSection section, _ExportData data) {
    switch (section) {
      case PortfolioSection.hero:
        final stats = data.heroStats
            .map((stat) =>
                '<li><strong>${_escapeHtml(stat.label)}</strong><br>${_escapeHtml(stat.value)}</li>')
            .join();
        return '''<section id="hero">
  <h2>${_sectionLabel(section)}</h2>
  <p class="headline">${_escapeHtml(data.headline)}</p>
  <ul class="stat-grid">$stats</ul>
</section>''';
      case PortfolioSection.skills:
        if (data.skills.isEmpty) {
          return '''<section id="skills">
  <h2>${_sectionLabel(section)}</h2>
  <p>No repository data to calculate skills yet.</p>
</section>''';
        }
        final items = data.skills.take(6).map((skill) {
          final percent = _formatPercent(skill.value);
          return '<li>${_escapeHtml(skill.label)}<div class="skill-bar"><span style="--value: $percent;"></span></div></li>';
        }).join();
        return '''<section id="skills">
  <h2>${_sectionLabel(section)}</h2>
  <ul class="skills">$items</ul>
</section>''';
      case PortfolioSection.projects:
        if (data.projects.isEmpty) {
          return '''<section id="projects">
  <h2>${_sectionLabel(section)}</h2>
  <p>Connect repositories to surface project highlights.</p>
</section>''';
        }
        final projectItems = data.projects.map((project) {
          final topics = project.topics.isEmpty
              ? ''
              : '<p>${_escapeHtml(project.topics.take(3).join(', '))}</p>';
          return '''<li>
    <h3>${_escapeHtml(project.name)}</h3>
    <p>${_escapeHtml(project.description)}</p>
    <p>${_escapeHtml(project.language)} • ${project.stars}★ / ${project.forks} forks</p>
    <p>Updated ${_escapeHtml(_formatHumanDate(project.updatedAt))}</p>
    $topics
    <a href="${_escapeHtml(project.url)}">${_escapeHtml(project.url)}</a>
  </li>''';
        }).join();
        return '''<section id="projects">
  <h2>${_sectionLabel(section)}</h2>
  <ul class="projects">$projectItems</ul>
</section>''';
      case PortfolioSection.timeline:
        if (data.timeline.isEmpty) {
          return '''<section id="timeline">
  <h2>${_sectionLabel(section)}</h2>
  <p>Timeline data will populate after syncing repositories.</p>
</section>''';
        }
        final timelineItems = data.timeline
            .map((entry) =>
                '<li><strong>${_escapeHtml(entry.title)}</strong><br>${_escapeHtml(entry.subtitle)}</li>')
            .join();
        return '''<section id="timeline">
  <h2>${_sectionLabel(section)}</h2>
  <ol class="timeline">$timelineItems</ol>
</section>''';
      case PortfolioSection.contact:
        final entries = data.contact.asEntries();
        if (entries.isEmpty) {
          return '''<section id="contact">
  <h2>${_sectionLabel(section)}</h2>
  <p>No contact preferences provided.</p>
</section>''';
        }
        final contactList = entries
            .map((entry) =>
                '<li><strong>${_escapeHtml(entry.label)}</strong>: ${_escapeHtml(entry.value)}</li>')
            .join();
        return '''<section id="contact">
  <h2>${_sectionLabel(section)}</h2>
  <ul>$contactList</ul>
</section>''';
    }
  }

  String _htmlAnalyticsSection(_ExportData data) {
    final analytics = data.analytics;
    final languages = analytics.languageShare.entries
        .map((entry) =>
            '<li>${_escapeHtml(entry.key)} — ${_formatPercent(entry.value)}</li>')
        .join();
    final highlight = analytics.highlight == null
        ? ''
        : '<p>Breakout repo: <strong>${_escapeHtml(analytics.highlight!.name)}</strong> (${analytics.highlight!.stars}★)</p>';
    return '''<section id="analytics">
  <h2>Analytics overview</h2>
  <p>Repos: ${analytics.totalRepos} • Stars: ${analytics.totalStars} • Forks: ${analytics.totalForks} • Watchers: ${analytics.totalWatchers}</p>
  <ul>$languages</ul>
  $highlight
</section>''';
  }

  Map<String, dynamic> _jsonSections(_ExportData data) {
    final sections = <String, dynamic>{};
    for (final section in data.config.sections) {
      switch (section) {
        case PortfolioSection.hero:
          sections['hero'] = {
            'headline': data.headline,
            'stats': data.heroStats
                .map((stat) => {'label': stat.label, 'value': stat.value})
                .toList(),
          };
          break;
        case PortfolioSection.skills:
          sections['skills'] = data.skills
              .map((skill) => {
                    'label': skill.label,
                    'weight': skill.value,
                  })
              .toList();
          break;
        case PortfolioSection.projects:
          sections['projects'] =
              data.projects.map((project) => project.toJson()).toList();
          break;
        case PortfolioSection.timeline:
          sections['timeline'] = data.timeline
              .map(
                  (entry) => {'title': entry.title, 'subtitle': entry.subtitle})
              .toList();
          break;
        case PortfolioSection.contact:
          sections['contact'] = data.contact.toJson();
          break;
      }
    }
    return sections;
  }
}

bool _shouldIncludeAnalytics(PortfolioConfig config) =>
    config.analyticsEnabled && config.includeAnalyticsInExports;

String _sectionLabel(PortfolioSection section) {
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

String _formatPercent(double value) =>
    '${(value * 100).clamp(0, 100).toStringAsFixed(0)}%';

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String _formatHumanDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final month = months[(date.month - 1).clamp(0, months.length - 1)];
  return '$month ${date.year}';
}

String _escapeHtml(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}

_ExportData _buildExportData(
  PortfolioConfig config,
  GithubUserModel? user,
  List<RepositoryModel>? repositories,
  String? bioOverride,
) {
  final repos =
      List<RepositoryModel>.from(repositories ?? const <RepositoryModel>[]);
  final effectiveBio = _sanitizeText(bioOverride) ??
      _sanitizeText(user?.bio) ??
      'Exploring creativity through code.';
  final displayName = _sanitizeText(user?.name) ?? user?.login ?? config.userId;
  final heroSkills = _buildSkillEntries(repos);
  final projects = _buildProjectEntries(repos);
  final timeline = _buildTimelineEntries(user, repos);
  final contact = _ContactInfo(
    email: _sanitizeText(user?.email),
    website: _sanitizeText(user?.blog),
    location: _sanitizeText(user?.location),
    github: user?.htmlUrl ?? 'https://github.com/${config.userId}',
    twitter: _sanitizeText(user?.twitterUsername),
  );
  final heroStats = _buildHeroStats(config, user, heroSkills, repos);
  final analytics = _buildAnalyticsSnapshot(repos, heroSkills, projects);
  return _ExportData(
    config: config,
    user: user,
    avatarUrl: user?.avatarUrl,
    displayName: displayName,
    headline: effectiveBio,
    heroStats: heroStats,
    skills: heroSkills,
    projects: projects,
    timeline: timeline,
    contact: contact,
    analytics: analytics,
  );
}

List<_HeroStat> _buildHeroStats(
  PortfolioConfig config,
  GithubUserModel? user,
  List<_SkillEntry> skills,
  List<RepositoryModel> repos,
) {
  final stats = <_HeroStat>[];
  if (_sanitizeText(user?.location) != null) {
    stats.add(_HeroStat('Location', _sanitizeText(user?.location)!));
  }
  if (user != null) {
    stats
      ..add(_HeroStat('Followers', user.followers.toString()))
      ..add(_HeroStat('Following', user.following.toString()))
      ..add(_HeroStat('Public repos', user.publicRepos.toString()));
  } else {
    stats.add(_HeroStat('GitHub handle', config.userId));
  }
  if (skills.isNotEmpty) {
    stats.add(_HeroStat('Primary stack', skills.first.label));
  } else if (repos.isNotEmpty) {
    stats.add(_HeroStat('Latest repo', repos.first.name));
  }
  stats.add(_HeroStat('Template', config.template.name));
  return stats;
}

List<_SkillEntry> _buildSkillEntries(List<RepositoryModel> repos) {
  final totals = <String, double>{};
  for (final repo in repos) {
    final language = _sanitizeText(repo.language) ?? 'Other';
    totals.update(
      language,
      (value) => value + repo.stargazersCount + 1,
      ifAbsent: () => repo.stargazersCount + 1,
    );
  }
  final totalWeight =
      totals.values.fold<double>(0, (sum, value) => sum + value);
  if (totalWeight == 0) {
    return const <_SkillEntry>[];
  }
  final entries = totals.entries
      .map((entry) =>
          _SkillEntry(label: entry.key, value: entry.value / totalWeight))
      .toList();
  entries.sort((a, b) => b.value.compareTo(a.value));
  return entries;
}

List<_ProjectEntry> _buildProjectEntries(List<RepositoryModel> repos) {
  if (repos.isEmpty) {
    return const <_ProjectEntry>[];
  }
  final sorted = List<RepositoryModel>.from(repos)
    ..sort((a, b) {
      final starCompare = b.stargazersCount.compareTo(a.stargazersCount);
      if (starCompare != 0) return starCompare;
      return b.updatedAt.compareTo(a.updatedAt);
    });
  return sorted.take(4).map((repo) {
    return _ProjectEntry(
      name: repo.name,
      description: _sanitizeText(repo.description) ?? 'Open-source project.',
      url: repo.htmlUrl,
      language: _sanitizeText(repo.language) ?? 'Multi-stack',
      stars: repo.stargazersCount,
      forks: repo.forksCount,
      updatedAt: repo.updatedAt,
      topics: repo.topics,
    );
  }).toList();
}

List<_TimelineEntry> _buildTimelineEntries(
  GithubUserModel? user,
  List<RepositoryModel> repos,
) {
  final entries = <_TimelineEntry>[];
  if (user != null) {
    entries.add(_TimelineEntry(
      title: 'Joined GitHub',
      subtitle: 'Active since ${user.createdAt.year}',
    ));
  }
  if (repos.isNotEmpty) {
    final topRepo =
        repos.reduce((a, b) => a.stargazersCount >= b.stargazersCount ? a : b);
    entries.add(
      _TimelineEntry(
        title: 'Breakthrough project',
        subtitle: '${topRepo.name} surpassed ${topRepo.stargazersCount} stars',
      ),
    );
    final latest = repos.reduce(
      (a, b) => a.updatedAt.isAfter(b.updatedAt) ? a : b,
    );
    entries.add(
      _TimelineEntry(
        title: 'Latest release',
        subtitle:
            '${latest.name} refreshed ${_formatHumanDate(latest.updatedAt)}',
      ),
    );
  }
  return entries;
}

_AnalyticsSnapshot _buildAnalyticsSnapshot(
  List<RepositoryModel> repos,
  List<_SkillEntry> skills,
  List<_ProjectEntry> projects,
) {
  final totalStars =
      repos.fold<int>(0, (sum, repo) => sum + repo.stargazersCount);
  final totalForks = repos.fold<int>(0, (sum, repo) => sum + repo.forksCount);
  final totalWatchers =
      repos.fold<int>(0, (sum, repo) => sum + repo.watchersCount);
  final activityTrend = _buildMonthlyActivityTrend(repos);
  final highlight = projects.isEmpty ? null : projects.first;
  final languageShare = {
    for (final skill in skills) skill.label: skill.value,
  };
  return _AnalyticsSnapshot(
    totalRepos: repos.length,
    totalStars: totalStars,
    totalForks: totalForks,
    totalWatchers: totalWatchers,
    languageShare: languageShare,
    activityTrend: activityTrend,
    highlight: highlight,
  );
}

List<_MonthlyMetricPoint> _buildMonthlyActivityTrend(
    List<RepositoryModel> repos) {
  if (repos.isEmpty) {
    return const <_MonthlyMetricPoint>[];
  }
  final now = DateTime.now();
  final points = <_MonthlyMetricPoint>[];
  for (var i = 11; i >= 0; i--) {
    final monthDate = DateTime(now.year, now.month - i, 1);
    final label = _formatHumanDate(monthDate);
    final monthlyScore = repos.where((repo) =>
        repo.updatedAt.year == monthDate.year &&
        repo.updatedAt.month == monthDate.month);
    final value = monthlyScore.fold<double>(
      0,
      (sum, repo) =>
          sum + 1 + (repo.stargazersCount / 100) + (repo.topics.length * 0.1),
    );
    points.add(_MonthlyMetricPoint(
        label: label, value: double.parse(value.toStringAsFixed(2))));
  }
  return points;
}

String? _sanitizeText(String? input) {
  if (input == null) return null;
  final trimmed = input.trim();
  return trimmed.isEmpty ? null : trimmed;
}

class _ExportData {
  const _ExportData({
    required this.config,
    required this.user,
    required this.avatarUrl,
    required this.displayName,
    required this.headline,
    required this.heroStats,
    required this.skills,
    required this.projects,
    required this.timeline,
    required this.contact,
    required this.analytics,
  });

  final PortfolioConfig config;
  final GithubUserModel? user;
  final String? avatarUrl;
  final String displayName;
  final String headline;
  final List<_HeroStat> heroStats;
  final List<_SkillEntry> skills;
  final List<_ProjectEntry> projects;
  final List<_TimelineEntry> timeline;
  final _ContactInfo contact;
  final _AnalyticsSnapshot analytics;
}

class _HeroStat {
  const _HeroStat(this.label, this.value);
  final String label;
  final String value;
}

class _SkillEntry {
  const _SkillEntry({required this.label, required this.value});
  final String label;
  final double value;
}

class _ProjectEntry {
  const _ProjectEntry({
    required this.name,
    required this.description,
    required this.url,
    required this.language,
    required this.stars,
    required this.forks,
    required this.updatedAt,
    required this.topics,
  });

  final String name;
  final String description;
  final String url;
  final String language;
  final int stars;
  final int forks;
  final DateTime updatedAt;
  final List<String> topics;

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'url': url,
        'language': language,
        'stars': stars,
        'forks': forks,
        'updatedAt': updatedAt.toIso8601String(),
        'topics': topics,
      };
}

class _TimelineEntry {
  const _TimelineEntry({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
}

class _ContactInfo {
  const _ContactInfo({
    this.email,
    this.website,
    this.location,
    required this.github,
    this.twitter,
  });

  final String? email;
  final String? website;
  final String? location;
  final String github;
  final String? twitter;

  List<_HeroStat> asEntries() {
    final entries = <_HeroStat>[];
    if (email != null) entries.add(_HeroStat('Email', email!));
    if (website != null) entries.add(_HeroStat('Website', website!));
    if (location != null) entries.add(_HeroStat('Location', location!));
    entries.add(_HeroStat('GitHub', github));
    if (twitter != null) entries.add(_HeroStat('Twitter', twitter!));
    return entries;
  }

  Map<String, dynamic> toJson() => {
        'email': email,
        'website': website,
        'location': location,
        'github': github,
        'twitter': twitter,
      }..removeWhere((key, value) => value == null);
}

class _AnalyticsSnapshot {
  const _AnalyticsSnapshot({
    required this.totalRepos,
    required this.totalStars,
    required this.totalForks,
    required this.totalWatchers,
    required this.languageShare,
    required this.activityTrend,
    required this.highlight,
  });

  final int totalRepos;
  final int totalStars;
  final int totalForks;
  final int totalWatchers;
  final Map<String, double> languageShare;
  final List<_MonthlyMetricPoint> activityTrend;
  final _ProjectEntry? highlight;

  Map<String, dynamic> toJson() => {
        'totals': {
          'repositories': totalRepos,
          'stars': totalStars,
          'forks': totalForks,
          'watchers': totalWatchers,
        },
        'languageShare': languageShare,
        'activityTrend': activityTrend
            .map((point) => {'label': point.label, 'value': point.value})
            .toList(),
        if (highlight != null) 'highlight': highlight!.toJson(),
      };
}

class _MonthlyMetricPoint {
  const _MonthlyMetricPoint({required this.label, required this.value});
  final String label;
  final double value;
}
