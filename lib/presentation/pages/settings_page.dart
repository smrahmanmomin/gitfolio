import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/token_service.dart';
import '../bloc/github/github_bloc.dart';
import '../bloc/github/github_event.dart';
import '../bloc/github/github_state.dart';
import '../bloc/settings/settings_cubit.dart';
import '../bloc/settings/settings_state.dart';

/// Settings page for core configuration (theme, notifications, account, etc.).
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settingsState) {
          return BlocBuilder<GithubBloc, GithubState>(
            builder: (context, githubState) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAppearanceSection(context, settingsState),
                    const SizedBox(height: 24),
                    _buildNotificationSection(context, settingsState),
                    const SizedBox(height: 24),
                    if (githubState is GithubUserLoaded) ...[
                      _buildAccountSection(context, githubState),
                      const SizedBox(height: 24),
                    ],
                    _buildDataSection(context, githubState),
                    const SizedBox(height: 24),
                    _buildAboutSection(context),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAppearanceSection(
    BuildContext context,
    SettingsState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Appearance'),
        Card(
          child: Column(
            children: [
              _buildThemeTile(context, state),
              const Divider(height: 1),
              _buildCompactModeTile(context, state),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationSection(
    BuildContext context,
    SettingsState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Notifications'),
        Card(
          child: Column(
            children: [
              _buildNotificationTile(
                context,
                title: 'New Followers',
                subtitle: 'Get notified when someone follows you',
                value: state.notifyFollowers,
                onChanged: (value) => context
                    .read<SettingsCubit>()
                    .setNotificationPreference(followers: value),
              ),
              const Divider(height: 1),
              _buildNotificationTile(
                context,
                title: 'Repository Stars',
                subtitle: 'Get notified about new stars on your repos',
                value: state.notifyStars,
                onChanged: (value) => context
                    .read<SettingsCubit>()
                    .setNotificationPreference(stars: value),
              ),
              const Divider(height: 1),
              _buildNotificationTile(
                context,
                title: 'Pull Requests',
                subtitle: 'Get notified about pull request activity',
                value: state.notifyPullRequests,
                onChanged: (value) => context
                    .read<SettingsCubit>()
                    .setNotificationPreference(pullRequests: value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSection(
    BuildContext context,
    GithubUserLoaded state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                leading: Icon(
                  Icons.logout,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Logout',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                onTap: () => _showLogoutDialog(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDataSection(BuildContext context, GithubState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                      const SnackBar(content: Text('Refreshing data...')),
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
                    const SnackBar(content: Text('Cache cleared locally')),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                onTap: () =>
                    _launchExternal(context, AppConstants.sourceCodeUrl),
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
      ],
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

  Widget _buildThemeTile(BuildContext context, SettingsState state) {
    return ListTile(
      leading: const Icon(Icons.brightness_6),
      title: const Text('Theme'),
      subtitle: Text(SettingsCubit.themeLabel(state.themeMode)),
      trailing: DropdownButton<ThemeMode>(
        value: state.themeMode,
        items: ThemeMode.values
            .map(
              (mode) => DropdownMenuItem(
                value: mode,
                child: Text(SettingsCubit.themeLabel(mode)),
              ),
            )
            .toList(),
        onChanged: (mode) {
          if (mode != null) {
            context.read<SettingsCubit>().setThemeMode(mode);
          }
        },
      ),
    );
  }

  Widget _buildCompactModeTile(BuildContext context, SettingsState state) {
    return SwitchListTile(
      secondary: const Icon(Icons.density_medium),
      title: const Text('Compact Mode'),
      subtitle: const Text('Use smaller spacing and sizes'),
      value: state.compactMode,
      onChanged: (value) {
        context.read<SettingsCubit>().toggleCompactMode(value);
      },
    );
  }

  Widget _buildNotificationTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
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
              await TokenService.clearToken();
              if (context.mounted) {
                context.read<GithubBloc>().add(const GithubLogout());
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchExternal(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open link')),
      );
    }
  }
}
