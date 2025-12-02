import 'dart:math';

import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import '../constants/app_constants.dart';
import '../errors/exceptions.dart';

/// Handles the GitHub OAuth browser flow across platforms.
class GithubOAuthService {
  GithubOAuthService._();

  /// Starts the OAuth authorization flow and returns the auth code on success.
  static Future<String> signIn() async {
    final state = _generateState();
    final redirectUri = Uri.parse(AppConstants.githubRedirectUri);
    if (!redirectUri.hasScheme) {
      throw const AuthException(
        'Invalid redirect URI',
        details:
            'Update AppConstants.githubRedirectUri with a valid URI (e.g. gitfolio://auth).',
      );
    }

    final queryParameters = <String, String>{
      'client_id': AppConstants.githubClientId,
      'redirect_uri': AppConstants.githubRedirectUri,
      'scope': AppConstants.githubScopes.join(' '),
      'state': state,
      'allow_signup': 'true',
    };

    final authorizeUrl = Uri.parse(AppConstants.githubAuthUrl).replace(
      queryParameters: queryParameters,
    );

    final callbackScheme = redirectUri.scheme;

    final result = await FlutterWebAuth2.authenticate(
      url: authorizeUrl.toString(),
      callbackUrlScheme: callbackScheme,
    );

    final responseUri = Uri.parse(result);
    final returnedState = responseUri.queryParameters['state'];
    final code = responseUri.queryParameters['code'];

    if (returnedState != state) {
      throw AuthException.oauthFailed(reason: 'OAuth state mismatch');
    }

    if (code == null || code.isEmpty) {
      throw AuthException.oauthFailed(
        reason: 'GitHub did not return an authorization code',
      );
    }

    return code;
  }

  static String _generateState([int length = 32]) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)])
        .join();
  }
}
