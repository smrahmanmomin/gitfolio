import 'package:equatable/equatable.dart';

/// Data model representing a GitHub user.
///
/// This model corresponds to the GitHub User API response and includes
/// serialization methods for converting between JSON and Dart objects.
class GithubUserModel extends Equatable {
  /// The user's login username
  final String login;

  /// The user's unique ID
  final int id;

  /// URL to the user's avatar image
  final String avatarUrl;

  /// The user's display name
  final String? name;

  /// The user's bio/description
  final String? bio;

  /// The user's blog/website URL
  final String? blog;

  /// The user's location
  final String? location;

  /// The user's public email address
  final String? email;

  /// Number of public repositories
  final int publicRepos;

  /// Number of followers
  final int followers;

  /// Number of users being followed
  final int following;

  /// The date the account was created
  final DateTime createdAt;

  /// The date the account was last updated
  final DateTime updatedAt;

  /// The user's company
  final String? company;

  /// Whether the user is hireable
  final bool? hireable;

  /// The user's Twitter username
  final String? twitterUsername;

  /// URL to the user's GitHub profile
  final String htmlUrl;

  /// The user's public gists count
  final int? publicGists;

  const GithubUserModel({
    required this.login,
    required this.id,
    required this.avatarUrl,
    this.name,
    this.bio,
    this.blog,
    this.location,
    this.email,
    required this.publicRepos,
    required this.followers,
    required this.following,
    required this.createdAt,
    required this.updatedAt,
    this.company,
    this.hireable,
    this.twitterUsername,
    required this.htmlUrl,
    this.publicGists,
  });

  /// Creates a [GithubUserModel] from a JSON map.
  ///
  /// Example:
  /// ```dart
  /// final user = GithubUserModel.fromJson({
  ///   'login': 'octocat',
  ///   'id': 1,
  ///   'avatar_url': 'https://github.com/images/error/octocat_happy.gif',
  ///   // ... other fields
  /// });
  /// ```
  factory GithubUserModel.fromJson(Map<String, dynamic> json) {
    return GithubUserModel(
      login: json['login'] as String,
      id: json['id'] as int,
      avatarUrl: json['avatar_url'] as String,
      name: json['name'] as String?,
      bio: json['bio'] as String?,
      blog: json['blog'] as String?,
      location: json['location'] as String?,
      email: json['email'] as String?,
      publicRepos: json['public_repos'] as int? ?? 0,
      followers: json['followers'] as int? ?? 0,
      following: json['following'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      company: json['company'] as String?,
      hireable: json['hireable'] as bool?,
      twitterUsername: json['twitter_username'] as String?,
      htmlUrl: json['html_url'] as String,
      publicGists: json['public_gists'] as int?,
    );
  }

  /// Converts this [GithubUserModel] to a JSON map.
  ///
  /// Example:
  /// ```dart
  /// final json = user.toJson();
  /// // json = {'login': 'octocat', 'id': 1, ...}
  /// ```
  Map<String, dynamic> toJson() {
    return {
      'login': login,
      'id': id,
      'avatar_url': avatarUrl,
      'name': name,
      'bio': bio,
      'blog': blog,
      'location': location,
      'email': email,
      'public_repos': publicRepos,
      'followers': followers,
      'following': following,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'company': company,
      'hireable': hireable,
      'twitter_username': twitterUsername,
      'html_url': htmlUrl,
      'public_gists': publicGists,
    };
  }

  /// Creates a copy of this [GithubUserModel] with the given fields replaced.
  GithubUserModel copyWith({
    String? login,
    int? id,
    String? avatarUrl,
    String? name,
    String? bio,
    String? blog,
    String? location,
    String? email,
    int? publicRepos,
    int? followers,
    int? following,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? company,
    bool? hireable,
    String? twitterUsername,
    String? htmlUrl,
    int? publicGists,
  }) {
    return GithubUserModel(
      login: login ?? this.login,
      id: id ?? this.id,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      blog: blog ?? this.blog,
      location: location ?? this.location,
      email: email ?? this.email,
      publicRepos: publicRepos ?? this.publicRepos,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      company: company ?? this.company,
      hireable: hireable ?? this.hireable,
      twitterUsername: twitterUsername ?? this.twitterUsername,
      htmlUrl: htmlUrl ?? this.htmlUrl,
      publicGists: publicGists ?? this.publicGists,
    );
  }

  @override
  List<Object?> get props => [
        login,
        id,
        avatarUrl,
        name,
        bio,
        blog,
        location,
        email,
        publicRepos,
        followers,
        following,
        createdAt,
        updatedAt,
        company,
        hireable,
        twitterUsername,
        htmlUrl,
        publicGists,
      ];

  @override
  String toString() {
    return 'GithubUserModel(login: $login, id: $id, name: $name, followers: $followers)';
  }
}
