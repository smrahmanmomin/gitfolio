import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import '../../data/datasources/github_remote_data_source.dart';
import '../../data/repositories/github_repository_impl.dart';
import '../../domain/repositories/github_repository.dart';
import 'github/github_bloc.dart';
import 'github/github_state.dart';

/// Provides all BLoC instances for the application.
///
/// This class sets up the dependency injection for all BLoCs,
/// creating the necessary repositories and data sources.
///
/// Usage:
/// ```dart
/// void main() {
///   runApp(
///     BlocProviders(
///       child: MyApp(),
///     ),
///   );
/// }
/// ```
class BlocProviders extends StatelessWidget {
  final Widget child;

  const BlocProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        // Provide the HTTP client
        RepositoryProvider<http.Client>(create: (context) => http.Client()),

        // Provide the remote data source
        RepositoryProvider<GithubRemoteDataSource>(
          create: (context) =>
              GithubRemoteDataSourceImpl(client: context.read<http.Client>()),
        ),

        // Provide the GitHub repository
        RepositoryProvider<GithubRepository>(
          create: (context) => GithubRepositoryImpl(
            remoteDataSource: context.read<GithubRemoteDataSource>(),
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          // GitHub BLoC
          BlocProvider<GithubBloc>(
            create: (context) =>
                GithubBloc(repository: context.read<GithubRepository>()),
          ),
        ],
        child: child,
      ),
    );
  }
}

/// Alternative setup for providing BLoCs with custom configurations.
///
/// Use this if you need more control over the initialization or
/// want to inject mock dependencies for testing.
///
/// Usage:
/// ```dart
/// void main() {
///   final githubRepository = GithubRepositoryImpl(
///     remoteDataSource: GithubRemoteDataSourceImpl(
///       client: http.Client(),
///     ),
///   );
///
///   runApp(
///     CustomBlocProviders(
///       githubRepository: githubRepository,
///       child: MyApp(),
///     ),
///   );
/// }
/// ```
class CustomBlocProviders extends StatelessWidget {
  final Widget child;
  final GithubRepository githubRepository;

  const CustomBlocProviders({
    super.key,
    required this.child,
    required this.githubRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<GithubBloc>(
          create: (context) => GithubBloc(repository: githubRepository),
        ),
      ],
      child: child,
    );
  }
}

/// Helper extension for accessing BLoCs from the context.
///
/// Provides convenient methods for reading and watching BLoCs.
///
/// Usage:
/// ```dart
/// // Read (doesn't rebuild on state changes)
/// context.githubBloc.add(GithubFetchUser(token: token));
///
/// // Watch (rebuilds on state changes)
/// final state = context.watchGithubBloc;
/// ```
extension BlocContextExtension on BuildContext {
  /// Get the GithubBloc without listening to changes
  GithubBloc get githubBloc => read<GithubBloc>();

  /// Get the GithubBloc and listen to state changes
  GithubBloc get watchGithubBloc => watch<GithubBloc>();

  /// Get the current GithubBloc state without listening
  GithubState get githubState => read<GithubBloc>().state;

  /// Get the current GithubBloc state and listen to changes
  GithubState get watchGithubState => watch<GithubBloc>().state;
}
