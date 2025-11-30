import 'package:flutter/material.dart';

import 'core/themes/app_theme.dart';
import 'presentation/bloc/bloc_providers.dart';
import 'presentation/pages/splash_screen.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/pages/dashboard_page.dart';

import 'core/utils/network_interceptor.dart';

void main() {
  NetworkInterceptor.initialize();
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProviders(
      child: MaterialApp(
        title: 'GitFolio',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginPage(),
          '/dashboard': (context) => const DashboardPage(),
        },
      ),
    );
  }
}

