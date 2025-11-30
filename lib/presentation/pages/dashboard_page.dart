import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_constants.dart';
import '../bloc/github/github_bloc.dart';
import '../bloc/github/github_event.dart';
import '../bloc/github/github_state.dart';
import 'profile_page.dart';
import 'repos_page.dart';

/// Main dashboard with tab navigation.
///
/// Displays different sections: Profile, Repos, Analytics, Portfolio.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const ProfilePage(),
    const ReposPage(),
    const _AnalyticsPlaceholder(),
    const _PortfolioPlaceholder(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocListener<GithubBloc, GithubState>(
      listener: (context, state) {
        if (state is GithubError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
              action: SnackBarAction(
                label: 'Dismiss',
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppConstants.appName),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                final state = context.read<GithubBloc>().state;
                if (state is GithubUserLoaded) {
                  context.read<GithubBloc>().add(
                        GithubRefreshData(token: state.token),
                      );
                }
              },
              tooltip: 'Refresh',
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'logout') {
                  _showLogoutDialog(context);
                } else if (value == 'settings') {
                  _showSettingsDialog(context);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings),
                      SizedBox(width: 8),
                      Text('Settings'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: 8),
                      Text('Logout'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: IndexedStack(index: _currentIndex, children: _pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
            NavigationDestination(
              icon: Icon(Icons.book_outlined),
              selectedIcon: Icon(Icons.book),
              label: 'Repos',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Analytics',
            ),
            NavigationDestination(
              icon: Icon(Icons.web_outlined),
              selectedIcon: Icon(Icons.web),
              label: 'Portfolio',
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<GithubBloc>().add(const GithubLogout());
              Navigator.of(context).pushReplacementNamed('/login');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Settings'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.brightness_6),
              title: Text('Theme'),
              subtitle: Text('Coming soon'),
            ),
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text('Notifications'),
              subtitle: Text('Coming soon'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Placeholder for Analytics section.
class _AnalyticsPlaceholder extends StatelessWidget {
  const _AnalyticsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 64),
          SizedBox(height: 16),
          Text('Analytics'),
          SizedBox(height: 8),
          Text('Coming soon!', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

/// Placeholder for Portfolio section.
class _PortfolioPlaceholder extends StatelessWidget {
  const _PortfolioPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.web, size: 64),
          SizedBox(height: 16),
          Text('Portfolio'),
          SizedBox(height: 8),
          Text('Coming soon!', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
