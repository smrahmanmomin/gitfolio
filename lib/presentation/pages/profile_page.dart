import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/extensions.dart';
import '../bloc/github/github_bloc.dart';
import '../bloc/github/github_event.dart';
import '../bloc/github/github_state.dart';
import '../widgets/contribution_heatmap.dart';
import '../widgets/error_retry_widget.dart';
import '../widgets/loading_indicator.dart';

/// Profile page displaying user information and stats.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

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
              // Try to get token from previous state
              if (state.previousState is GithubUserLoaded) {
                final prevState = state.previousState as GithubUserLoaded;
                context.read<GithubBloc>().add(
                      GithubFetchUser(token: prevState.token),
                    );
              }
            },
          );
        }

        if (state is GithubUserLoaded) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<GithubBloc>().add(
                    GithubRefreshData(token: state.token),
                  );
              // Wait a bit for the refresh to complete
              await Future.delayed(const Duration(seconds: 1));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile header
                  _buildProfileHeader(context, state),
                  const SizedBox(height: AppConstants.largePadding),

                  // Stats
                  _buildStatsRow(context, state),
                  const SizedBox(height: AppConstants.largePadding),

                  // Bio
                  if (state.user.bio != null) ...[
                    _buildSection(
                      context,
                      'About',
                      child: Text(
                        state.user.bio!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: AppConstants.largePadding),
                  ],

                  // Additional info
                  _buildAdditionalInfo(context, state),
                  const SizedBox(height: AppConstants.largePadding),

                  // Contributions
                  if (state.contributions != null)
                    ContributionHeatmap(contributionData: state.contributions),
                ],
              ),
            ),
          );
        }

        return const Center(child: Text('No user data available'));
      },
    );
  }

  Widget _buildProfileHeader(BuildContext context, GithubUserLoaded state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: Column(
          children: [
            CircleAvatar(
              radius: AppConstants.largeAvatarSize,
              backgroundImage: NetworkImage(state.user.avatarUrl),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            if (state.user.name != null)
              Text(
                state.user.name!,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
            Text(
              '@${state.user.login}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            ElevatedButton.icon(
              onPressed: () => _launchUrl(state.user.htmlUrl),
              icon: const Icon(Icons.open_in_new, size: 20),
              label: const Text('View on GitHub'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, GithubUserLoaded state) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            Icons.book,
            state.user.publicRepos.formatCompact,
            'Repositories',
          ),
        ),
        const SizedBox(width: AppConstants.defaultPadding),
        Expanded(
          child: _buildStatCard(
            context,
            Icons.people,
            state.user.followers.formatCompact,
            'Followers',
          ),
        ),
        const SizedBox(width: AppConstants.defaultPadding),
        Expanded(
          child: _buildStatCard(
            context,
            Icons.person_add,
            state.user.following.formatCompact,
            'Following',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title, {
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfo(BuildContext context, GithubUserLoaded state) {
    final items = <Widget>[];

    if (state.user.company != null) {
      items.add(_buildInfoItem(context, Icons.business, state.user.company!));
    }

    if (state.user.location != null) {
      items.add(
        _buildInfoItem(context, Icons.location_on, state.user.location!),
      );
    }

    if (state.user.email != null) {
      items.add(_buildInfoItem(context, Icons.email, state.user.email!));
    }

    if (state.user.blog != null && state.user.blog!.isNotEmpty) {
      items.add(
        _buildInfoItem(
          context,
          Icons.link,
          state.user.blog!,
          onTap: () => _launchUrl(state.user.blog!),
        ),
      );
    }

    items.add(
      _buildInfoItem(
        context,
        Icons.calendar_today,
        'Joined ${state.user.createdAt.formattedDate}',
      ),
    );

    if (items.isEmpty) return const SizedBox.shrink();

    return _buildSection(
      context,
      'Information',
      child: Column(children: items),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    IconData icon,
    String text, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppConstants.smallPadding,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
            const SizedBox(width: AppConstants.defaultPadding),
            Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
            ),
            if (onTap != null)
              Icon(
                Icons.open_in_new,
                size: 16,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
