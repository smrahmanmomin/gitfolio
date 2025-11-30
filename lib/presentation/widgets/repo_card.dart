import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/extensions.dart';
import '../../data/models/repository_model.dart';

/// Card displaying GitHub repository information.
///
/// Shows repository name, description, language, stars, forks, and topics.
class RepoCard extends StatelessWidget {
  final RepositoryModel repository;
  final VoidCallback? onTap;

  const RepoCard({super.key, required this.repository, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Repository name
              Row(
                children: [
                  Icon(
                    repository.isFork ? Icons.call_split : Icons.book,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppConstants.smallPadding),
                  Expanded(
                    child: Text(
                      repository.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (repository.isPrivate)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        'Private',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                ],
              ),

              // Description
              if (repository.description != null) ...[
                const SizedBox(height: AppConstants.smallPadding),
                Text(
                  repository.description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: AppConstants.defaultPadding),

              // Stats and metadata
              Wrap(
                spacing: AppConstants.defaultPadding,
                runSpacing: AppConstants.smallPadding,
                children: [
                  // Language
                  if (repository.language != null)
                    _buildMetaItem(
                      context,
                      _getLanguageColor(repository.language!),
                      repository.language!,
                    ),
                  // Stars
                  _buildMetaItem(
                    context,
                    null,
                    '${repository.stargazersCount.formatCompact} ⭐',
                  ),
                  // Forks
                  _buildMetaItem(
                    context,
                    null,
                    '${repository.forksCount.formatCompact} 🍴',
                  ),
                  // Updated
                  _buildMetaItem(
                    context,
                    null,
                    'Updated ${repository.updatedAt.timeAgo}',
                  ),
                ],
              ),

              // Topics
              if (repository.topics.isNotEmpty) ...[
                const SizedBox(height: AppConstants.defaultPadding),
                Wrap(
                  spacing: AppConstants.smallPadding,
                  runSpacing: AppConstants.smallPadding,
                  children: repository.topics.take(5).map((topic) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        topic,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaItem(BuildContext context, Color? dotColor, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dotColor != null) ...[
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
        ],
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Color _getLanguageColor(String language) {
    // Common programming language colors
    final colors = {
      'Dart': const Color(0xFF00B4AB),
      'JavaScript': const Color(0xFFF1E05A),
      'TypeScript': const Color(0xFF3178C6),
      'Python': const Color(0xFF3572A5),
      'Java': const Color(0xFFB07219),
      'Kotlin': const Color(0xFFA97BFF),
      'Swift': const Color(0xFFFF5722),
      'Go': const Color(0xFF00ADD8),
      'Rust': const Color(0xFFDEA584),
      'C++': const Color(0xFFF34B7D),
      'C#': const Color(0xFF178600),
      'Ruby': const Color(0xFF701516),
      'PHP': const Color(0xFF4F5D95),
      'HTML': const Color(0xFFE34C26),
      'CSS': const Color(0xFF563D7C),
    };
    return colors[language] ?? const Color(0xFF858585);
  }
}
