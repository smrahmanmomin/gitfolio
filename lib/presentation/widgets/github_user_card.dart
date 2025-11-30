import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/extensions.dart';
import '../../data/models/github_user_model.dart';

/// Beautiful card displaying GitHub user profile information.
///
/// Shows avatar, name, username, bio, and key statistics.
class GithubUserCard extends StatelessWidget {
  final GithubUserModel user;
  final VoidCallback? onTap;

  const GithubUserCard({super.key, required this.user, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            children: [
              // Avatar and basic info
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: AppConstants.largeAvatarSize / 2,
                    backgroundImage: NetworkImage(user.avatarUrl),
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),
                  const SizedBox(width: AppConstants.defaultPadding),
                  // Name and username
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (user.name != null)
                          Text(
                            user.name!,
                            style: Theme.of(context).textTheme.titleLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                        Text(
                          '@${user.login}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Bio
              if (user.bio != null) ...[
                const SizedBox(height: AppConstants.defaultPadding),
                Text(
                  user.bio!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Stats
              const SizedBox(height: AppConstants.defaultPadding),
              const Divider(),
              const SizedBox(height: AppConstants.smallPadding),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat(
                    context,
                    Icons.book,
                    user.publicRepos.formatCompact,
                    'Repos',
                  ),
                  _buildStat(
                    context,
                    Icons.people,
                    user.followers.formatCompact,
                    'Followers',
                  ),
                  _buildStat(
                    context,
                    Icons.person_add,
                    user.following.formatCompact,
                    'Following',
                  ),
                ],
              ),

              // Additional info
              if (user.location != null || user.company != null) ...[
                const SizedBox(height: AppConstants.defaultPadding),
                const Divider(),
                const SizedBox(height: AppConstants.smallPadding),
                Wrap(
                  spacing: AppConstants.defaultPadding,
                  runSpacing: AppConstants.smallPadding,
                  children: [
                    if (user.location != null)
                      _buildInfoChip(
                        context,
                        Icons.location_on,
                        user.location!,
                      ),
                    if (user.company != null)
                      _buildInfoChip(context, Icons.business, user.company!),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String text) {
    return Chip(
      avatar: Icon(
        icon,
        size: 16,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      ),
      label: Text(text, style: Theme.of(context).textTheme.bodySmall),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
