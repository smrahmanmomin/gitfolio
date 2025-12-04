import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/portfolio/portfolio_entity.dart';

class PortfolioEditorSession extends ChangeNotifier {
  PortfolioEditorSession({this.maxHistory = 50});

  final int maxHistory;

  PortfolioConfig? _currentConfig;
  PortfolioConfig? _lastSavedConfig;
  final List<PortfolioConfig> _undoStack = [];
  final List<PortfolioConfig> _redoStack = [];
  bool _hasPendingSave = false;
  bool _isSaving = false;
  bool _showSavedIndicator = false;
  PortfolioConfig? _conflictRemote;
  Timer? _savedIndicatorTimer;

  PortfolioConfig? get currentConfig => _currentConfig;
  bool get hasUnsavedChanges => _hasPendingSave;
  bool get isSaving => _isSaving;
  bool get showSavedIndicator => _showSavedIndicator;
  bool get canUndo => _undoStack.length > 1;
  bool get canRedo => _redoStack.isNotEmpty;
  bool get shouldAutoSave => hasUnsavedChanges && !_isSaving;
  PortfolioConfig? get conflictCandidate => _conflictRemote;
  bool get hasConflict => _conflictRemote != null;

  void bootstrap(PortfolioConfig config) {
    _currentConfig = config;
    _lastSavedConfig = config;
    _undoStack
      ..clear()
      ..add(config);
    _redoStack.clear();
    _hasPendingSave = false;
    _conflictRemote = null;
    notifyListeners();
  }

  void registerChange(PortfolioConfig config) {
    _currentConfig = config;
    _undoStack.add(config);
    if (_undoStack.length > maxHistory) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
    _hasPendingSave = true;
    _showSavedIndicator = false;
    _savedIndicatorTimer?.cancel();
    notifyListeners();
  }

  PortfolioConfig? undo() {
    if (!canUndo) return null;
    final latest = _undoStack.removeLast();
    _redoStack.add(latest);
    final previous = _undoStack.last;
    _currentConfig = previous;
    _hasPendingSave = true;
    notifyListeners();
    return previous;
  }

  PortfolioConfig? redo() {
    if (_redoStack.isEmpty) return null;
    final next = _redoStack.removeLast();
    _undoStack.add(next);
    _currentConfig = next;
    _hasPendingSave = true;
    notifyListeners();
    return next;
  }

  void clearHistory() {
    if (_currentConfig == null) {
      return;
    }
    _undoStack
      ..clear()
      ..add(_currentConfig!);
    _redoStack.clear();
    notifyListeners();
  }

  void updateSaving(bool saving) {
    if (_isSaving == saving) return;
    _isSaving = saving;
    notifyListeners();
  }

  void markSaved(PortfolioConfig config) {
    _currentConfig = config;
    _lastSavedConfig = config;
    if (_undoStack.isEmpty) {
      _undoStack.add(config);
    } else {
      _undoStack[_undoStack.length - 1] = config;
    }
    _redoStack.clear();
    _hasPendingSave = false;
    _isSaving = false;
    _showSavedIndicator = true;
    _savedIndicatorTimer?.cancel();
    _savedIndicatorTimer = Timer(const Duration(seconds: 2), () {
      _showSavedIndicator = false;
      notifyListeners();
    });
    notifyListeners();
  }

  void registerRemoteSnapshot(PortfolioConfig config) {
    if (_lastSavedConfig != null &&
        config.updatedAt.isAfter(_lastSavedConfig!.updatedAt) &&
        hasUnsavedChanges) {
      _conflictRemote = config;
      notifyListeners();
      return;
    }
    _lastSavedConfig = config;
    _currentConfig = config;
    if (_undoStack.isEmpty) {
      _undoStack.add(config);
    } else {
      _undoStack[_undoStack.length - 1] = config;
    }
    _redoStack.clear();
    _hasPendingSave = false;
    notifyListeners();
  }

  PortfolioConfig? resolveConflict({required bool acceptRemote}) {
    final remote = _conflictRemote;
    _conflictRemote = null;
    if (remote == null) {
      notifyListeners();
      return null;
    }
    if (acceptRemote) {
      bootstrap(remote);
      return remote;
    }
    notifyListeners();
    return null;
  }

  @override
  void dispose() {
    _savedIndicatorTimer?.cancel();
    super.dispose();
  }
}
