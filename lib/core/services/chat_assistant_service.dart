import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../../data/models/github_user_model.dart';
import '../../data/models/repository_model.dart';
import '../constants/app_constants.dart';

/// Lightweight RAG service that uses embeddings + chat completions to answer
/// repository-specific questions.
class ChatAssistantService {
  ChatAssistantService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  static const _embeddingEndpoint = 'https://api.openai.com/v1/embeddings';
  static const _chatEndpoint = 'https://api.openai.com/v1/chat/completions';

  static final Map<String, List<double>> _embeddingCache = {};

  Future<String> askCopilot({
    required String apiKey,
    required String question,
    required List<RepositoryModel> repositories,
    GithubUserModel? user,
    String? selectedTemplateDescription,
  }) async {
    if (apiKey.isEmpty) {
      throw const ChatAssistantException(
        'Missing OpenAI API key. Save it in Settings > AI Assistant first.',
      );
    }

    final query = question.trim();
    if (query.isEmpty) {
      throw const ChatAssistantException('Ask a question to start the chat.');
    }

    if (repositories.isEmpty) {
      throw const ChatAssistantException(
        'Load your repositories first so I have context for answers.',
      );
    }

    final rankedContexts = await _rankRepositoryContexts(
      apiKey: apiKey,
      question: query,
      repositories: repositories,
    );

    final contextBlock = rankedContexts
        .take(3)
        .map((doc) => '- ${doc.repo.fullName}: ${doc.summary}')
        .join('\n\n');

    final profileSummary =
        _buildProfileSummary(user, selectedTemplateDescription);

    final systemPrompt =
        'You are GitFolio Copilot, an AI mentor for GitHub developers. '
        'Blend retrieved repo context with fresh insights to answer questions '
        'and suggest concrete project ideas. Keep answers concise but rich in '
        'technical depth.';

    final userPrompt = '''
$profileSummary

Repository context:
$contextBlock

Question: $query
Provide a thoughtful answer referencing specific repositories and suggesting two follow-up project ideas. If more data is needed, explain what to collect.
''';

    return _callChatCompletion(
        apiKey: apiKey, systemPrompt: systemPrompt, userPrompt: userPrompt);
  }

  Future<List<_RepoDocument>> _rankRepositoryContexts({
    required String apiKey,
    required String question,
    required List<RepositoryModel> repositories,
  }) async {
    final sorted = [...repositories]
      ..sort((a, b) => b.stargazersCount.compareTo(a.stargazersCount));
    final topRepos = sorted.take(10).toList();

    final questionEmbedding = await _embedText(apiKey, question);
    final docs = <_RepoDocument>[];

    for (final repo in topRepos) {
      final cacheKey = '${repo.id}_${repo.updatedAt.toIso8601String()}';
      final summary = _repoSummary(repo);
      List<double> repoEmbedding;
      if (_embeddingCache.containsKey(cacheKey)) {
        repoEmbedding = _embeddingCache[cacheKey]!;
      } else {
        repoEmbedding = await _embedText(apiKey, summary);
        _embeddingCache[cacheKey] = repoEmbedding;
      }

      final score = _cosineSimilarity(questionEmbedding, repoEmbedding);
      docs.add(_RepoDocument(repo: repo, score: score, summary: summary));
    }

    docs.sort((a, b) => b.score.compareTo(a.score));
    return docs;
  }

  Future<List<double>> _embedText(String apiKey, String text) async {
    final response = await _client.post(
      Uri.parse(_embeddingEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': AppConstants.openAiEmbeddingModel,
        'input': text,
      }),
    );

    if (response.statusCode != 200) {
      throw ChatAssistantException(
        'Embedding request failed (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as List<dynamic>;
    if (data.isEmpty) {
      throw const ChatAssistantException('Embedding response missing data.');
    }
    final embedding = (data.first['embedding'] as List<dynamic>)
        .map((e) => (e as num).toDouble())
        .toList();
    return embedding;
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    final length = math.min(a.length, b.length);
    double dot = 0;
    double magA = 0;
    double magB = 0;
    for (var i = 0; i < length; i++) {
      dot += a[i] * b[i];
      magA += a[i] * a[i];
      magB += b[i] * b[i];
    }
    if (magA == 0 || magB == 0) return 0;
    return dot / (math.sqrt(magA) * math.sqrt(magB));
  }

  String _repoSummary(RepositoryModel repo) {
    final topics = repo.topics.isEmpty ? 'No topics' : repo.topics.join(', ');
    final description = repo.description ?? 'No description provided.';
    final language = repo.language ?? 'Unknown language';
    return '${repo.name}: $description | Language: $language | '
        'Topics: $topics | Stars: ${repo.stargazersCount} | Last updated: '
        '${repo.updatedAt.toIso8601String()}';
  }

  Future<String> _callChatCompletion({
    required String apiKey,
    required String systemPrompt,
    required String userPrompt,
  }) async {
    final response = await _client.post(
      Uri.parse(_chatEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': AppConstants.openAiChatModel,
        'temperature': 0.2,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw ChatAssistantException(
        'Chat completion failed (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = decoded['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw const ChatAssistantException('Chat completion response was empty.');
    }
    final message = choices.first['message'] as Map<String, dynamic>?;
    return (message?['content'] as String?)?.trim() ??
        'I could not generate a response. Please try again.';
  }

  String _buildProfileSummary(
    GithubUserModel? user,
    String? selectedTemplateDescription,
  ) {
    if (user == null) {
      return 'No authenticated GitHub profile data available.';
    }

    final buffer = StringBuffer('User profile: ${user.login}\n');
    if (user.name != null) buffer.writeln('Name: ${user.name}');
    if (user.bio != null) buffer.writeln('Bio: ${user.bio}');
    buffer
        .writeln('Followers: ${user.followers}, Following: ${user.following}');
    buffer.writeln('Public repos: ${user.publicRepos}');
    if (selectedTemplateDescription != null) {
      buffer.writeln('Portfolio template: $selectedTemplateDescription');
    }
    return buffer.toString();
  }
}

class ChatAssistantException implements Exception {
  final String message;
  const ChatAssistantException(this.message);

  @override
  String toString() => message;
}

class _RepoDocument {
  final RepositoryModel repo;
  final double score;
  final String summary;

  _RepoDocument({
    required this.repo,
    required this.score,
    required this.summary,
  });
}
