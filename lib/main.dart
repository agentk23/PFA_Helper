import 'package:flutter/material.dart';
import 'dart:async';
import 'services/storage_service.dart';
import 'utils/error_handler.dart';
import 'utils/app_router.dart';

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
    return MaterialApp.router(
      title: 'PFA Helper',
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
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
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: const Color(0xFFFAFAFA), // Colors.grey.shade50
        ),
      ),
    );
  }
}
