import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/themes/app_theme.dart';
import 'presentation/bloc/bloc_providers.dart';
import 'presentation/bloc/settings/settings_cubit.dart';
import 'presentation/bloc/settings/settings_state.dart';
import 'presentation/pages/splash_screen.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/pages/dashboard_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProviders(
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settingsState) {
          return MaterialApp(
            title: 'GitFolio',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(compactMode: settingsState.compactMode),
            darkTheme: AppTheme.dark(compactMode: settingsState.compactMode),
            themeMode: settingsState.themeMode,
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/login': (context) => const LoginPage(),
              '/dashboard': (context) => const DashboardPage(),
            },
          );
        },
      ),
    );
  }
}
