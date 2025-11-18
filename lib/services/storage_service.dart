import 'package:hive_flutter/hive_flutter.dart';
import '../models/pfa.dart';
import '../models/transaction.dart';
import '../models/caen_code.dart';
import '../models/transaction_category.dart';

/// Service for managing local data storage with Hive
class StorageService {
  static const String pfaBoxName = 'pfa';
  static const String transactionsBoxName = 'transactions';
  static const String categoriesBoxName = 'categories';

  static Box<PFA>? _pfaBox;
  static Box<Transaction>? _transactionsBox;
  static Box<TransactionCategory>? _categoriesBox;

  /// Initialize Hive and open boxes
  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(PFAAdapter());
    Hive.registerAdapter(TransactionAdapter());
    Hive.registerAdapter(TransactionCategoryAdapter());
    Hive.registerAdapter(CaenCodeAdapter());

    // Open boxes
    _pfaBox = await Hive.openBox<PFA>(pfaBoxName);
    _transactionsBox = await Hive.openBox<Transaction>(transactionsBoxName);
    _categoriesBox =
        await Hive.openBox<TransactionCategory>(categoriesBoxName);

    // Initialize default categories if empty
    if (_categoriesBox!.isEmpty) {
      await _initializeDefaultCategories();
    }
  }

  /// Initialize default transaction categories
  static Future<void> _initializeDefaultCategories() async {
    final defaultCategories = [
      TransactionCategory(
        name: 'Servicii IT',
        description: 'Venituri din servicii IT',
        isDeductible: true,
      ),
      TransactionCategory(
        name: 'Consultanță',
        description: 'Venituri din consultanță',
        isDeductible: true,
      ),
      TransactionCategory(
        name: 'Utilități',
        description: 'Cheltuieli utilități (electricitate, internet)',
        isDeductible: true,
      ),
      TransactionCategory(
        name: 'Echipamente',
        description: 'Achiziție echipamente și software',
        isDeductible: true,
      ),
      TransactionCategory(
        name: 'Chirii',
        description: 'Chirie spațiu de lucru',
        isDeductible: true,
      ),
      TransactionCategory(
        name: 'Transport',
        description: 'Cheltuieli transport',
        isDeductible: true,
      ),
      TransactionCategory(
        name: 'Marketing',
        description: 'Cheltuieli marketing și publicitate',
        isDeductible: true,
      ),
      TransactionCategory(
        name: 'Formare profesională',
        description: 'Cursuri și training',
        isDeductible: true,
      ),
      TransactionCategory(
        name: 'Altele',
        description: 'Alte venituri/cheltuieli',
        isDeductible: false,
      ),
    ];

    for (var category in defaultCategories) {
      await _categoriesBox!.add(category);
    }
  }

  // PFA methods
  static PFA? getPFA() {
    return _pfaBox?.get('current');
  }

  static Future<void> savePFA(PFA pfa) async {
    await _pfaBox?.put('current', pfa);
  }

  static Future<void> deletePFA() async {
    await _pfaBox?.delete('current');
  }

  // Transaction methods
  static List<Transaction> getAllTransactions() {
    return _transactionsBox?.values.toList() ?? [];
  }

  static List<Transaction> getTransactionsByPeriod(
    DateTime start,
    DateTime end,
  ) {
    final all = getAllTransactions();
    return all.where((t) {
      return t.date.isAfter(start.subtract(const Duration(days: 1))) &&
          t.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  static Future<void> saveTransaction(Transaction transaction) async {
    await _transactionsBox?.put(transaction.id, transaction);
  }

  static Future<void> deleteTransaction(String id) async {
    await _transactionsBox?.delete(id);
  }

  // Category methods
  static List<TransactionCategory> getAllCategories() {
    return _categoriesBox?.values.toList() ?? [];
  }

  static Future<void> saveCategory(TransactionCategory category) async {
    await _categoriesBox?.add(category);
  }

  // Clear all data
  static Future<void> clearAll() async {
    await _pfaBox?.clear();
    await _transactionsBox?.clear();
    await _categoriesBox?.clear();
    await _initializeDefaultCategories();
  }
}
