import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/github/github_bloc.dart';
import '../bloc/github/github_state.dart';

/// Analytics page displaying GitHub statistics and insights.
///
/// This page shows comprehensive analytics including:
/// - Repository statistics (total, stars, forks, languages)
/// - Profile statistics (followers, following, repos, gists)
/// - Language distribution
/// - Top repositories
class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<GithubBloc, GithubState>(
        builder: (context, state) {
          // Show loading for all non-loaded states
          if (state is GithubLoading ||
              state is GithubInitial ||
              state is GithubAuthenticated) {
            final message =
                state is GithubLoading ? state.message : 'Loading analytics...';
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(message),
                ],
              ),
            );
          }

          if (state is GithubError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 64, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 16),
                  Text(state.message),
                ],
              ),
            );
          }

          if (state is! GithubUserLoaded) {
            return const Center(
              child: Text('No data available'),
            );
          }

          return CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 120,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text('Analytics'),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 60.0),
                        child: Text(
                          'Your GitHub Statistics',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Content
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Repository Stats Cards
                    _buildStatsCards(state.repositories ?? []),
                    const SizedBox(height: 24),

                    // Profile Stats
                    _buildProfileStats(state.user),
                    const SizedBox(height: 24),

                    // Language Distribution
                    _buildLanguageDistribution(state.repositories ?? []),
                    const SizedBox(height: 24),

                    // Top Repositories
                    _buildRepositoryStats(state.repositories ?? []),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Builds the top stats cards row showing repository overview.
  Widget _buildStatsCards(List<dynamic> repositories) {
    // Calculate statistics
    final totalRepos = repositories.length;
    final totalStars = repositories.fold<int>(
      0,
      (sum, repo) => sum + (repo.stargazersCount as int? ?? 0),
    );
    final totalForks = repositories.fold<int>(
      0,
      (sum, repo) => sum + (repo.forksCount as int? ?? 0),
    );

    // Count unique languages
    final languages = <String>{};
    for (var repo in repositories) {
      final language = repo.language;
      if (language != null && language.toString().isNotEmpty) {
        languages.add(language.toString());
      }
    }
    final totalLanguages = languages.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 600;

        if (isWideScreen) {
          return Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Repositories',
                  totalRepos.toString(),
                  Icons.folder,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Total Stars',
                  totalStars.toString(),
                  Icons.star,
                  Colors.amber,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Total Forks',
                  totalForks.toString(),
                  Icons.call_split,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Languages',
                  totalLanguages.toString(),
                  Icons.code,
                  Colors.purple,
                ),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Repositories',
                      totalRepos.toString(),
                      Icons.folder,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Total Stars',
                      totalStars.toString(),
                      Icons.star,
                      Colors.amber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Forks',
                      totalForks.toString(),
                      Icons.call_split,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Languages',
                      totalLanguages.toString(),
                      Icons.code,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
            ],
          );
        }
      },
    );
  }

  /// Builds a single stat card.
  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the profile stats card.
  Widget _buildProfileStats(dynamic user) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildProfileStat(
                    'Followers',
                    user.followers.toString(),
                    Icons.people,
                  ),
                ),
                Expanded(
                  child: _buildProfileStat(
                    'Following',
                    user.following.toString(),
                    Icons.person_add,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildProfileStat(
                    'Public Repos',
                    user.publicRepos.toString(),
                    Icons.folder_open,
                  ),
                ),
                Expanded(
                  child: _buildProfileStat(
                    'Public Gists',
                    (user.publicGists ?? 0).toString(),
                    Icons.description,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a single profile stat item.
  Widget _buildProfileStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.blue),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  /// Builds the language distribution chart.
  Widget _buildLanguageDistribution(List<dynamic> repositories) {
    // Calculate language statistics
    final languageStats = <String, int>{};
    for (var repo in repositories) {
      final language = repo.language;
      if (language != null && language.toString().isNotEmpty) {
        final langStr = language.toString();
        languageStats[langStr] = (languageStats[langStr] ?? 0) + 1;
      }
    }

    // Sort by count and take top 10
    final sortedLanguages = languageStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topLanguages = sortedLanguages.take(10).toList();

    if (topLanguages.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxCount = topLanguages.first.value;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Language Distribution',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...topLanguages.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${entry.value} repos',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: entry.value / maxCount,
                      minHeight: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getLanguageColor(entry.key),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Builds the top repositories section.
  Widget _buildRepositoryStats(List<dynamic> repositories) {
    // Sort repositories by stars and take top 5
    final sortedRepos = List.from(repositories)
      ..sort((a, b) => (b.stargazersCount as int? ?? 0)
          .compareTo(a.stargazersCount as int? ?? 0));
    final topRepos = sortedRepos.take(5).toList();

    if (topRepos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Repositories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...topRepos.asMap().entries.map((entry) {
              final index = entry.key;
              final repo = entry.value;
              return Column(
                children: [
                  if (index > 0) const Divider(height: 24),
                  _buildRepositoryCard(repo),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Builds a single repository card.
  Widget _buildRepositoryCard(dynamic repo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                repo.name.toString(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            if (repo.language != null && repo.language.toString().isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getLanguageColor(repo.language.toString())
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  repo.language.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: _getLanguageColor(repo.language.toString()),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        if (repo.description != null && repo.description.toString().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              repo.description.toString(),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.star, size: 16, color: Colors.amber),
            const SizedBox(width: 4),
            Text(
              repo.stargazersCount.toString(),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.call_split, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              repo.forksCount.toString(),
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  /// Gets a color for a given programming language.
  Color _getLanguageColor(String language) {
    final colors = {
      'Dart': const Color(0xFF0175C2),
      'JavaScript': const Color(0xFFF7DF1E),
      'TypeScript': const Color(0xFF3178C6),
      'Python': const Color(0xFF3776AB),
      'Java': const Color(0xFFB07219),
      'Kotlin': const Color(0xFFA97BFF),
      'Swift': const Color(0xFFFA7343),
      'Go': const Color(0xFF00ADD8),
      'Rust': const Color(0xFFDEA584),
      'C++': const Color(0xFFF34B7D),
      'C#': const Color(0xFF178600),
      'Ruby': const Color(0xFF701516),
      'PHP': const Color(0xFF4F5D95),
      'HTML': const Color(0xFFE34C26),
      'CSS': const Color(0xFF563D7C),
      'Shell': const Color(0xFF89E051),
    };

    return colors[language] ?? Colors.grey;
  }
}
