import 'package:hive/hive.dart';

import '../models/portfolio_config_model.dart';

const String _portfolioBoxName = 'portfolio_configs';

class LocalPortfolioSource {
  LocalPortfolioSource({required HiveInterface hive}) : _hive = hive;

  final HiveInterface _hive;

  Future<Box<Map>> _openBox() {
    return _hive.openBox<Map>(_portfolioBoxName);
  }

  Future<PortfolioConfigModel?> fetchConfig(String userId) async {
    final box = await _openBox();
    final data = box.get(userId);
    if (data == null) {
      return null;
    }
    return PortfolioConfigModel.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  Future<void> persistConfig(PortfolioConfigModel config) async {
    final box = await _openBox();
    await box.put(config.userId, config.toJson());
  }

  PortfolioConfigModel createDefault(String userId) {
    return PortfolioConfigModel.defaultForUser(userId);
  }
}
