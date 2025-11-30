import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../bloc/github/github_bloc.dart';
import '../bloc/github/github_event.dart';
import '../bloc/github/github_state.dart';
import '../widgets/error_retry_widget.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/repo_card.dart';

/// Page displaying user repositories with search and filtering.
class ReposPage extends StatefulWidget {
  const ReposPage({super.key});

  @override
  State<ReposPage> createState() => _ReposPageState();
}

class _ReposPageState extends State<ReposPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'updated'; // updated, name, stars

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GithubBloc, GithubState>(
      builder: (context, state) {
        if (state is GithubLoading) {
          return LoadingIndicator(message: state.message);
        }

        if (state is GithubError) {
          return ErrorRetryWidget(
            message: state.message,
            details: state.details,
            onRetry: () {
              if (state.previousState is GithubUserLoaded) {
                final prevState = state.previousState as GithubUserLoaded;
                context.read<GithubBloc>().add(
                      GithubFetchRepos(token: prevState.token),
                    );
              }
            },
          );
        }

        if (state is GithubUserLoaded) {
          final repos = state.repositories ?? [];
          final filteredRepos = _filterAndSortRepos(repos);

          return Column(
            children: [
              // Search and filter bar
              Container(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search repositories...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                    ),
                    const SizedBox(height: AppConstants.smallPadding),
                    Row(
                      children: [
                        Text(
                          'Sort by:',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: AppConstants.smallPadding),
                        Expanded(
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                value: 'updated',
                                label: Text('Updated'),
                              ),
                              ButtonSegment(value: 'name', label: Text('Name')),
                              ButtonSegment(
                                value: 'stars',
                                label: Text('Stars'),
                              ),
                            ],
                            selected: {_sortBy},
                            onSelectionChanged: (Set<String> selected) {
                              setState(() => _sortBy = selected.first);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Repository list
              Expanded(
                child: filteredRepos.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'No repositories found'
                              : 'No repositories match "$_searchQuery"',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          context.read<GithubBloc>().add(
                                GithubFetchRepos(token: state.token),
                              );
                          await Future.delayed(const Duration(seconds: 1));
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(
                            AppConstants.defaultPadding,
                          ),
                          itemCount: filteredRepos.length,
                          itemBuilder: (context, index) {
                            final repo = filteredRepos[index];
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppConstants.defaultPadding,
                              ),
                              child: RepoCard(
                                repository: repo,
                                onTap: () => _launchUrl(repo.htmlUrl),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        }

        return const Center(child: Text('No repository data available'));
      },
    );
  }

  List<dynamic> _filterAndSortRepos(List repos) {
    var filtered = repos;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((repo) {
        final name = repo.name.toLowerCase();
        final description = repo.description?.toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || description.contains(query);
      }).toList();
    }

    // Sort
    switch (_sortBy) {
      case 'name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'stars':
        filtered.sort((a, b) => b.stargazersCount.compareTo(a.stargazersCount));
        break;
      case 'updated':
      default:
        filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
    }

    return filtered;
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
