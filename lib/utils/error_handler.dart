import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Global error handler for the application
class ErrorHandler {
  /// Log error for debugging
  static void logError(String context, dynamic error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      developer.log(
        '❌ Error in $context: $error',
        name: 'PFAHelper',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Show error snackbar to user
  static void showErrorSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show success snackbar to user
  static void showSuccessSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show warning snackbar to user
  static void showWarningSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_outlined, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Handle and display error with context-aware messaging
  static void handleError(
    BuildContext context,
    String operation,
    dynamic error, [
    StackTrace? stackTrace,
  ]) {
    logError(operation, error, stackTrace);

    String userMessage = _getUserFriendlyMessage(operation, error);
    showErrorSnackBar(context, userMessage);
  }

  /// Convert technical errors to user-friendly messages
  static String _getUserFriendlyMessage(String operation, dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('locale') || errorString.contains('initializeDateFormatting')) {
      return 'Eroare la formatarea datei. Vă rugăm să reporniți aplicația.';
    } else if (errorString.contains('hive') || errorString.contains('database')) {
      return 'Eroare la salvarea datelor. Vă rugăm să încercați din nou.';
    } else if (errorString.contains('pdf')) {
      return 'Eroare la generarea PDF. Verificați spațiul de stocare.';
    } else if (errorString.contains('permission')) {
      return 'Permisiuni necesare. Verificați setările aplicației.';
    } else if (errorString.contains('network') || errorString.contains('internet')) {
      return 'Eroare de conexiune. Verificați conexiunea la internet.';
    } else if (errorString.contains('format')) {
      return 'Eroare la formatarea datelor. Verificați informațiile introduse.';
    } else {
      return 'Eroare la $operation. Vă rugăm să încercați din nou.';
    }
  }

  /// Show error dialog for critical errors
  static Future<void> showErrorDialog(
    BuildContext context,
    String title,
    String message, {
    VoidCallback? onRetry,
  }) async {
    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onRetry();
              },
              child: const Text('Reîncercare'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Închide'),
          ),
        ],
      ),
    );
  }
}
