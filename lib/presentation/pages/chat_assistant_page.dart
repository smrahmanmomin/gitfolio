import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';
import '../../core/services/chat_assistant_service.dart';
import '../../data/models/github_user_model.dart';
import '../../data/models/repository_model.dart';
import '../bloc/github/github_bloc.dart';
import '../bloc/github/github_event.dart';
import '../bloc/github/github_state.dart';
import '../bloc/settings/settings_cubit.dart';
import '../bloc/settings/settings_state.dart';

class ChatAssistantPage extends StatefulWidget {
  const ChatAssistantPage({super.key});

  @override
  State<ChatAssistantPage> createState() => _ChatAssistantPageState();
}

class _ChatAssistantPageState extends State<ChatAssistantPage> {
  late ChatAssistantService _assistantService;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isSending = false;
  bool _serviceInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_serviceInitialized) {
      final client = context.read<http.Client>();
      _assistantService = ChatAssistantService(client: client);
      _serviceInitialized = true;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsCubit>().state;
    final githubState = context.watch<GithubBloc>().state;
    final repos = _extractRepositories(githubState);
    final user = githubState is GithubUserLoaded ? githubState.user : null;
    final templateDescription = settingsState.selectedTemplate != null
        ? SettingsCubit.templateDescription(settingsState.selectedTemplate!)
        : null;

    final readinessBanner = _buildReadinessBanner(settingsState, githubState);

    return Scaffold(
      appBar: AppBar(
        title: const Text('GitFolio Copilot'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Tooltip(
              message: 'Powered by ${AppConstants.openAiChatModel}',
              child: const Icon(Icons.bolt_outlined),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (readinessBanner != null) readinessBanner,
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState(settingsState)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _ChatBubble(message: message);
                    },
                  ),
          ),
          _buildComposer(
            settingsState: settingsState,
            repos: repos,
            user: user,
            templateDescription: templateDescription,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(SettingsState settingsState) {
    final hasKey = settingsState.hasOpenAiKey;
    final text = hasKey
        ? 'Ask a question about your GitHub work to get started.'
        : 'Add your OpenAI API key in Settings to enable Copilot.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(hasKey ? Icons.question_answer : Icons.key_off, size: 56),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer({
    required SettingsState settingsState,
    required List<RepositoryModel> repos,
    required GithubUserModel? user,
    required String? templateDescription,
  }) {
    final canSend =
        settingsState.hasOpenAiKey && repos.isNotEmpty && !_isSending;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: settingsState.hasOpenAiKey
                      ? 'Ask about your repos, roadmap, or projects'
                      : 'Save an API key in Settings to start chatting',
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filled(
              onPressed: canSend
                  ? () => _sendMessage(
                        repos: repos,
                        user: user,
                        settingsState: settingsState,
                        templateDescription: templateDescription,
                      )
                  : null,
              icon: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildReadinessBanner(
    SettingsState settingsState,
    GithubState githubState,
  ) {
    if (!settingsState.hasOpenAiKey) {
      return _InfoBanner(
        icon: Icons.key_off,
        message:
            'Add your OpenAI API key in Settings > AI Assistant to enable Copilot.',
        actionLabel: 'Open Settings',
        onPressed: () => Navigator.of(context).pop(),
      );
    }

    if (githubState is! GithubUserLoaded ||
        (githubState.repositories == null ||
            githubState.repositories!.isEmpty)) {
      return _InfoBanner(
        icon: Icons.cloud_download_outlined,
        message: 'Load your repositories to give Copilot context.',
        actionLabel: 'Refresh',
        onPressed: () {
          if (githubState is GithubUserLoaded) {
            context
                .read<GithubBloc>()
                .add(GithubRefreshData(token: githubState.token));
          }
        },
      );
    }

    return null;
  }

  List<RepositoryModel> _extractRepositories(GithubState state) {
    if (state is GithubUserLoaded) {
      return List<RepositoryModel>.from(state.repositories ?? const []);
    }
    return const [];
  }

  Future<void> _sendMessage({
    required List<RepositoryModel> repos,
    required GithubUserModel? user,
    required SettingsState settingsState,
    required String? templateDescription,
  }) async {
    final query = _messageController.text.trim();
    if (query.isEmpty || _isSending) return;

    setState(() {
      _messages.add(_ChatMessage(role: ChatRole.user, content: query));
      _isSending = true;
      _messageController.clear();
    });

    try {
      final response = await _assistantService.askCopilot(
        apiKey: settingsState.openAiApiKey!,
        question: query,
        repositories: repos,
        user: user,
        selectedTemplateDescription: templateDescription,
      );
      setState(() {
        _messages
            .add(_ChatMessage(role: ChatRole.assistant, content: response));
      });
    } on ChatAssistantException catch (e) {
      _appendSystemMessage(e.message);
    } catch (e) {
      _appendSystemMessage('Copilot failed: $e');
    } finally {
      setState(() => _isSending = false);
      _scrollToBottom();
    }
  }

  void _appendSystemMessage(String message) {
    setState(() {
      _messages.add(_ChatMessage(role: ChatRole.system, content: message));
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: AppConstants.defaultAnimationDuration,
          curve: Curves.easeOut,
        );
      }
    });
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final alignment = switch (message.role) {
      ChatRole.user => Alignment.centerRight,
      ChatRole.assistant => Alignment.centerLeft,
      ChatRole.system => Alignment.center,
    };
    final bubbleColor = switch (message.role) {
      ChatRole.user => Theme.of(context).colorScheme.primary,
      ChatRole.assistant =>
        Theme.of(context).colorScheme.surfaceContainerHighest,
      ChatRole.system => Theme.of(context).colorScheme.surface,
    };
    final textColor = message.role == ChatRole.user
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSurface;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: SelectableText(
          message.content,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: textColor, height: 1.4),
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onPressed,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            if (actionLabel != null)
              TextButton(onPressed: onPressed, child: Text(actionLabel!)),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final ChatRole role;
  final String content;

  _ChatMessage({required this.role, required this.content});
}

enum ChatRole { user, assistant, system }
