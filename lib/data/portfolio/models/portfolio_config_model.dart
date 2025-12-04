import '../../../domain/portfolio/portfolio_entity.dart';

class PortfolioConfigModel extends PortfolioConfig {
  PortfolioConfigModel({
    required String userId,
    PortfolioTemplate template = PortfolioTemplate.modern,
    List<PortfolioSection> sections = const [
      PortfolioSection.hero,
      PortfolioSection.skills,
      PortfolioSection.projects,
      PortfolioSection.contact,
    ],
    bool analyticsEnabled = false,
    bool includeAnalyticsInExports = false,
    DateTime? updatedAt,
  }) : super(
          userId: userId,
          template: template,
          sections: sections,
          analyticsEnabled: analyticsEnabled,
          includeAnalyticsInExports: includeAnalyticsInExports,
          updatedAt: updatedAt,
        );

  factory PortfolioConfigModel.fromJson(Map<String, dynamic> json) {
    return PortfolioConfigModel(
      userId: json['userId'] as String,
      template: PortfolioTemplate.values
          .byName(json['template'] as String? ?? 'modern'),
      sections: (json['sections'] as List<dynamic>? ?? const [])
          .map(
            (value) => PortfolioSection.values.byName(value as String),
          )
          .toList(),
      analyticsEnabled: json['analyticsEnabled'] as bool? ?? false,
      includeAnalyticsInExports:
          json['includeAnalyticsInExports'] as bool? ?? false,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'template': template.name,
      'sections': sections.map((section) => section.name).toList(),
      'analyticsEnabled': analyticsEnabled,
      'includeAnalyticsInExports': includeAnalyticsInExports,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PortfolioConfigModel.fromEntity(PortfolioConfig config) {
    return PortfolioConfigModel(
      userId: config.userId,
      template: config.template,
      sections: List<PortfolioSection>.from(config.sections),
      analyticsEnabled: config.analyticsEnabled,
      includeAnalyticsInExports: config.includeAnalyticsInExports,
      updatedAt: config.updatedAt,
    );
  }

  factory PortfolioConfigModel.defaultForUser(String userId) {
    return PortfolioConfigModel(userId: userId);
  }
}
