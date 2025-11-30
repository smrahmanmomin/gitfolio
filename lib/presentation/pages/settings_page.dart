import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/token_service.dart';
import '../bloc/github/github_bloc.dart';
import '../bloc/github/github_event.dart';
import '../bloc/github/github_state.dart';

/// Settings page for app configuration.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: BlocBuilder<GithubBloc, GithubState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Appearance Section
                _buildSectionHeader(context, 'Appearance'),
                Card(
                  child: Column(
                    children: [
                      _buildThemeTile(context),
                      const Divider(height: 1),
                      _buildCompactModeTile(context),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Notifications Section
                _buildSectionHeader(context, 'Notifications'),
                Card(
                  child: Column(
                    children: [
                      _buildNotificationTile(
                        context,
                        'New Followers',
                        'Get notified when someone follows you',
                        true,
                      ),
                      const Divider(height: 1),
                      _buildNotificationTile(
                        context,
                        'Repository Stars',
                        'Get notified about new stars on your repos',
                        true,
                      ),
                      const Divider(height: 1),
                      _buildNotificationTile(
                        context,
                        'Pull Requests',
                        'Get notified about pull request activity',
                        false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Account Section
                if (state is GithubUserLoaded) ...[
                  _buildSectionHeader(context, 'Account'),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(state.user.avatarUrl),
                          ),
                          title: Text(state.user.name ?? state.user.login),
                          subtitle: Text(state.user.email ?? state.user.login),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.info_outline),
                          title: const Text('Token Info'),
                          subtitle: FutureBuilder<int?>(
                            future: TokenService.getTokenAgeDays(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data != null) {
                                return Text('Saved ${snapshot.data} days ago');
                              }
                              return const Text('Token saved locally');
                            },
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(Icons.logout,
                              color: Theme.of(context).colorScheme.error),
                          title: Text(
                            'Logout',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error),
                          ),
                          onTap: () => _showLogoutDialog(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Data & Storage Section
                _buildSectionHeader(context, 'Data & Storage'),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.refresh),
                        title: const Text('Refresh Data'),
                        subtitle: const Text('Reload all GitHub data'),
                        onTap: () {
                          if (state is GithubUserLoaded) {
                            context.read<GithubBloc>().add(
                                  GithubRefreshData(token: state.token),
                                );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Refreshing data...')),
                            );
                          }
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.delete_outline),
                        title: const Text('Clear Cache'),
                        subtitle: const Text('Clear locally cached data'),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cache cleared')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // About Section
                _buildSectionHeader(context, 'About'),
                Card(
                  child: Column(
                    children: [
                      const ListTile(
                        leading: Icon(Icons.info_outline),
                        title: Text('Version'),
                        subtitle: Text('1.0.0'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.code),
                        title: const Text('Source Code'),
                        subtitle: const Text('View on GitHub'),
                        trailing: const Icon(Icons.open_in_new, size: 20),
                        onTap: () {},
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.gavel),
                        title: const Text('Licenses'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          showLicensePage(
                            context: context,
                            applicationName: AppConstants.appName,
                            applicationVersion: '1.0.0',
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildThemeTile(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return ListTile(
      leading: const Icon(Icons.brightness_6),
      title: const Text('Theme'),
      subtitle: Text(isDark ? 'Dark' : 'Light'),
      trailing: const Text('System default'),
    );
  }

  Widget _buildCompactModeTile(BuildContext context) {
    return SwitchListTile(
      secondary: const Icon(Icons.density_medium),
      title: const Text('Compact Mode'),
      subtitle: const Text('Use smaller spacing and sizes'),
      value: false,
      onChanged: (value) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Compact mode ${value ? "enabled" : "disabled"}'),
          ),
        );
      },
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    String title,
    String subtitle,
    bool value,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: (newValue) {
        // TODO: Implement notification preferences
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title ${newValue ? "enabled" : "disabled"}'),
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              // Clear saved token
              await TokenService.clearToken();
              // Logout from BLoC
              if (context.mounted) {
                context.read<GithubBloc>().add(const GithubLogout());
                // Navigate back and then to login
                Navigator.of(context).pop(); // Pop settings
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
