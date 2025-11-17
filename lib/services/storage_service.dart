import 'package:hive_flutter/hive_flutter.dart';
import '../models/pfa.dart';
import '../models/transaction.dart';
import '../models/transaction_category.dart';
import '../models/caen_code.dart';

/// Service for managing local storage with Hive
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
    final box = getPFABox();
    return box.get('current_pfa');
  }

  /// Check if PFA is registered
  static bool isPFARegistered() {
    return getCurrentPFA() != null;
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
    final box = getTransactionsBox();
    return box.values.toList();
  }

  /// Get transactions for a specific year
  static List<Transaction> getTransactionsByYear(int year) {
    final allTransactions = getAllTransactions();
    return allTransactions.where((t) => t.date.year == year).toList();
  }

  /// Get transactions for a specific month
  static List<Transaction> getTransactionsByMonth(int year, int month) {
    final allTransactions = getAllTransactions();
    return allTransactions
        .where((t) => t.date.year == year && t.date.month == month)
        .toList();
  }

  /// Get transactions for a specific category
  static List<Transaction> getTransactionsByCategory(
      TransactionCategory category) {
    final allTransactions = getAllTransactions();
    return allTransactions.where((t) => t.category == category).toList();
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
