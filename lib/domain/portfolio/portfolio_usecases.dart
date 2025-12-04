import 'dart:typed_data';

import 'portfolio_entity.dart';
import 'portfolio_repository.dart';

class GeneratePortfolioUseCase {
  const GeneratePortfolioUseCase(this._repository);

  final PortfolioRepository _repository;

  Future<PortfolioConfig> call(String userId) {
    return _repository.getPortfolioConfig(userId);
  }
}

class ExportPortfolioUseCase {
  const ExportPortfolioUseCase(this._repository);

  final PortfolioRepository _repository;

  Future<Uint8List> call(PortfolioConfig config, ExportFormat format) {
    return _repository.exportPortfolio(config, format);
  }
}

class UpdateTemplateUseCase {
  const UpdateTemplateUseCase(this._repository);

  final PortfolioRepository _repository;

  Future<void> call(PortfolioConfig config) {
    return _repository.savePortfolioConfig(config);
  }
}
