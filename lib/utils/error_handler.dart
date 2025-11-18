import 'dart:developer' as developer;

/// Global error handler for logging and debugging
class ErrorHandler {
  static void logError(
    String context,
    Object error,
    StackTrace? stackTrace,
  ) {
    developer.log(
      'Error in $context: $error',
      name: 'pfa_helper',
      level: 1000, // SEVERE
      error: error,
      stackTrace: stackTrace,
    );
  }
}
