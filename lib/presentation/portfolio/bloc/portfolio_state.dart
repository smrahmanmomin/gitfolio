import 'package:equatable/equatable.dart';

import '../../../domain/portfolio/portfolio_entity.dart';

abstract class PortfolioState extends Equatable {
  const PortfolioState({
    this.config,
    this.isSaving = false,
    this.exportPath,
  });

  final PortfolioConfig? config;
  final bool isSaving;
  final String? exportPath;

  @override
  List<Object?> get props => [config, isSaving, exportPath];
}

class PortfolioInitial extends PortfolioState {
  const PortfolioInitial();
}

class PortfolioLoading extends PortfolioState {
  const PortfolioLoading({PortfolioConfig? config}) : super(config: config);
}

class PortfolioLoaded extends PortfolioState {
  const PortfolioLoaded({
    required PortfolioConfig config,
    bool isSaving = false,
    String? exportPath,
  }) : super(config: config, isSaving: isSaving, exportPath: exportPath);

  PortfolioLoaded copyWith({
    PortfolioConfig? config,
    bool? isSaving,
    String? exportPath,
  }) {
    return PortfolioLoaded(
      config: config ?? this.config!,
      isSaving: isSaving ?? this.isSaving,
      exportPath: exportPath ?? this.exportPath,
    );
  }
}

class PortfolioError extends PortfolioState {
  const PortfolioError(this.message, {PortfolioConfig? config})
      : super(config: config);

  final String message;

  @override
  List<Object?> get props => [...super.props, message];
}
