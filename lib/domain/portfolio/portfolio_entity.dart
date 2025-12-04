import 'package:equatable/equatable.dart';

/// Available layout templates for the generated portfolio.
enum PortfolioTemplate { modern, creative, professional }

/// Supported sections that can be toggled for a portfolio page.
enum PortfolioSection { hero, skills, projects, timeline, contact }

/// Export formats that the share feature can produce.
enum ExportFormat { pdf, markdown, html, json }

/// Aggregate configuration that defines how a portfolio should look.
class PortfolioConfig extends Equatable {
  PortfolioConfig({
    required this.userId,
    this.template = PortfolioTemplate.modern,
    this.sections = const [
      PortfolioSection.hero,
      PortfolioSection.skills,
      PortfolioSection.projects,
      PortfolioSection.contact,
    ],
    this.analyticsEnabled = false,
    this.includeAnalyticsInExports = false,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  final String userId;
  final PortfolioTemplate template;
  final List<PortfolioSection> sections;
  final bool analyticsEnabled;
  final bool includeAnalyticsInExports;
  final DateTime updatedAt;

  PortfolioConfig copyWith({
    PortfolioTemplate? template,
    List<PortfolioSection>? sections,
    bool? analyticsEnabled,
    bool? includeAnalyticsInExports,
    DateTime? updatedAt,
  }) {
    return PortfolioConfig(
      userId: userId,
      template: template ?? this.template,
      sections: sections ?? this.sections,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
      includeAnalyticsInExports:
          includeAnalyticsInExports ?? this.includeAnalyticsInExports,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        userId,
        template,
        sections,
        analyticsEnabled,
        includeAnalyticsInExports,
        updatedAt,
      ];
}
