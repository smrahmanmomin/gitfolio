import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/services/github_oauth_service.dart';
import '../../core/services/token_service.dart';
import '../../core/utils/extensions.dart';
import '../bloc/github/github_bloc.dart';
import '../bloc/github/github_event.dart';
import '../bloc/github/github_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _tokenController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isObscured = true;
  bool _isOauthLoading = false;
  bool _isTokenSubmitting = false;

  Future<void> _handleGithubOAuth() async {
    if (_isOauthLoading) return;

    if (!GithubOAuthService.isSupported) {
      context.showErrorSnackBar(
        'GitHub sign-in is not available in this build. Use a personal access token below.',
      );
      return;
    }

    setState(() => _isOauthLoading = true);

    try {
      final code = await GithubOAuthService.signIn();
      if (!mounted) return;
      context.read<GithubBloc>().add(GithubAuthenticate(code: code));
    } on AuthException catch (e) {
      if (mounted) {
        context.showErrorSnackBar(e.message);
      }
    } catch (_) {
      if (mounted) {
        context.showErrorSnackBar('GitHub sign-in failed. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isOauthLoading = false);
      }
    }
  }

  Future<void> _handleTokenLogin() async {
    if (_isTokenSubmitting || !_formKey.currentState!.validate()) return;

    setState(() => _isTokenSubmitting = true);

    final token = _tokenController.text.trim();
    await TokenService.saveToken(token);

    if (mounted) {
      context.read<GithubBloc>().add(GithubAuthenticate(token: token));
    }

    if (mounted) {
      setState(() => _isTokenSubmitting = false);
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  bool get _isOauthSupported => GithubOAuthService.isSupported;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<GithubBloc, GithubState>(
        listener: (context, state) {
          if (state is GithubAuthenticated) {
            TokenService.saveToken(state.token);
          }

          if (state is GithubUserLoaded) {
            Navigator.of(context).pushReplacementNamed('/dashboard');
          } else if (state is GithubError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.largePadding),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHeroSection(context),
                    const SizedBox(height: 48),
                    _buildGithubButton(context),
                    if (!_isOauthSupported) ...[
                      const SizedBox(height: 12),
                      Text(
                        'GitHub OAuth is unavailable on this platform. Use the token option below instead.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .error
                                  .withValues(alpha: 0.85),
                            ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    Text(
                      'Authenticate with GitHub to explore your stats, repositories, and portfolio in one unified dashboard.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.75),
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'We never see your password. Authentication happens on GitHub and tokens stay securely on this device.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                    ),
                    const SizedBox(height: 32),
                    _TokenFallbackCard(
                      formKey: _formKey,
                      tokenController: _tokenController,
                      isObscured: _isObscured,
                      isSubmitting: _isTokenSubmitting,
                      onToggleVisibility: () =>
                          setState(() => _isObscured = !_isObscured),
                      onSubmit: _handleTokenLogin,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            Icons.code,
            size: 56,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          AppConstants.appName,
          style: Theme.of(context)
              .textTheme
              .displaySmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Your GitHub Portfolio',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
        ),
      ],
    );
  }

  Widget _buildGithubButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: _isOauthLoading ? null : _handleGithubOAuth,
        icon: _isOauthLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : const Icon(Icons.login),
        label: Text(
          _isOauthLoading ? 'Connecting to GitHub…' : 'Continue with GitHub',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

class _TokenFallbackCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController tokenController;
  final bool isObscured;
  final bool isSubmitting;
  final VoidCallback onToggleVisibility;
  final VoidCallback onSubmit;

  const _TokenFallbackCard({
    required this.formKey,
    required this.tokenController,
    required this.isObscured,
    required this.isSubmitting,
    required this.onToggleVisibility,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Use a personal access token',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Fallback for browsers or environments where the GitHub popup cannot open.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              TextFormField(
                controller: tokenController,
                obscureText: isObscured,
                decoration: InputDecoration(
                  labelText: 'GitHub Personal Access Token',
                  hintText: 'ghp_xxxxxxxxxxxx',
                  prefixIcon: const Icon(Icons.key),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isObscured ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: onToggleVisibility,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please paste your access token';
                  }
                  if (!value.trim().startsWith('gh')) {
                    return 'Token should start with gh…';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: isSubmitting ? null : onSubmit,
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(isSubmitting ? 'Validating…' : 'Use Token'),
                ),
              ),
              const SizedBox(height: AppConstants.smallPadding),
              Text(
                'Required scopes: user, repo, read:org',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
