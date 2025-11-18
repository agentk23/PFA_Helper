import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/pfa_registration_screen.dart';
import '../screens/pfa_profile_screen.dart';
import '../screens/transactions_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/anaf_invoices_screen.dart';
import '../screens/help_screen.dart';
import '../services/storage_service.dart';

/// Application router configuration using go_router
/// Defines all routes and navigation logic for the app
class AppRouter {
  /// Router instance for the entire application
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const _SplashScreen(),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/registration',
        name: 'registration',
        builder: (context, state) => const PFARegistrationScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const PFAProfileScreen(),
      ),
      GoRoute(
        path: '/transactions',
        name: 'transactions',
        builder: (context, state) => const TransactionsScreen(),
      ),
      GoRoute(
        path: '/reports',
        name: 'reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/invoices',
        name: 'invoices',
        builder: (context, state) => const ANAFInvoicesScreen(),
      ),
      GoRoute(
        path: '/help',
        name: 'help',
        builder: (context, state) {
          final initialTerm = state.uri.queryParameters['term'];
          return HelpScreen(initialTerm: initialTerm);
        },
      ),
    ],
    redirect: (context, state) {
      // Don't redirect if we're already on splash
      if (state.matchedLocation == '/splash') {
        return null;
      }

      final isPFARegistered = StorageService.isPFARegistered();

      // If PFA is not registered and trying to access protected routes
      if (!isPFARegistered && state.matchedLocation != '/registration') {
        return '/registration';
      }

      return null;
    },
  );
}

/// Internal splash screen widget
class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkPFAStatus();
  }

  Future<void> _checkPFAStatus() async {
    // Simulate a small delay for splash screen
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // Check if PFA is registered and navigate accordingly
    final isPFARegistered = StorageService.isPFARegistered();

    if (mounted) {
      context.go(isPFARegistered ? '/' : '/registration');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary,
              colorScheme.primary.withOpacity(0.8),
              colorScheme.secondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 72,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'PFA Helper',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Contabilitate simplificată pentru PFA',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                    strokeWidth: 3,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
