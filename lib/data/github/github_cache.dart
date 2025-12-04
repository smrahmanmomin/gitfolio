import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/github_user_model.dart';
import '../models/repository_model.dart';

class GithubCache {
  GithubCache._(this._prefs);

  final SharedPreferences _prefs;

  static const _userKey = 'cached_github_user';
  static const _reposKey = 'cached_github_repos';

  static Future<GithubCache> create() async {
    final prefs = await SharedPreferences.getInstance();
    return GithubCache._(prefs);
  }

  Future<void> persistUser(GithubUserModel user) async {
    await _prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<void> persistRepos(List<RepositoryModel> repos) async {
    final payload = repos.map((repo) => repo.toJson()).toList();
    await _prefs.setString(_reposKey, jsonEncode(payload));
  }

  GithubUserModel? readUser() {
    final raw = _prefs.getString(_userKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return GithubUserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  List<RepositoryModel> readRepos() {
    final raw = _prefs.getString(_reposKey);
    if (raw == null || raw.isEmpty) {
      return const <RepositoryModel>[];
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map(
          (entry) => RepositoryModel.fromJson(
            Map<String, dynamic>.from(entry as Map),
          ),
        )
        .toList();
  }
}
