import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../domain/portfolio/portfolio_entity.dart';

/// Service responsible for exporting [PortfolioConfig] data to various formats.
class PortfolioExportService {
  const PortfolioExportService();

  /// Generates a PDF document containing the portfolio summary.
  Future<Uint8List> exportToPdf(PortfolioConfig config) async {
    final document = pw.Document();
    final sections = config.sections;
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        build: (context) {
          return [
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 12),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(width: 1)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    config.userId,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text('Contact: ${config.userId}@users.noreply.github.com'),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            for (final section in sections) ...[
              pw.Container(
                margin: const pw.EdgeInsets.symmetric(vertical: 8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      _sectionLabel(section),
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(_sectionBody(section)),
                  ],
                ),
              ),
            ],
            if (_shouldIncludeAnalytics(config)) ...[
              pw.SizedBox(height: 12),
              pw.Text(
                'Analytics overview',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(_analyticsNarrative(config)),
            ],
          ];
        },
      ),
    );

    return document.save();
  }

  /// Generates a GitHub-flavored Markdown export.
  Future<Uint8List> exportToMarkdown(PortfolioConfig config) async {
    final buffer = StringBuffer()
      ..writeln('# ${config.userId} Portfolio')
      ..writeln(
          '![Template](https://img.shields.io/badge/template-${config.template.name}-blue)')
      ..writeln(
          '![Updated](https://img.shields.io/badge/updated-${_formatDate(config.updatedAt)}-success)')
      ..writeln()
      ..writeln('## Table of contents');

    for (final section in config.sections) {
      buffer.writeln('- [${_sectionLabel(section)}](#${section.name})');
    }
    if (_shouldIncludeAnalytics(config)) {
      buffer.writeln('- [Analytics overview](#analytics)');
    }

    for (final section in config.sections) {
      buffer
        ..writeln('\n<a name="${section.name}"></a>')
        ..writeln('## ${_sectionLabel(section)}')
        ..writeln(_sectionBody(section))
        ..writeln('\n```text')
        ..writeln('Project highlights for ${section.name} go here...')
        ..writeln('```');
    }
    if (_shouldIncludeAnalytics(config)) {
      buffer
        ..writeln('\n<a name="analytics"></a>')
        ..writeln('## Analytics overview')
        ..writeln(_analyticsNarrative(config));
    }

    return Uint8List.fromList(utf8.encode(buffer.toString()));
  }

  /// Generates a responsive single-file HTML export.
  Future<Uint8List> exportToHtml(PortfolioConfig config) async {
    final sectionsHtml = config.sections
        .map(
          (section) => '<section id="${section.name}">\n'
              '<h2>${_sectionLabel(section)}</h2>\n'
              '<p>${_sectionBody(section)}</p>\n'
              '</section>',
        )
        .join('\n');

    final analyticsHtml = _shouldIncludeAnalytics(config)
        ? '<section id="analytics">\n'
            '<h2>Analytics overview</h2>\n'
            '<p>${_analyticsNarrative(config)}</p>\n'
            '</section>'
        : '';

    final html = '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <meta name="title" content="${config.userId} Portfolio" />
  <meta name="description" content="Portfolio export for ${config.userId}" />
  <meta name="keywords" content="portfolio, ${config.userId}, developer" />
  <title>${config.userId} Portfolio</title>
  <style>
    :root {
      color-scheme: light dark;
      font-family: 'Segoe UI', Arial, sans-serif;
    }
    body {
      margin: 0;
      padding: 0;
      background: #f5f5f5;
      color: #1b1f23;
    }
    header {
      background: linear-gradient(120deg, #6f42c1, #0366d6);
      color: white;
      padding: 3rem 1.5rem;
      text-align: center;
    }
    main {
      padding: 2rem;
      max-width: 900px;
      margin: 0 auto;
    }
    section {
      background: white;
      border-radius: 16px;
      padding: 1.5rem;
      margin-bottom: 1.25rem;
      box-shadow: 0 10px 30px rgba(0,0,0,0.1);
    }
    h1, h2 {
      margin: 0 0 1rem 0;
    }
    @media (max-width: 640px) {
      header {
        padding: 2rem 1rem;
      }
      main {
        padding: 1rem;
      }
    }
  </style>
</head>
<body>
  <header>
    <h1>${config.userId}</h1>
    <p>Template: ${config.template.name}</p>
  </header>
  <main>
    $sectionsHtml
    $analyticsHtml
  </main>
</body>
</html>
''';

    return Uint8List.fromList(utf8.encode(html));
  }

  /// Serializes the full portfolio payload as pretty-printed JSON.
  Future<Uint8List> exportToJson(PortfolioConfig config) async {
    final encoder = const JsonEncoder.withIndent('  ');
    final payload = <String, dynamic>{
      'version': '1.0.0',
      'generatedAt': DateTime.now().toIso8601String(),
      'config': _configToJson(config),
      if (_shouldIncludeAnalytics(config))
        'analytics': {
          'summary': _analyticsNarrative(config),
        },
    };
    return Uint8List.fromList(utf8.encode(encoder.convert(payload)));
  }

  Map<String, dynamic> _configToJson(PortfolioConfig config) {
    return {
      'userId': config.userId,
      'template': config.template.name,
      'sections': config.sections.map((section) => section.name).toList(),
      'analyticsEnabled': config.analyticsEnabled,
      'includeAnalyticsInExports': config.includeAnalyticsInExports,
      'updatedAt': config.updatedAt.toIso8601String(),
    };
  }

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

  String _sectionBody(PortfolioSection section) {
    switch (section) {
      case PortfolioSection.hero:
        return 'Introduce yourself and describe your mission statement.';
      case PortfolioSection.skills:
        return 'Summaries of languages, frameworks, and tooling expertise.';
      case PortfolioSection.projects:
        return 'Highlighted repositories with impact statements.';
      case PortfolioSection.timeline:
        return 'Milestones, roles, and key accomplishments over time.';
      case PortfolioSection.contact:
        return 'Best ways to reach out for collaborations or work.';
    }
  }

  bool _shouldIncludeAnalytics(PortfolioConfig config) =>
      config.analyticsEnabled && config.includeAnalyticsInExports;

  String _analyticsNarrative(PortfolioConfig config) {
    return 'Developer activity insights, contribution trends, and repository performance metrics are bundled with this export because analytics are enabled for ${config.userId}. Use these snapshots to showcase consistency, language breadth, and momentum alongside the primary portfolio sections.';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
