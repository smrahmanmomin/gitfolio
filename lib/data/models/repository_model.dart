import 'package:equatable/equatable.dart';

/// Data model representing a GitHub repository.
///
/// This model corresponds to the GitHub Repository API response and includes
/// all relevant fields for displaying repository information.
class RepositoryModel extends Equatable {
  /// The repository's unique ID
  final int id;

  /// The repository name (without owner)
  final String name;

  /// The full repository name (owner/repo)
  final String fullName;

  /// The repository description
  final String? description;

  /// URL to the repository's GitHub page
  final String htmlUrl;

  /// The primary programming language
  final String? language;

  /// Number of stars
  final int stargazersCount;

  /// Number of forks
  final int forksCount;

  /// Repository size in KB
  final int size;

  /// The date the repository was last updated
  final DateTime updatedAt;

  /// The date the repository was created
  final DateTime createdAt;

  /// List of topics/tags
  final List<String> topics;

  /// License information
  final String? license;

  /// Whether the repository has issues enabled
  final bool hasIssues;

  /// Whether the repository has projects enabled
  final bool hasProjects;

  /// Whether the repository has downloads enabled
  final bool hasDownloads;

  /// Whether the repository has wiki enabled
  final bool hasWiki;

  /// Whether this repository is a fork
  final bool isFork;

  /// Number of forks (same as forksCount, kept for compatibility)
  final int forkCount;

  /// Number of watchers
  final int watchersCount;

  /// The default branch name
  final String defaultBranch;

  /// Number of open issues
  final int? openIssuesCount;

  /// Whether the repository is private
  final bool isPrivate;

  /// Whether the repository is archived
  final bool? isArchived;

  /// The repository owner's login
  final String? ownerLogin;

  /// The repository owner's avatar URL
  final String? ownerAvatarUrl;

  /// URL to clone the repository
  final String? cloneUrl;

  /// Git URL of the repository
  final String? gitUrl;

  /// SSH URL of the repository
  final String? sshUrl;

  /// URL to the repository's homepage
  final String? homepage;

  const RepositoryModel({
    required this.id,
    required this.name,
    required this.fullName,
    this.description,
    required this.htmlUrl,
    this.language,
    required this.stargazersCount,
    required this.forksCount,
    required this.size,
    required this.updatedAt,
    required this.createdAt,
    required this.topics,
    this.license,
    required this.hasIssues,
    required this.hasProjects,
    required this.hasDownloads,
    required this.hasWiki,
    required this.isFork,
    required this.forkCount,
    required this.watchersCount,
    required this.defaultBranch,
    this.openIssuesCount,
    required this.isPrivate,
    this.isArchived,
    this.ownerLogin,
    this.ownerAvatarUrl,
    this.cloneUrl,
    this.gitUrl,
    this.sshUrl,
    this.homepage,
  });

  /// Creates a [RepositoryModel] from a JSON map.
  ///
  /// Example:
  /// ```dart
  /// final repo = RepositoryModel.fromJson({
  ///   'id': 123,
  ///   'name': 'my-repo',
  ///   'full_name': 'user/my-repo',
  ///   // ... other fields
  /// });
  /// ```
  factory RepositoryModel.fromJson(Map<String, dynamic> json) {
    // Parse license
    String? licenseName;
    if (json['license'] != null && json['license'] is Map) {
      licenseName = json['license']['name'] as String?;
    }

    // Parse topics
    List<String> topicsList = [];
    if (json['topics'] != null && json['topics'] is List) {
      topicsList = (json['topics'] as List)
          .map((topic) => topic.toString())
          .toList();
    }

    // Parse owner information
    String? ownerLogin;
    String? ownerAvatarUrl;
    if (json['owner'] != null && json['owner'] is Map) {
      final owner = json['owner'] as Map<String, dynamic>;
      ownerLogin = owner['login'] as String?;
      ownerAvatarUrl = owner['avatar_url'] as String?;
    }

    return RepositoryModel(
      id: json['id'] as int,
      name: json['name'] as String,
      fullName: json['full_name'] as String,
      description: json['description'] as String?,
      htmlUrl: json['html_url'] as String,
      language: json['language'] as String?,
      stargazersCount: json['stargazers_count'] as int? ?? 0,
      forksCount: json['forks_count'] as int? ?? 0,
      size: json['size'] as int? ?? 0,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      topics: topicsList,
      license: licenseName,
      hasIssues: json['has_issues'] as bool? ?? false,
      hasProjects: json['has_projects'] as bool? ?? false,
      hasDownloads: json['has_downloads'] as bool? ?? false,
      hasWiki: json['has_wiki'] as bool? ?? false,
      isFork: json['fork'] as bool? ?? false,
      forkCount: json['forks'] as int? ?? json['forks_count'] as int? ?? 0,
      watchersCount: json['watchers_count'] as int? ?? 0,
      defaultBranch: json['default_branch'] as String? ?? 'main',
      openIssuesCount: json['open_issues_count'] as int?,
      isPrivate: json['private'] as bool? ?? false,
      isArchived: json['archived'] as bool?,
      ownerLogin: ownerLogin,
      ownerAvatarUrl: ownerAvatarUrl,
      cloneUrl: json['clone_url'] as String?,
      gitUrl: json['git_url'] as String?,
      sshUrl: json['ssh_url'] as String?,
      homepage: json['homepage'] as String?,
    );
  }

  /// Converts this [RepositoryModel] to a JSON map.
  ///
  /// Example:
  /// ```dart
  /// final json = repository.toJson();
  /// // json = {'id': 123, 'name': 'my-repo', ...}
  /// ```
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'full_name': fullName,
      'description': description,
      'html_url': htmlUrl,
      'language': language,
      'stargazers_count': stargazersCount,
      'forks_count': forksCount,
      'size': size,
      'updated_at': updatedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'topics': topics,
      'license': license != null ? {'name': license} : null,
      'has_issues': hasIssues,
      'has_projects': hasProjects,
      'has_downloads': hasDownloads,
      'has_wiki': hasWiki,
      'fork': isFork,
      'forks': forkCount,
      'watchers_count': watchersCount,
      'default_branch': defaultBranch,
      'open_issues_count': openIssuesCount,
      'private': isPrivate,
      'archived': isArchived,
      'owner': ownerLogin != null
          ? {'login': ownerLogin, 'avatar_url': ownerAvatarUrl}
          : null,
      'clone_url': cloneUrl,
      'git_url': gitUrl,
      'ssh_url': sshUrl,
      'homepage': homepage,
    };
  }

  /// Creates a copy of this [RepositoryModel] with the given fields replaced.
  RepositoryModel copyWith({
    int? id,
    String? name,
    String? fullName,
    String? description,
    String? htmlUrl,
    String? language,
    int? stargazersCount,
    int? forksCount,
    int? size,
    DateTime? updatedAt,
    DateTime? createdAt,
    List<String>? topics,
    String? license,
    bool? hasIssues,
    bool? hasProjects,
    bool? hasDownloads,
    bool? hasWiki,
    bool? isFork,
    int? forkCount,
    int? watchersCount,
    String? defaultBranch,
    int? openIssuesCount,
    bool? isPrivate,
    bool? isArchived,
    String? ownerLogin,
    String? ownerAvatarUrl,
    String? cloneUrl,
    String? gitUrl,
    String? sshUrl,
    String? homepage,
  }) {
    return RepositoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      fullName: fullName ?? this.fullName,
      description: description ?? this.description,
      htmlUrl: htmlUrl ?? this.htmlUrl,
      language: language ?? this.language,
      stargazersCount: stargazersCount ?? this.stargazersCount,
      forksCount: forksCount ?? this.forksCount,
      size: size ?? this.size,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      topics: topics ?? this.topics,
      license: license ?? this.license,
      hasIssues: hasIssues ?? this.hasIssues,
      hasProjects: hasProjects ?? this.hasProjects,
      hasDownloads: hasDownloads ?? this.hasDownloads,
      hasWiki: hasWiki ?? this.hasWiki,
      isFork: isFork ?? this.isFork,
      forkCount: forkCount ?? this.forkCount,
      watchersCount: watchersCount ?? this.watchersCount,
      defaultBranch: defaultBranch ?? this.defaultBranch,
      openIssuesCount: openIssuesCount ?? this.openIssuesCount,
      isPrivate: isPrivate ?? this.isPrivate,
      isArchived: isArchived ?? this.isArchived,
      ownerLogin: ownerLogin ?? this.ownerLogin,
      ownerAvatarUrl: ownerAvatarUrl ?? this.ownerAvatarUrl,
      cloneUrl: cloneUrl ?? this.cloneUrl,
      gitUrl: gitUrl ?? this.gitUrl,
      sshUrl: sshUrl ?? this.sshUrl,
      homepage: homepage ?? this.homepage,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    fullName,
    description,
    htmlUrl,
    language,
    stargazersCount,
    forksCount,
    size,
    updatedAt,
    createdAt,
    topics,
    license,
    hasIssues,
    hasProjects,
    hasDownloads,
    hasWiki,
    isFork,
    forkCount,
    watchersCount,
    defaultBranch,
    openIssuesCount,
    isPrivate,
    isArchived,
    ownerLogin,
    ownerAvatarUrl,
    cloneUrl,
    gitUrl,
    sshUrl,
    homepage,
  ];

  @override
  String toString() {
    return 'RepositoryModel(name: $name, stars: $stargazersCount, language: $language)';
  }
}
