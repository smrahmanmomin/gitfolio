import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/chat_provider.dart';
import '../../core/services/token_service.dart';
import '../bloc/github/github_bloc.dart';
import '../bloc/github/github_event.dart';
import '../bloc/github/github_state.dart';
import '../bloc/settings/settings_cubit.dart';
import '../bloc/settings/settings_state.dart';
import 'chat_assistant_page.dart';

/// Settings page for app configuration.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _localBaseUrlController = TextEditingController();
  final TextEditingController _localChatModelController =
      TextEditingController();
  final TextEditingController _localEmbeddingModelController =
      TextEditingController();
  bool _apiKeySynced = false;
  bool _localConfigSynced = false;
  bool _isApiKeyObscured = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_apiKeySynced) {
      final state = context.read<SettingsCubit>().state;
      _apiKeyController.text = state.openAiApiKey ?? '';
      _apiKeySynced = true;
    }
    if (!_localConfigSynced) {
      final state = context.read<SettingsCubit>().state;
      _syncLocalControllers(state);
      _localConfigSynced = true;
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _localBaseUrlController.dispose();
    _localChatModelController.dispose();
    _localEmbeddingModelController.dispose();
    super.dispose();
  }

  void _syncLocalControllers(SettingsState state) {
    if (_localBaseUrlController.text != state.localLlmBaseUrl) {
      _localBaseUrlController.text = state.localLlmBaseUrl;
    }
    if (_localChatModelController.text != state.localLlmModel) {
      _localChatModelController.text = state.localLlmModel;
    }
    if (_localEmbeddingModelController.text != state.localLlmEmbeddingModel) {
      _localEmbeddingModelController.text = state.localLlmEmbeddingModel;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<SettingsCubit, SettingsState>(
            listenWhen: (previous, current) =>
                previous.openAiApiKey != current.openAiApiKey,
            listener: (context, state) {
              final nextValue = state.openAiApiKey ?? '';
              if (_apiKeyController.text != nextValue) {
                _apiKeyController.text = nextValue;
              }
            },
          ),
          BlocListener<SettingsCubit, SettingsState>(
            listenWhen: (previous, current) =>
                previous.localLlmBaseUrl != current.localLlmBaseUrl ||
                previous.localLlmModel != current.localLlmModel ||
                previous.localLlmEmbeddingModel !=
                    current.localLlmEmbeddingModel,
            listener: (context, state) => _syncLocalControllers(state),
          ),
        ],
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, settingsState) {
            return BlocBuilder<GithubBloc, GithubState>(
              builder: (context, githubState) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(context, 'Appearance'),
                      Card(
                        child: Column(
                          children: [
                            _buildThemeTile(context, settingsState),
                            const Divider(height: 1),
                            _buildCompactModeTile(context, settingsState),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionHeader(context, 'Notifications'),
                      Card(
                        child: Column(
                          children: [
                            _buildNotificationTile(
                              context,
                              'New Followers',
                              'Get notified when someone follows you',
                              settingsState.notifyFollowers,
                              (value) => context
                                  .read<SettingsCubit>()
                                  .setNotificationPreference(
                                    followers: value,
                                  ),
                            ),
                            const Divider(height: 1),
                            _buildNotificationTile(
                              context,
                              'Repository Stars',
                              'Get notified about new stars on your repos',
                              settingsState.notifyStars,
                              (value) => context
                                  .read<SettingsCubit>()
                                  .setNotificationPreference(stars: value),
                            ),
                            const Divider(height: 1),
                            _buildNotificationTile(
                              context,
                              'Pull Requests',
                              'Get notified about pull request activity',
                              settingsState.notifyPullRequests,
                              (value) => context
                                  .read<SettingsCubit>()
                                  .setNotificationPreference(
                                    pullRequests: value,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionHeader(context, 'AI Assistant'),
                      _buildAiAssistantCard(context, settingsState),
                      const SizedBox(height: 24),
                      if (githubState is GithubUserLoaded) ...[
                        _buildSectionHeader(context, 'Account'),
                        Card(
                          child: Column(
                            children: [
                              ListTile(
                                leading: CircleAvatar(
                                  backgroundImage:
                                      NetworkImage(githubState.user.avatarUrl),
                                ),
                                title: Text(githubState.user.name ??
                                    githubState.user.login),
                                subtitle: Text(githubState.user.email ??
                                    githubState.user.login),
                              ),
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(Icons.info_outline),
                                title: const Text('Token Info'),
                                subtitle: FutureBuilder<int?>(
                                  future: TokenService.getTokenAgeDays(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData &&
                                        snapshot.data != null) {
                                      return Text(
                                          'Saved ${snapshot.data} days ago');
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
                                      color:
                                          Theme.of(context).colorScheme.error),
                                ),
                                onTap: () => _showLogoutDialog(context),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      _buildSectionHeader(context, 'Data & Storage'),
                      Card(
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.refresh),
                              title: const Text('Refresh Data'),
                              subtitle: const Text('Reload all GitHub data'),
                              onTap: () {
                                if (githubState is GithubUserLoaded) {
                                  context.read<GithubBloc>().add(
                                        GithubRefreshData(
                                            token: githubState.token),
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
                                  const SnackBar(
                                      content: Text('Cache cleared locally')),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
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
                              onTap: () => _launchExternal(
                                  context, AppConstants.sourceCodeUrl),
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
            );
          },
        ),
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

  Widget _buildThemeTile(BuildContext context, SettingsState settingsState) {
    return ListTile(
      leading: const Icon(Icons.brightness_6),
      title: const Text('Theme'),
      subtitle: Text(SettingsCubit.themeLabel(settingsState.themeMode)),
      trailing: DropdownButton<ThemeMode>(
        value: settingsState.themeMode,
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

  Widget _buildCompactModeTile(
      BuildContext context, SettingsState settingsState) {
    return SwitchListTile(
      secondary: const Icon(Icons.density_medium),
      title: const Text('Compact Mode'),
      subtitle: const Text('Use smaller spacing and sizes'),
      value: settingsState.compactMode,
      onChanged: (value) {
        context.read<SettingsCubit>().toggleCompactMode(value);
      },
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildAiAssistantCard(
    BuildContext context,
    SettingsState settingsState,
  ) {
    final isReady = settingsState.isAssistantReady;
    final provider = settingsState.chatProvider;
    final showLocalServerFields = provider == ChatProvider.local && !kIsWeb;
    final helperText = provider == ChatProvider.local && kIsWeb
        ? 'Runs fully in the browser using TinyLlama and all-MiniLM so it '
            'keeps working on GitHub Pages without any API keys.'
        : provider.helper;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GitFolio Copilot',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose between a hosted API (OpenAI-compatible) or a local LLM '
              'to power the Copilot chatbot. Local mode can run fully '
              'offline in your browser on GitHub Pages, or talk to Ollama / '
              'llama.cpp running on your machine.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Row(
              children: [
                const Icon(Icons.hub_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<ChatProvider>(
                    initialValue: provider,
                    decoration: const InputDecoration(
                      labelText: 'Assistant Provider',
                    ),
                    items: ChatProvider.values
                        .map(
                          (option) => DropdownMenuItem(
                            value: option,
                            child: Text(option.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        context.read<SettingsCubit>().setChatProvider(value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              helperText,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            if (provider == ChatProvider.openAi) ...[
              TextFormField(
                controller: _apiKeyController,
                obscureText: _isApiKeyObscured,
                decoration: InputDecoration(
                  labelText: 'OpenAI API Key',
                  hintText: 'sk-xxxx',
                  prefixIcon: const Icon(Icons.vpn_key),
                  suffixIcon: IconButton(
                    icon: Icon(_isApiKeyObscured
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () {
                      setState(() => _isApiKeyObscured = !_isApiKeyObscured);
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
            ] else if (showLocalServerFields) ...[
              TextFormField(
                controller: _localBaseUrlController,
                decoration: const InputDecoration(
                  labelText: 'Local server URL',
                  hintText: 'http://127.0.0.1:11434',
                  prefixIcon: Icon(Icons.lan_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _localChatModelController,
                decoration: const InputDecoration(
                  labelText: 'Chat model',
                  hintText: 'llama3.1:8b',
                  prefixIcon: Icon(Icons.smart_toy_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _localEmbeddingModelController,
                decoration: const InputDecoration(
                  labelText: 'Embedding model',
                  hintText: 'nomic-embed-text',
                  prefixIcon: Icon(Icons.blur_on_outlined),
                ),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              Text(
                'Tip: run `ollama pull llama3.1` and `ollama pull nomic-embed-text`, '
                'then start Ollama so GitFolio can talk to it.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppConstants.defaultPadding),
            ] else ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.bolt, color: Colors.amber),
                title: const Text('Browser LLM ready'),
                subtitle: const Text(
                  'TinyLlama (1.1B) + MiniLM embeddings run entirely in-browser. '
                  'Expect a short download the first time you open Copilot.',
                ),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
            ],
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.save_outlined),
                    label: Text(
                      provider == ChatProvider.openAi
                          ? 'Save API Key'
                          : showLocalServerFields
                              ? 'Save Local Config'
                              : 'Prime Browser Model',
                    ),
                    onPressed: () async {
                      if (provider == ChatProvider.openAi) {
                        await context
                            .read<SettingsCubit>()
                            .saveOpenAiKey(_apiKeyController.text);
                      } else if (showLocalServerFields) {
                        await context.read<SettingsCubit>().saveLocalLlmConfig(
                              baseUrl: _localBaseUrlController.text,
                              chatModel: _localChatModelController.text,
                              embeddingModel:
                                  _localEmbeddingModelController.text,
                            );
                      } else {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'The browser model downloads automatically '
                              'the first time you open Copilot.',
                            ),
                          ),
                        );
                        return;
                      }
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            provider == ChatProvider.openAi
                                ? 'Assistant key saved'
                                : showLocalServerFields
                                    ? 'Local model settings saved'
                                    : 'Browser model primed',
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.smart_toy_outlined),
                    label: Text(isReady ? 'Open Copilot' : 'Complete setup'),
                    onPressed: isReady
                        ? () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ChatAssistantPage(),
                              ),
                            );
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
