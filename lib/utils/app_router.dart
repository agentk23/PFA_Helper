import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/pfa_registration_screen.dart';
import '../screens/transactions_screen.dart';
import '../screens/reports_screen.dart';
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
        path: '/transactions',
        name: 'transactions',
        builder: (context, state) => const TransactionsScreen(),
      ),
      GoRoute(
        path: '/reports',
        name: 'reports',
        builder: (context, state) => const ReportsScreen(),
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
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade800, Colors.blue.shade400],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  size: 80,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'PFA Helper',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Contabilitate simplificată pentru PFA',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
