import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/portfolio/portfolio_usecases.dart';
import 'portfolio_event.dart';
import 'portfolio_state.dart';

class PortfolioBloc extends Bloc<PortfolioEvent, PortfolioState> {
  PortfolioBloc({
    required GeneratePortfolioUseCase generatePortfolio,
    required UpdateTemplateUseCase updateTemplate,
    required ExportPortfolioUseCase exportPortfolio,
  })  : _generatePortfolio = generatePortfolio,
        _updateTemplate = updateTemplate,
        _exportPortfolio = exportPortfolio,
        super(const PortfolioInitial()) {
    on<PortfolioLoadRequested>(_onLoadRequested);
    on<PortfolioUpdated>(_onUpdated);
    on<PortfolioExported>(_onExported);
  }

  final GeneratePortfolioUseCase _generatePortfolio;
  final UpdateTemplateUseCase _updateTemplate;
  final ExportPortfolioUseCase _exportPortfolio;

  Future<void> _onLoadRequested(
    PortfolioLoadRequested event,
    Emitter<PortfolioState> emit,
  ) async {
    emit(PortfolioLoading(config: state.config));
    try {
      final config = await _generatePortfolio(event.userId);
      emit(PortfolioLoaded(config: config));
    } catch (error) {
      emit(PortfolioError(error.toString(), config: state.config));
    }
  }

  Future<void> _onUpdated(
    PortfolioUpdated event,
    Emitter<PortfolioState> emit,
  ) async {
    final currentState = state;
    final loadingState = currentState is PortfolioLoaded
        ? currentState.copyWith(config: event.config, isSaving: true)
        : PortfolioLoaded(config: event.config, isSaving: true);
    emit(loadingState);

    try {
      await _updateTemplate(event.config);
      emit(loadingState.copyWith(isSaving: false));
    } catch (error) {
      emit(PortfolioError(error.toString(), config: event.config));
    }
  }

  Future<void> _onExported(
    PortfolioExported event,
    Emitter<PortfolioState> emit,
  ) async {
    final config = state.config;
    if (config == null) {
      emit(PortfolioError('No portfolio configuration loaded.'));
      return;
    }

    final workingState = state is PortfolioLoaded
        ? (state as PortfolioLoaded).copyWith(isSaving: true, exportPath: null)
        : PortfolioLoaded(config: config, isSaving: true);
    emit(workingState);

    try {
      final artifact = await _exportPortfolio(config, event.format);
      final exportName =
          'portfolio_${config.userId}_${artifact.length}.${event.format.name}';
      emit(workingState.copyWith(
        isSaving: false,
        exportPath: exportName,
      ));
    } catch (error) {
      emit(PortfolioError(error.toString(), config: config));
    }
  }
}
