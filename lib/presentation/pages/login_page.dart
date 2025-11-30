import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';

/// Login page with GitHub OAuth integration.
///
/// Displays branding and initiates GitHub OAuth flow.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.largePadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(
                      AppConstants.defaultBorderRadius * 2,
                    ),
                  ),
                  child: Icon(
                    Icons.code,
                    size: 56,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppConstants.largePadding),

                // App name
                Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppConstants.smallPadding),
                Text(
                  'Your GitHub Portfolio',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                ),

                const SizedBox(height: AppConstants.largePadding * 2),

                // Features
                _buildFeature(
                  context,
                  Icons.person,
                  'View Your Profile',
                  'Display your GitHub profile with stats',
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                _buildFeature(
                  context,
                  Icons.book,
                  'Browse Repositories',
                  'Explore all your repositories',
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                _buildFeature(
                  context,
                  Icons.bar_chart,
                  'Track Contributions',
                  'Visualize your coding activity',
                ),

                const SizedBox(height: AppConstants.largePadding * 2),

                // Login button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => _initiateGitHubLogin(context),
                    icon: const Icon(Icons.login, size: 24),
                    label: const Text(
                      'Sign in with GitHub',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.defaultBorderRadius,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppConstants.defaultPadding),

                // Terms and privacy
                Text(
                  'By continuing, you agree to our Terms of Service\nand Privacy Policy',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeature(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(
              AppConstants.defaultBorderRadius,
            ),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: AppConstants.defaultPadding),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _initiateGitHubLogin(BuildContext context) async {
    // Build OAuth URL
    final authUrl = Uri.parse(AppConstants.githubAuthUrl).replace(
      queryParameters: {
        'client_id': AppConstants.githubClientId,
        'redirect_uri': AppConstants.githubRedirectUri,
        'scope': AppConstants.githubScopes.join(' '),
      },
    );

    // Try to launch URL
    if (await canLaunchUrl(authUrl)) {
      await launchUrl(authUrl, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch GitHub login')),
        );
      }
    }
  }
}
