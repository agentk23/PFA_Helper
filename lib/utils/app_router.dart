import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/pfa_registration_screen.dart';
import '../screens/transactions_screen.dart';
import '../screens/reports_screen.dart';
import '../services/storage_service.dart';

/// Application routing configuration
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // Check if PFA is registered
      final pfa = StorageService.getPFA();
      final isRegistered = pfa != null;

      // If not registered and not on registration page, redirect to registration
      if (!isRegistered && state.matchedLocation != '/register') {
        return '/register';
      }

      // If registered and on registration page, redirect to home
      if (isRegistered && state.matchedLocation == '/register') {
        return '/';
      }

      return null; // No redirect needed
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
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
  );
}
