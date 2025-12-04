import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import '../../../core/themes/app_theme.dart';
import '../../../data/github/github_cache.dart';
import '../../../data/models/github_user_model.dart';
import '../../../data/models/repository_model.dart';
import '../../../data/portfolio/datasources/export_service.dart';
import '../../../domain/portfolio/portfolio_entity.dart';
import '../../bloc/github/github_bloc.dart';
import '../../bloc/github/github_event.dart';
import '../../bloc/github/github_state.dart';
import '../providers/portfolio_editor_session.dart';
import '../bloc/portfolio_bloc.dart';
import '../bloc/portfolio_event.dart';
import '../bloc/portfolio_state.dart';
import '../widgets/analytics/contribution_heatmap.dart';
import '../widgets/analytics/language_distribution_chart.dart';
import '../widgets/analytics/repository_metrics.dart';
import '../widgets/analytics/skill_growth_timeline.dart';
import '../widgets/export_modal.dart';
import '../utils/preview_saver.dart';
import '../widgets/share/share_portfolio_sheet.dart';
import '../widgets/templates/creative_portfolio_template.dart';
import '../widgets/templates/modern_developer_template.dart';
import '../widgets/templates/professional_resume_template.dart';

class PortfolioEditorPage extends StatefulWidget {
  const PortfolioEditorPage({super.key});

  @override
  State<PortfolioEditorPage> createState() => _PortfolioEditorPageState();
}

class _PortfolioEditorPageState extends State<PortfolioEditorPage> {
  static bool _hiveReady = false;
  static const _colorChoices = <Color>[
    AppTheme.gitHubPurple,
    AppTheme.gitHubOrange,
    AppTheme.gitHubYellow,
    Colors.blue,
    Colors.indigo,
    Colors.teal,
    Colors.pinkAccent,
    Colors.green,
  ];
  static const _animationDuration = Duration(milliseconds: 250);

  late final Future<void> _initFuture;
  late PortfolioExportService _exportService;
  PortfolioConfig? _editingConfig;
  String? _activeUserId;
  bool _wasMobileLayout = false;
  bool _wasSaving = false;
  Color _primaryColor = AppTheme.gitHubPurple;
  Color _secondaryColor = AppTheme.gitHubOrange;
  double _zoomValue = 1.0;
  final GlobalKey _previewBoundaryKey = GlobalKey();
  GithubUserModel? _cachedUser;
  List<RepositoryModel> _cachedRepos = const <RepositoryModel>[];
  String? _lastGithubToken;
  late GithubCache _githubCache;
  bool _offlineMode = false;
  late final PortfolioEditorSession _session = PortfolioEditorSession();

  final ValueNotifier<_PreviewData> _previewNotifier =
      ValueNotifier<_PreviewData>(_PreviewData.initial());
  final ValueNotifier<bool> _previewVisibilityNotifier =
      ValueNotifier<bool>(true);
  final TextEditingController _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initFuture = _prepareDependencies();
    _bioController.addListener(_handleBioChanged);
  }

  Future<void> _prepareDependencies() async {
    if (!_hiveReady) {
      await Hive.initFlutter();
      _hiveReady = true;
    }
    _exportService = const PortfolioExportService();
    _githubCache = await GithubCache.create();
    _cachedUser = _githubCache.readUser();
    _cachedRepos = _githubCache.readRepos();
  }

  @override
  void dispose() {
    _bioController.removeListener(_handleBioChanged);
    _bioController.dispose();
    _previewNotifier.dispose();
    _previewVisibilityNotifier.dispose();
    _session.dispose();
    super.dispose();
  }

  void _handleBioChanged() {
    _updatePreview(bio: _bioController.text);
  }

  void _cacheGithubPayload(GithubUserLoaded state) {
    _cachedUser = state.user;
    if (state.repositories != null) {
      _cachedRepos = state.repositories!;
      unawaited(_githubCache.persistRepos(state.repositories!));
    }
    _lastGithubToken = state.token;
    unawaited(_githubCache.persistUser(state.user));
  }

  void _retryGithubSync() {
    final token = _lastGithubToken;
    if (token == null) return;
    context.read<GithubBloc>().add(GithubRefreshData(token: token));
  }

  void _dispatchPortfolioEvent(PortfolioEvent event) {
    if (!mounted) return;
    context.read<PortfolioBloc>().add(event);
  }

  void _updatePreview({
    PortfolioConfig? config,
    bool configChanged = false,
    Color? primaryColor,
    Color? secondaryColor,
    String? bio,
    double? zoom,
    bool? processing,
  }) {
    final current = _previewNotifier.value;
    _previewNotifier.value = _PreviewData(
      config: configChanged ? config : (config ?? current.config),
      primaryColor: primaryColor ?? current.primaryColor,
      secondaryColor: secondaryColor ?? current.secondaryColor,
      bioOverride: bio ?? current.bioOverride,
      zoom: zoom ?? current.zoom,
      processing: processing ?? current.processing,
    );
  }

  void _maybeRequestConfig(GithubState state) {
    GithubUserModel? targetUser;
    if (state is GithubUserLoaded) {
      _cacheGithubPayload(state);
      targetUser = state.user;
      _offlineMode = false;
    } else if (state is GithubError && state.errorType == 'network') {
      targetUser = _cachedUser;
      _offlineMode = true;
    } else if (_cachedUser != null && _editingConfig == null) {
      targetUser = _cachedUser;
    }

    if (targetUser == null) {
      if (_editingConfig == null) {
        _activeUserId = null;
        _updatePreview(config: null, configChanged: true, processing: true);
      }
      return;
    }

    final userId = targetUser.login;
    if (_activeUserId == userId && !_offlineMode) {
      return;
    }
    _activeUserId = userId;
    _editingConfig = null;
    _bioController.clear();
    _updatePreview(config: null, configChanged: true, processing: true);
    _dispatchPortfolioEvent(PortfolioLoadRequested(userId));
  }

  void _handlePortfolioState(BuildContext context, PortfolioState state) {
    final isProcessing = state is PortfolioLoading || state.isSaving;
    _updatePreview(processing: isProcessing);
    _session.updateSaving(state.isSaving);
    final config = state.config;

    if (config != null) {
      if (_editingConfig == null) {
        _session.bootstrap(config);
      } else {
        _session.registerRemoteSnapshot(config);
      }
      if (config != _editingConfig) {
        setState(() {
          _editingConfig = config;
        });
        _updatePreview(
          config: config,
          configChanged: true,
          processing: isProcessing,
        );
      }
    }

    if (state is PortfolioError) {
      final snackBar = SnackBar(
        content: Text('Unable to save portfolio: ${state.message}'),
        action: _lastGithubToken != null
            ? SnackBarAction(
                label: 'Retry',
                onPressed: _retryGithubSync,
              )
            : null,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }

    if (state is PortfolioLoaded && state.exportPath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export ready: ${state.exportPath}')),
      );
    }

    if (_wasSaving && !state.isSaving && config != null) {
      _session.markSaved(config);
    }
    _wasSaving = state.isSaving;
  }

  void _mutateConfig(
    PortfolioConfig Function(PortfolioConfig current) cb, {
    bool trackHistory = true,
  }) {
    final current = _editingConfig;
    if (current == null) return;
    final updated = cb(current);
    setState(() {
      _editingConfig = updated;
    });
    _updatePreview(config: updated, configChanged: true);
    if (trackHistory) {
      _session.registerChange(updated);
    }
  }

  void _handleUndo() {
    final previous = _session.undo();
    if (previous != null) {
      _applyHistoryConfig(previous);
    }
  }

  void _handleRedo() {
    final next = _session.redo();
    if (next != null) {
      _applyHistoryConfig(next);
    }
  }

  void _applyHistoryConfig(PortfolioConfig config) {
    setState(() {
      _editingConfig = config;
    });
    _updatePreview(config: config, configChanged: true);
  }

  void _clearHistory() {
    _session.clearHistory();
  }

  void _resolveConflict(bool acceptRemote) {
    final resolved = _session.resolveConflict(acceptRemote: acceptRemote);
    if (resolved != null) {
      _applyHistoryConfig(resolved);
    }
  }

  void _onTemplateChanged(PortfolioTemplate template) {
    _mutateConfig((current) => current.copyWith(template: template));
  }

  void _onSectionChanged(bool? value, PortfolioSection section) {
    if (value == null) return;
    _mutateConfig((current) {
      final nextSections = List<PortfolioSection>.from(current.sections);
      if (value) {
        if (!nextSections.contains(section)) {
          nextSections.add(section);
        }
      } else {
        nextSections.remove(section);
      }
      return current.copyWith(sections: nextSections);
    });
  }

  void _onSectionReordered(int oldIndex, int newIndex) {
    final sections = List<PortfolioSection>.from(
      _editingConfig?.sections ?? const <PortfolioSection>[],
    );
    if (sections.isEmpty) {
      return;
    }
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final moved = sections.removeAt(oldIndex);
    sections.insert(newIndex, moved);
    _mutateConfig((current) => current.copyWith(sections: sections));
  }

  void _onPrimaryColorSelected(Color color) {
    setState(() {
      _primaryColor = color;
    });
    _updatePreview(primaryColor: color);
  }

  void _onSecondaryColorSelected(Color color) {
    setState(() {
      _secondaryColor = color;
    });
    _updatePreview(secondaryColor: color);
  }

  void _onZoomChanged(double value) {
    setState(() {
      _zoomValue = value;
    });
    _updatePreview(zoom: value);
  }

  void _saveDraft(BuildContext context) {
    final config = _editingConfig;
    if (config == null) return;
    _dispatchPortfolioEvent(PortfolioUpdated(config));
  }

  Future<void> _openExportSheet(BuildContext context) async {
    final config = _editingConfig;
    if (config == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return ExportModal(
          config: config,
          exportService: _exportService,
        );
      },
    );
  }

  Future<void> _openShareSheet(BuildContext context) async {
    final config = _editingConfig;
    if (config == null) return;
    final shareUrl = _buildShareUrl(config.userId);
    final previewBytes = await _capturePreviewImage();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SharePortfolioSheet(
          shareUrl: shareUrl,
          previewBytes: previewBytes,
          onSavePreview: previewBytes == null
              ? null
              : () => savePreviewBytes(previewBytes),
        );
      },
    );
  }

  String _buildShareUrl(String userId) {
    final stamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    return 'https://gitfolio.app/$userId/$stamp';
  }

  Future<Uint8List?> _capturePreviewImage() async {
    final boundary = _previewBoundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) {
      return null;
    }
    final image = await boundary.toImage(pixelRatio: 2);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  void _handleLayoutSwitch(bool isMobile) {
    if (_wasMobileLayout == isMobile) return;
    _wasMobileLayout = isMobile;
    if (isMobile) {
      _previewVisibilityNotifier.value = false;
    } else {
      _previewVisibilityNotifier.value = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Unable to initialize editor: ${snapshot.error}'),
              ),
            ),
          );
        }
        final githubState = context.watch<GithubBloc>().state;
        _maybeRequestConfig(githubState);
        final shortcuts = <ShortcutActivator, Intent>{
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ):
              const _UndoIntent(),
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyY):
              const _RedoIntent(),
          LogicalKeySet(
            LogicalKeyboardKey.control,
            LogicalKeyboardKey.shift,
            LogicalKeyboardKey.keyZ,
          ): const _RedoIntent(),
        };

        return ChangeNotifierProvider.value(
          value: _session,
          child: Shortcuts(
            shortcuts: shortcuts,
            child: Actions(
              actions: {
                _UndoIntent: CallbackAction<_UndoIntent>(
                  onInvoke: (_) {
                    _handleUndo();
                    return null;
                  },
                ),
                _RedoIntent: CallbackAction<_RedoIntent>(
                  onInvoke: (_) {
                    _handleRedo();
                    return null;
                  },
                ),
              },
              child: Stack(
                children: [
                  BlocListener<GithubBloc, GithubState>(
                    listener: (context, state) => _maybeRequestConfig(state),
                    child: BlocListener<PortfolioBloc, PortfolioState>(
                      listener: _handlePortfolioState,
                      child: Scaffold(
                        appBar: _buildAppBar(context),
                        body: SafeArea(
                          child: _buildEditorBody(context, githubState),
                        ),
                        bottomNavigationBar: _buildBottomBar(context),
                      ),
                    ),
                  ),
                  const _SavedIndicatorOverlay(),
                  _AutoSaveOrchestrator(
                    onAutoSave: () {
                      if (_session.shouldAutoSave) {
                        _saveDraft(context);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlPanel(
    BuildContext context,
    bool isReady, {
    required bool enableInternalScroll,
  }) {
    final controlsEnabled = _editingConfig != null && isReady;
    final columnContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTemplateSelector(),
        const SizedBox(height: 16),
        _buildSectionSelector(),
        const SizedBox(height: 16),
        _buildAnalyticsControls(),
        const SizedBox(height: 16),
        _buildColorPickers(),
        const SizedBox(height: 16),
        _buildBioField(),
        const SizedBox(height: 16),
        _buildHistoryControls(),
      ],
    );

    final Widget content = controlsEnabled
        ? (enableInternalScroll
            ? SingleChildScrollView(
                key: const ValueKey('scrollable-control-panel'),
                primary: false,
                padding: EdgeInsets.zero,
                child: columnContent,
              )
            : columnContent)
        : const _EditorLoadingCard();

    return FocusTraversalGroup(
      child: AnimatedSwitcher(
        duration: _animationDuration,
        child: content,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final highContrast = MediaQuery.of(context).highContrast;
    return AppBar(
      title: const Text('Portfolio editor'),
      actions: [
        BlocBuilder<PortfolioBloc, PortfolioState>(
          builder: (context, state) {
            final label = state.isSaving ? 'Saving...' : 'Up to date';
            final background = state.isSaving
                ? (highContrast
                    ? Theme.of(context).colorScheme.error
                    : Colors.orange.withOpacity(0.2))
                : (highContrast
                    ? Theme.of(context).colorScheme.primary
                    : Colors.green.withOpacity(0.2));
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Chip(
                backgroundColor: background,
                label: Text(label),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAnalyticsControls() {
    final analyticsEnabled = _editingConfig?.analyticsEnabled ?? false;
    final includeInExports = _editingConfig?.includeAnalyticsInExports ?? false;

    return Card(
      child: Column(
        children: [
          SwitchListTile.adaptive(
            title: const Text('GitHub analytics'),
            subtitle: const Text(
              'Surface contribution heatmaps, language charts, and repo metrics.',
            ),
            value: analyticsEnabled,
            onChanged: (value) => _mutateConfig(
              (current) => current.copyWith(analyticsEnabled: value),
            ),
          ),
          CheckboxListTile(
            title: const Text('Include analytics in exports'),
            subtitle: const Text(
              'Append the insights section to PDF/HTML/Markdown output.',
            ),
            value: includeInExports,
            onChanged: analyticsEnabled
                ? (value) => _mutateConfig(
                      (current) => current.copyWith(
                        includeAnalyticsInExports: value ?? false,
                      ),
                    )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryControls() {
    return Consumer<PortfolioEditorSession>(
      builder: (context, session, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'History',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Undo (Ctrl+Z)',
                      onPressed: session.canUndo ? _handleUndo : null,
                      icon: const Icon(Icons.undo),
                    ),
                    IconButton(
                      tooltip: 'Redo (Ctrl+Y)',
                      onPressed: session.canRedo ? _handleRedo : null,
                      icon: const Icon(Icons.redo),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: session.canUndo || session.canRedo
                          ? _clearHistory
                          : null,
                      icon: const Icon(Icons.delete_sweep_outlined),
                      label: const Text('Clear history'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  GithubUserModel? _resolveActiveUser(GithubState state) {
    if (state is GithubUserLoaded) {
      return state.user;
    }
    if (state is GithubError && state.previousState is GithubUserLoaded) {
      return (state.previousState as GithubUserLoaded).user;
    }
    return _cachedUser;
  }

  List<RepositoryModel> _resolveActiveRepos(GithubState state) {
    if (state is GithubUserLoaded) {
      return state.repositories ?? _cachedRepos;
    }
    if (state is GithubError && state.previousState is GithubUserLoaded) {
      return (state.previousState as GithubUserLoaded).repositories ??
          _cachedRepos;
    }
    return _cachedRepos;
  }

  Widget? _buildOfflineBanner(BuildContext context, GithubState state) {
    final isNetworkError = state is GithubError && state.errorType == 'network';
    if (!isNetworkError && !_offlineMode) {
      return null;
    }
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Card(
        color: scheme.tertiaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.cloud_off, color: scheme.onTertiaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Working offline. Recent GitHub data may be cached.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: scheme.onTertiaryContainer),
                ),
              ),
              TextButton(
                onPressed: _retryGithubSync,
                child: const Text('Retry'),
              ),
              TextButton(
                onPressed: () => setState(() => _offlineMode = true),
                child: const Text('Use cache'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConflictBanner(BuildContext context) {
    return Consumer<PortfolioEditorSession>(
      builder: (context, session, _) {
        if (!session.hasConflict) {
          return const SizedBox.shrink();
        }
        final remoteTimestamp =
            session.conflictCandidate?.updatedAt.toLocal().toString();
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Changes detected from another device.',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                  ),
                  if (remoteTimestamp != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Remote edit: $remoteTimestamp',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => _resolveConflict(false),
                        child: const Text('Keep mine'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: () => _resolveConflict(true),
                        child: const Text('Use remote'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEditorBody(BuildContext context, GithubState githubState) {
    final user = _resolveActiveUser(githubState);
    final repos = _resolveActiveRepos(githubState);
    final offlineBanner = _buildOfflineBanner(context, githubState);

    return Column(
      children: [
        if (offlineBanner != null) offlineBanner,
        _buildConflictBanner(context),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 900;
              _handleLayoutSwitch(isMobile);
              final showAnalytics = _shouldShowAnalytics(user);

              if (isMobile) {
                final controls = _buildControlPanel(
                  context,
                  user != null,
                  enableInternalScroll: false,
                );
                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    controls,
                    const SizedBox(height: 24),
                    _buildMobilePreviewToggleHint(),
                    ValueListenableBuilder<bool>(
                      valueListenable: _previewVisibilityNotifier,
                      builder: (context, visible, _) {
                        return AnimatedSwitcher(
                          duration: _animationDuration,
                          child: visible
                              ? _buildPreviewCard(
                                  context,
                                  user,
                                  repos,
                                  occupiesHeight: false,
                                )
                              : _PreviewPlaceholder(
                                  message:
                                      'Preview hidden. Use the toggle below to view.',
                                ),
                        );
                      },
                    ),
                    if (showAnalytics && user != null) ...[
                      const SizedBox(height: 24),
                      _buildAnalyticsPanel(context, user, repos),
                    ],
                  ],
                );
              }

              final controls = _buildControlPanel(
                context,
                user != null,
                enableInternalScroll: true,
              );
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: constraints.maxWidth * 0.4,
                      child: controls,
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          _buildPreviewCard(
                            context,
                            user,
                            repos,
                            occupiesHeight: false,
                          ),
                          if (showAnalytics && user != null) ...[
                            const SizedBox(height: 24),
                            _buildAnalyticsPanel(context, user, repos),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateSelector() {
    final selected = _editingConfig?.template ?? PortfolioTemplate.modern;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Templates',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SegmentedButton<PortfolioTemplate>(
              segments: PortfolioTemplate.values
                  .map(
                    (template) => ButtonSegment<PortfolioTemplate>(
                      value: template,
                      label: Text(_templateLabel(template)),
                    ),
                  )
                  .toList(),
              selected: <PortfolioTemplate>{selected},
              showSelectedIcon: false,
              onSelectionChanged: (selection) {
                if (selection.isEmpty) return;
                _onTemplateChanged(selection.first);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionSelector() {
    final activeSections = List<PortfolioSection>.from(
      _editingConfig?.sections ?? const <PortfolioSection>[],
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sections',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              'Drag to reorder the sections that appear on your site.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (activeSections.isEmpty)
              Text(
                'Enable at least one section to begin reordering.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).hintColor),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activeSections.length,
                onReorder: _onSectionReordered,
                itemBuilder: (context, index) {
                  final section = activeSections[index];
                  return ListTile(
                    key: ValueKey(section),
                    leading: const Icon(Icons.drag_handle),
                    title: Text(_sectionLabel(section)),
                    trailing: IconButton(
                      tooltip: 'Hide section',
                      onPressed: () => _onSectionChanged(false, section),
                      icon: const Icon(Icons.visibility_off_outlined),
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),
            Text(
              'Toggle sections',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final section in PortfolioSection.values)
                  FilterChip(
                    label: Text(_sectionLabel(section)),
                    selected: activeSections.contains(section),
                    onSelected: (value) => _onSectionChanged(value, section),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPickers() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Palette',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _ColorPickerRow(
              label: 'Primary',
              selected: _primaryColor,
              colors: _colorChoices,
              onTap: _onPrimaryColorSelected,
            ),
            const SizedBox(height: 16),
            _ColorPickerRow(
              label: 'Secondary',
              selected: _secondaryColor,
              colors: _colorChoices,
              onTap: _onSecondaryColorSelected,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBioField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Custom headline',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Tell visitors what makes you unique...',
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _shouldShowAnalytics(GithubUserModel? user) {
    return user != null && (_editingConfig?.analyticsEnabled ?? false);
  }

  Widget _buildAnalyticsPanel(
    BuildContext context,
    GithubUserModel user,
    List<RepositoryModel> repos,
  ) {
    return HookBuilder(
      builder: (context) {
        final debouncedRepos =
            useDebouncedValue(repos, const Duration(milliseconds: 250));
        final contributions = _generateContributionDays(debouncedRepos);
        final years = contributions.isEmpty
            ? <int>[DateTime.now().year]
            : (contributions.map((day) => day.date.year).toSet().toList()
              ..sort());
        final languageWeights = _languageDistributionFromRepos(debouncedRepos);
        final metricsData = _buildRepositoryMetricsData(debouncedRepos);
        final skillSeries = _buildSkillGrowthSeries(debouncedRepos);
        final benchmarkSeries = _buildBenchmarkSeries(skillSeries);
        final markers = _buildSkillMarkers(debouncedRepos);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'GitHub analytics',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Visualize how ${user.name ?? user.login} shows up on GitHub across contributions, languages, and repository momentum.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                ContributionHeatmap(
                  days: contributions,
                  availableYears: years,
                  initialYear: years.isEmpty ? null : years.last,
                ),
                const SizedBox(height: 24),
                LanguageDistributionChart(languageWeights: languageWeights),
                const SizedBox(height: 24),
                RepositoryMetrics(data: metricsData),
                const SizedBox(height: 24),
                SkillGrowthTimeline(
                  primarySeries: skillSeries,
                  benchmarkSeries: benchmarkSeries,
                  markers: markers,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<ContributionDayData> _generateContributionDays(
    List<RepositoryModel> repos,
  ) {
    if (repos.isEmpty) {
      return const <ContributionDayData>[];
    }
    final now = DateTime.now();
    final start = DateTime(now.year - 1, now.month, now.day);
    final totalDays = now.difference(start).inDays;
    final contributions = <DateTime, int>{};
    for (final repo in repos) {
      final normalized = DateTime(
          repo.updatedAt.year, repo.updatedAt.month, repo.updatedAt.day);
      contributions[normalized] =
          (contributions[normalized] ?? 0) + 1 + repo.stargazersCount ~/ 75;
    }
    final days = <ContributionDayData>[];
    for (var i = 0; i <= totalDays; i++) {
      final date = DateTime(start.year, start.month, start.day + i);
      final normalized = DateTime(date.year, date.month, date.day);
      days.add(
        ContributionDayData(
          date: normalized,
          count: contributions[normalized] ?? (i % 6 == 0 ? 1 : 0),
        ),
      );
    }
    return days;
  }

  Map<String, double> _languageDistributionFromRepos(
    List<RepositoryModel> repos,
  ) {
    if (repos.isEmpty) return const <String, double>{};
    final totals = <String, double>{};
    for (final repo in repos) {
      final language = repo.language?.trim().isEmpty ?? true
          ? 'Other'
          : repo.language!.trim();
      totals[language] = (totals[language] ?? 0) + repo.stargazersCount + 1;
    }
    final total = totals.values.fold<double>(0, (sum, value) => sum + value);
    if (total == 0) {
      return totals;
    }
    return totals.map((key, value) => MapEntry(key, value / total));
  }

  RepositoryMetricsData _buildRepositoryMetricsData(
    List<RepositoryModel> repos,
  ) {
    final totalStars =
        repos.fold<int>(0, (sum, repo) => sum + repo.stargazersCount);
    final totalForks = repos.fold<int>(0, (sum, repo) => sum + repo.forksCount);
    final totalContributors = repos.fold<int>(
      0,
      (sum, repo) => sum + math.max(1, (repo.watchersCount ~/ 4) + 1),
    );
    final starTrend = _buildMonthlyTrend(
      repos,
      (repo) => repo.stargazersCount.toDouble(),
    );
    final forkTrend = _buildMonthlyTrend(
      repos,
      (repo) => repo.forksCount.toDouble(),
    );
    final contributorTrend = _buildMonthlyTrend(
      repos,
      (repo) => math.max(1, repo.watchersCount / 5),
    );
    final topRepo = repos.isEmpty ? null : _topRepositoriesByStars(repos).first;

    return RepositoryMetricsData(
      totalStars: totalStars,
      totalForks: totalForks,
      totalContributors: totalContributors,
      starTrend: starTrend,
      forkTrend: forkTrend,
      contributorTrend: contributorTrend,
      topRepository: topRepo == null
          ? null
          : RepositoryHighlight(
              name: topRepo.name,
              description: topRepo.description ?? 'Open source initiative',
              stars: topRepo.stargazersCount,
              language: topRepo.language ?? 'Unknown',
            ),
    );
  }

  List<double> _buildMonthlyTrend(
    List<RepositoryModel> repos,
    double Function(RepositoryModel repo) extractor,
  ) {
    final buckets = List<double>.filled(12, 0);
    if (repos.isEmpty) {
      for (var i = 0; i < buckets.length; i++) {
        buckets[i] = (i + 1).toDouble();
      }
      return buckets;
    }
    final now = DateTime.now();
    for (final repo in repos) {
      final diffMonths = (now.year - repo.updatedAt.year) * 12 +
          (now.month - repo.updatedAt.month);
      if (diffMonths < 0 || diffMonths > 11) continue;
      final bucketIndex = 11 - diffMonths;
      buckets[bucketIndex] += extractor(repo);
    }
    if (buckets.every((value) => value == 0)) {
      for (var i = 0; i < buckets.length; i++) {
        buckets[i] = (i + 1).toDouble();
      }
    }
    return buckets;
  }

  List<SkillGrowthPoint> _buildSkillGrowthSeries(List<RepositoryModel> repos) {
    final now = DateTime.now();
    final points = <SkillGrowthPoint>[];
    for (var i = 11; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final monthlyRepos = repos
          .where(
            (repo) =>
                repo.updatedAt.year == monthDate.year &&
                repo.updatedAt.month == monthDate.month,
          )
          .toList();
      final momentum = monthlyRepos.fold<double>(
        0,
        (sum, repo) =>
            sum +
            repo.stargazersCount / 75 +
            (repo.topics.isEmpty ? 0.2 : repo.topics.length * 0.05),
      );
      final normalized = monthlyRepos.isEmpty
          ? 0.2
          : (momentum / (monthlyRepos.length * 1.5)).clamp(0.0, 1.0);
      points.add(SkillGrowthPoint(date: monthDate, value: normalized));
    }
    return points;
  }

  List<SkillGrowthPoint> _buildBenchmarkSeries(
    List<SkillGrowthPoint> primary,
  ) {
    if (primary.isEmpty) {
      return const <SkillGrowthPoint>[];
    }
    return primary
        .map(
          (point) => SkillGrowthPoint(
            date: point.date,
            value: (point.value * 0.85).clamp(0.0, 1.0),
          ),
        )
        .toList();
  }

  List<SkillTimelineMarker> _buildSkillMarkers(List<RepositoryModel> repos) {
    final topRepos = _topRepositoriesByStars(repos, limit: 3);
    return topRepos
        .map(
          (repo) => SkillTimelineMarker(
            date: repo.createdAt,
            label: repo.name,
          ),
        )
        .toList();
  }

  List<RepositoryModel> _topRepositoriesByStars(
    List<RepositoryModel> repos, {
    int limit = 5,
  }) {
    final sorted = List<RepositoryModel>.from(repos);
    sorted.sort((a, b) => b.stargazersCount.compareTo(a.stargazersCount));
    return sorted.take(limit).toList();
  }

  Widget _buildPreviewCard(
    BuildContext context,
    GithubUserModel? user,
    List<RepositoryModel> repos, {
    required bool occupiesHeight,
  }) {
    final theme = Theme.of(context);
    final previewHeader = Row(
      children: [
        Text('Live preview', style: theme.textTheme.titleMedium),
        const Spacer(),
        IconButton(
          onPressed: () => _onZoomChanged(math.max(0.8, _zoomValue - 0.05)),
          icon: const Icon(Icons.zoom_out_map),
          tooltip: 'Zoom out',
        ),
        SizedBox(
          width: 160,
          child: Slider(
            value: _zoomValue,
            onChanged: _onZoomChanged,
            divisions: 4,
            min: 0.8,
            max: 1.2,
            label: '${(_zoomValue * 100).round()}%',
            semanticFormatterCallback: (value) =>
                '${(value * 100).round()} percent zoom',
          ),
        ),
        IconButton(
          onPressed: () => _onZoomChanged(math.min(1.2, _zoomValue + 0.05)),
          icon: const Icon(Icons.zoom_in_map),
          tooltip: 'Zoom in',
        ),
      ],
    );

    final previewContent = RepaintBoundary(
      key: _previewBoundaryKey,
      child: ValueListenableBuilder<_PreviewData>(
        valueListenable: _previewNotifier,
        builder: (context, preview, _) {
          if (user == null) {
            return const _PreviewPlaceholder(
              message: 'Connect your GitHub account to start editing.',
            );
          }
          final config = preview.config;
          final effectiveUser = preview.bioOverride.trim().isEmpty
              ? user
              : user.copyWith(bio: preview.bioOverride.trim());
          final themedChild = config == null
              ? const _PreviewSkeleton()
              : Theme(
                  data: _buildPreviewTheme(context, preview),
                  child: Transform.scale(
                    scale: preview.zoom,
                    alignment: Alignment.topCenter,
                    child: _buildTemplate(config, effectiveUser, repos),
                  ),
                );
          return AnimatedSwitcher(
            duration: _animationDuration,
            child: preview.processing || config == null
                ? const _PreviewSkeleton()
                : themedChild,
          );
        },
      ),
    );

    Widget previewSurface = previewContent;
    if (!occupiesHeight) {
      previewSurface = LayoutBuilder(
        builder: (context, constraints) {
          return ClipRect(
            child: ScrollConfiguration(
              behavior: const _PreviewScrollBehavior(),
              child: SingleChildScrollView(
                key: const ValueKey('desktop-preview-scroll'),
                primary: false,
                padding: EdgeInsets.zero,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: constraints.maxWidth,
                  ),
                  child: previewContent,
                ),
              ),
            ),
          );
        },
      );
    }

    final child = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        previewHeader,
        const SizedBox(height: 12),
        Expanded(child: previewSurface),
      ],
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: occupiesHeight ? child : SizedBox(height: 520, child: child),
      ),
    );
  }

  ThemeData _buildPreviewTheme(BuildContext context, _PreviewData preview) {
    final base = Theme.of(context);
    final scheme = base.colorScheme.copyWith(
      primary: preview.primaryColor,
      secondary: preview.secondaryColor,
      surfaceTint: preview.primaryColor,
    );
    return base.copyWith(colorScheme: scheme);
  }

  Widget _buildTemplate(
    PortfolioConfig config,
    GithubUserModel user,
    List<RepositoryModel> repos,
  ) {
    switch (config.template) {
      case PortfolioTemplate.creative:
        return CreativePortfolioTemplate(
          user: user,
          repos: repos,
          config: config,
        );
      case PortfolioTemplate.professional:
        return ProfessionalResumeTemplate(
          user: user,
          repos: repos,
          config: config,
        );
      case PortfolioTemplate.modern:
        return ModernDeveloperTemplate(
          user: user,
          repos: repos,
          config: config,
        );
    }
  }

  Widget _buildMobilePreviewToggleHint() {
    return ValueListenableBuilder<bool>(
      valueListenable: _previewVisibilityNotifier,
      builder: (context, visible, _) {
        final label = visible ? 'Hide preview' : 'Show preview';
        return Text(
          '$label to switch between editor and preview.',
          style: Theme.of(context).textTheme.bodySmall,
        );
      },
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    return BottomAppBar(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            FilledButton.icon(
              onPressed: _editingConfig == null
                  ? null
                  : () => _openExportSheet(context),
              icon: const Icon(Icons.ios_share),
              label: const Text('Export'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _editingConfig == null
                  ? null
                  : () => _openShareSheet(context),
              icon: const Icon(Icons.qr_code_2),
              label: const Text('Share'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed:
                  _editingConfig == null ? null : () => _saveDraft(context),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save draft'),
            ),
            const Spacer(),
            if (isMobile)
              ValueListenableBuilder<bool>(
                valueListenable: _previewVisibilityNotifier,
                builder: (context, visible, _) {
                  return IconButton(
                    onPressed: () =>
                        _previewVisibilityNotifier.value = !visible,
                    icon:
                        Icon(visible ? Icons.visibility_off : Icons.visibility),
                    tooltip: visible ? 'Hide preview' : 'Show preview',
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _templateLabel(PortfolioTemplate template) {
    switch (template) {
      case PortfolioTemplate.modern:
        return 'Modern';
      case PortfolioTemplate.creative:
        return 'Creative';
      case PortfolioTemplate.professional:
        return 'Professional';
    }
  }

  String _sectionLabel(PortfolioSection section) {
    switch (section) {
      case PortfolioSection.hero:
        return 'Hero';
      case PortfolioSection.skills:
        return 'Skills';
      case PortfolioSection.projects:
        return 'Projects';
      case PortfolioSection.timeline:
        return 'Timeline';
      case PortfolioSection.contact:
        return 'Contact';
    }
  }
}

class _PreviewData {
  const _PreviewData({
    this.config,
    this.primaryColor = AppTheme.gitHubPurple,
    this.secondaryColor = AppTheme.gitHubOrange,
    this.bioOverride = '',
    this.zoom = 1.0,
    this.processing = true,
  });

  final PortfolioConfig? config;
  final Color primaryColor;
  final Color secondaryColor;
  final String bioOverride;
  final double zoom;
  final bool processing;

  factory _PreviewData.initial() => const _PreviewData();
}

class _EditorLoadingCard extends StatelessWidget {
  const _EditorLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Fetching portfolio...'),
          ],
        ),
      ),
    );
  }
}

class _ColorPickerRow extends StatelessWidget {
  const _ColorPickerRow({
    required this.label,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final Color selected;
  final List<Color> colors;
  final ValueChanged<Color> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final color in colors)
              Semantics(
                selected: selected == color,
                label: '$label color option',
                button: true,
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => onTap(color),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected == color
                              ? Theme.of(context).colorScheme.onPrimary
                              : Colors.black12,
                          width: selected == color ? 3 : 1,
                        ),
                      ),
                      child: selected == color
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 18)
                          : null,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _PreviewSkeleton extends StatelessWidget {
  const _PreviewSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < 4; i++)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
      ],
    );
  }
}

class _PreviewPlaceholder extends StatelessWidget {
  const _PreviewPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _UndoIntent extends Intent {
  const _UndoIntent();
}

class _RedoIntent extends Intent {
  const _RedoIntent();
}

class _SavedIndicatorOverlay extends StatelessWidget {
  const _SavedIndicatorOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoringSemantics: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Consumer<PortfolioEditorSession>(
              builder: (context, session, _) {
                final visible = session.showSavedIndicator;
                final scheme = Theme.of(context).colorScheme;
                return AnimatedSlide(
                  offset: visible ? Offset.zero : const Offset(0, -1),
                  duration: const Duration(milliseconds: 200),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: visible ? 1 : 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle,
                                color: scheme.primary, size: 18),
                            const SizedBox(width: 8),
                            const Text('All changes saved'),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AutoSaveOrchestrator extends StatefulWidget {
  const _AutoSaveOrchestrator({required this.onAutoSave});

  final VoidCallback onAutoSave;

  @override
  State<_AutoSaveOrchestrator> createState() => _AutoSaveOrchestratorState();
}

class _AutoSaveOrchestratorState extends State<_AutoSaveOrchestrator> {
  Timer? _debounce;
  Timer? _interval;
  bool _pendingSave = false;
  PortfolioEditorSession? _latestSession;
  static const _debounceDuration = Duration(milliseconds: 300);
  static const _intervalDuration = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _startIntervalLoop();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _interval?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PortfolioEditorSession>(
      builder: (context, session, _) {
        _latestSession = session;
        final shouldSave = session.shouldAutoSave;
        if (shouldSave && !_pendingSave) {
          _pendingSave = true;
          _queueDebouncedSave();
        } else if (!shouldSave && _pendingSave) {
          _pendingSave = false;
          _debounce?.cancel();
        }
        if (!shouldSave) {
          _pendingSave = false;
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _queueDebouncedSave() {
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () {
      _pendingSave = false;
      widget.onAutoSave();
    });
  }

  void _startIntervalLoop() {
    _interval?.cancel();
    _interval = Timer.periodic(_intervalDuration, (_) {
      final session = _latestSession;
      if (session?.shouldAutoSave ?? false) {
        widget.onAutoSave();
      }
    });
  }
}

class _PreviewScrollBehavior extends ScrollBehavior {
  const _PreviewScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

T useDebouncedValue<T>(T value, Duration duration) {
  final state = useState<T>(value);
  final previous = useRef<T>(value);

  useEffect(() {
    if (previous.value == value) {
      return null;
    }
    previous.value = value;
    Timer? timer = Timer(duration, () {
      state.value = value;
    });
    return timer.cancel;
  }, [value, duration]);

  return state.value;
}
