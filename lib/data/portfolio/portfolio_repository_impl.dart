import 'dart:typed_data';

import '../../domain/portfolio/portfolio_entity.dart';
import '../../domain/portfolio/portfolio_repository.dart';
import 'datasources/export_service.dart';
import 'datasources/local_portfolio_source.dart';
import 'models/portfolio_config_model.dart';

class PortfolioRepositoryImpl implements PortfolioRepository {
  PortfolioRepositoryImpl({
    required LocalPortfolioSource localSource,
    PortfolioExportService? exportService,
  })  : _localSource = localSource,
        _exportService = exportService ?? const PortfolioExportService();

  final LocalPortfolioSource _localSource;
  final PortfolioExportService _exportService;

  @override
  Future<PortfolioConfig> getPortfolioConfig(String userId) async {
    final config = await _localSource.fetchConfig(userId);
    return config ?? _localSource.createDefault(userId);
  }

  @override
  Future<void> savePortfolioConfig(PortfolioConfig config) {
    return _localSource.persistConfig(
      PortfolioConfigModel.fromEntity(config),
    );
  }

  @override
  Future<Uint8List> exportPortfolio(
    PortfolioConfig config,
    ExportFormat format,
  ) async {
    switch (format) {
      case ExportFormat.pdf:
        return _exportService.exportToPdf(config);
      case ExportFormat.markdown:
        return _exportService.exportToMarkdown(config);
      case ExportFormat.html:
        return _exportService.exportToHtml(config);
      case ExportFormat.json:
        return _exportService.exportToJson(config);
    }
  }
}
