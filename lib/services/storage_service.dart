import 'package:hive_flutter/hive_flutter.dart';
import '../models/pfa.dart';
import '../models/transaction.dart';
import '../models/transaction_category.dart';
import '../models/caen_code.dart';
import '../utils/error_handler.dart';

/// Service for managing local storage with Hive
/// All methods include error handling to prevent app crashes
class StorageService {
  static const String pfaBoxName = 'pfa_box';
  static const String transactionsBoxName = 'transactions_box';

  /// Initialize Hive and register adapters
  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(PFAAdapter());
    Hive.registerAdapter(TransactionAdapter());
    Hive.registerAdapter(TransactionCategoryAdapter());
    Hive.registerAdapter(CAENCodeAdapter());

    // Open boxes
    await Hive.openBox<PFA>(pfaBoxName);
    await Hive.openBox<Transaction>(transactionsBoxName);
  }

  /// Get PFA box
  static Box<PFA> getPFABox() {
    return Hive.box<PFA>(pfaBoxName);
  }

  /// Get transactions box
  static Box<Transaction> getTransactionsBox() {
    return Hive.box<Transaction>(transactionsBoxName);
  }

  /// Save PFA information
  static Future<void> savePFA(PFA pfa) async {
    final box = getPFABox();
    await box.put('current_pfa', pfa);
  }

  /// Get current PFA
  static PFA? getCurrentPFA() {
    try {
      final box = getPFABox();
      return box.get('current_pfa');
    } catch (e, stackTrace) {
      ErrorHandler.logError('getCurrentPFA', e, stackTrace);
      return null;
    }
  }

  /// Check if PFA is registered
  static bool isPFARegistered() {
    try {
      return getCurrentPFA() != null;
    } catch (e, stackTrace) {
      ErrorHandler.logError('isPFARegistered', e, stackTrace);
      return false;
    }
  }

  /// Add transaction
  static Future<void> addTransaction(Transaction transaction) async {
    final box = getTransactionsBox();
    await box.put(transaction.id, transaction);
  }

  /// Update transaction
  static Future<void> updateTransaction(Transaction transaction) async {
    final box = getTransactionsBox();
    await box.put(transaction.id, transaction);
  }

  /// Delete transaction
  static Future<void> deleteTransaction(String transactionId) async {
    final box = getTransactionsBox();
    await box.delete(transactionId);
  }

  /// Get all transactions
  static List<Transaction> getAllTransactions() {
    try {
      final box = getTransactionsBox();
      return box.values.toList();
    } catch (e, stackTrace) {
      ErrorHandler.logError('getAllTransactions', e, stackTrace);
      return [];
    }
  }

  /// Get transactions for a specific year
  static List<Transaction> getTransactionsByYear(int year) {
    try {
      final allTransactions = getAllTransactions();
      return allTransactions.where((t) => t.date.year == year).toList();
    } catch (e, stackTrace) {
      ErrorHandler.logError('getTransactionsByYear', e, stackTrace);
      return [];
    }
  }

  /// Get transactions for a specific month
  static List<Transaction> getTransactionsByMonth(int year, int month) {
    try {
      final allTransactions = getAllTransactions();
      return allTransactions
          .where((t) => t.date.year == year && t.date.month == month)
          .toList();
    } catch (e, stackTrace) {
      ErrorHandler.logError('getTransactionsByMonth', e, stackTrace);
      return [];
    }
  }

  /// Get transactions for a specific category
  static List<Transaction> getTransactionsByCategory(
      TransactionCategory category) {
    try {
      final allTransactions = getAllTransactions();
      return allTransactions.where((t) => t.category == category).toList();
    } catch (e, stackTrace) {
      ErrorHandler.logError('getTransactionsByCategory', e, stackTrace);
      return [];
    }
  }

  /// Clear all data
  static Future<void> clearAllData() async {
    final pfaBox = getPFABox();
    final transactionsBox = getTransactionsBox();
    await pfaBox.clear();
    await transactionsBox.clear();
  }

  /// Close all boxes
  static Future<void> closeBoxes() async {
    await Hive.close();
  }
}
