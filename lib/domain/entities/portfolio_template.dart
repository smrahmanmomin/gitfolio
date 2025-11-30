/// Portfolio template entity representing different portfolio styles.
class PortfolioTemplate {
  final String id;
  final String name;
  final String description;
  final TemplateTheme theme;
  final List<TemplateSection> sections;

  const PortfolioTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.theme,
    required this.sections,
  });
}

/// Template theme configuration
class TemplateTheme {
  final String primaryColor;
  final String accentColor;
  final String backgroundColor;
  final String textColor;
  final String fontFamily;
  final LayoutStyle layoutStyle;

  const TemplateTheme({
    required this.primaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.textColor,
    required this.fontFamily,
    required this.layoutStyle,
  });
}

/// Layout style enumeration
enum LayoutStyle {
  modern, // Card-based, clean, minimal
  creative, // Bold, colorful, unique shapes
  professional // Traditional, formal, structured
}

/// Template section types
enum TemplateSection {
  header, // Profile photo, name, bio
  about, // Extended description
  skills, // Language/tech skills
  experience, // Work history
  projects, // Featured repositories
  contributions, // GitHub contribution graph
  statistics, // Analytics and metrics
  contact, // Social links
  achievements, // Badges, certifications
  education, // Academic background
}

/// Predefined portfolio templates
class PortfolioTemplates {
  static const modernDeveloper = PortfolioTemplate(
    id: 'modern_developer',
    name: 'Modern Developer',
    description: 'Clean, minimal design perfect for developers',
    theme: TemplateTheme(
      primaryColor: '#0366D6',
      accentColor: '#28A745',
      backgroundColor: '#FFFFFF',
      textColor: '#24292F',
      fontFamily: 'Inter',
      layoutStyle: LayoutStyle.modern,
    ),
    sections: [
      TemplateSection.header,
      TemplateSection.about,
      TemplateSection.skills,
      TemplateSection.projects,
      TemplateSection.contributions,
      TemplateSection.statistics,
      TemplateSection.contact,
    ],
  );

  static const creativePortfolio = PortfolioTemplate(
    id: 'creative_portfolio',
    name: 'Creative Portfolio',
    description: 'Bold and colorful design for creative professionals',
    theme: TemplateTheme(
      primaryColor: '#FF6B6B',
      accentColor: '#4ECDC4',
      backgroundColor: '#F7F7F7',
      textColor: '#2C3E50',
      fontFamily: 'Poppins',
      layoutStyle: LayoutStyle.creative,
    ),
    sections: [
      TemplateSection.header,
      TemplateSection.about,
      TemplateSection.projects,
      TemplateSection.skills,
      TemplateSection.achievements,
      TemplateSection.contributions,
      TemplateSection.contact,
    ],
  );

  static const professionalResume = PortfolioTemplate(
    id: 'professional_resume',
    name: 'Professional Resume',
    description: 'Traditional resume format for formal contexts',
    theme: TemplateTheme(
      primaryColor: '#2C3E50',
      accentColor: '#3498DB',
      backgroundColor: '#FFFFFF',
      textColor: '#333333',
      fontFamily: 'Roboto',
      layoutStyle: LayoutStyle.professional,
    ),
    sections: [
      TemplateSection.header,
      TemplateSection.experience,
      TemplateSection.education,
      TemplateSection.skills,
      TemplateSection.projects,
      TemplateSection.achievements,
      TemplateSection.contact,
    ],
  );

  static List<PortfolioTemplate> get all => [
        modernDeveloper,
        creativePortfolio,
        professionalResume,
      ];
}
