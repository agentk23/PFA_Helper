import 'package:flutter/material.dart';
import 'dart:async';
import 'services/storage_service.dart';
import 'screens/pfa_registration_screen.dart';
import 'screens/home_screen.dart';
import 'utils/error_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set up global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    ErrorHandler.logError(
      'Flutter Error',
      details.exception,
      details.stack,
    );
  };

  // Handle errors in async operations
  runZonedGuarded(
    () async {
      // Initialize Hive storage
      try {
        await StorageService.initialize();
      } catch (e, stackTrace) {
        ErrorHandler.logError('Storage Initialization', e, stackTrace);
        // Continue anyway - app can still function without data
      }

      runApp(const PFAHelperApp());
    },
    (error, stackTrace) {
      ErrorHandler.logError('Uncaught Error', error, stackTrace);
    },
  );
}

class PFAHelperApp extends StatelessWidget {
  const PFAHelperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PFA Helper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Color(0xFF1565C0), // Colors.blue.shade800
          foregroundColor: Colors.white,
        ),
        cardTheme: const CardTheme(
          elevation: 2,
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: const Color(0xFFFAFAFA), // Colors.grey.shade50
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkPFAStatus();
  }

  Future<void> _checkPFAStatus() async {
    // Simulate a small delay for splash screen
    await Future.delayed(const Duration(seconds: 1));

    // Check if PFA is registered
    final isPFARegistered = StorageService.isPFARegistered();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => isPFARegistered
              ? const HomeScreen()
              : const PFARegistrationScreen(),
        ),
      );
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
