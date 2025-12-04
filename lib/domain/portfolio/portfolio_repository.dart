import 'dart:typed_data';

import 'portfolio_entity.dart';

/// Contract for persisting and exporting portfolio data.
abstract class PortfolioRepository {
  Future<PortfolioConfig> getPortfolioConfig(String userId);

  Future<void> savePortfolioConfig(PortfolioConfig config);

  Future<Uint8List> exportPortfolio(
    PortfolioConfig config,
    ExportFormat format,
  );
}
