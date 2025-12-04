import 'package:equatable/equatable.dart';

import '../../../domain/portfolio/portfolio_entity.dart';

abstract class PortfolioEvent extends Equatable {
  const PortfolioEvent();

  @override
  List<Object?> get props => [];
}

class PortfolioLoadRequested extends PortfolioEvent {
  const PortfolioLoadRequested(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

class PortfolioUpdated extends PortfolioEvent {
  const PortfolioUpdated(this.config);

  final PortfolioConfig config;

  @override
  List<Object?> get props => [config];
}

class PortfolioExported extends PortfolioEvent {
  const PortfolioExported(this.format);

  final ExportFormat format;

  @override
  List<Object?> get props => [format];
}
