import 'package:flutter_test/flutter_test.dart';
import 'package:pfa_helper/models/transaction.dart';
import 'package:pfa_helper/models/transaction_category.dart';

void main() {
  group('Transaction Model Tests', () {
    test('Transaction should be created with required fields', () {
      final transaction = Transaction(
        id: 'txn_1',
        amount: 5000.0,
        date: DateTime(2024, 1, 15),
        category: TransactionCategory.taxableIncome,
        description: 'Software development services',
        createdAt: DateTime.now(),
      );

      expect(transaction.id, 'txn_1');
      expect(transaction.amount, 5000.0);
      expect(transaction.category, TransactionCategory.taxableIncome);
      expect(transaction.description, 'Software development services');
    });

    test('Transaction should identify income transactions', () {
      final taxableIncome = Transaction(
        id: 'txn_1',
        amount: 5000.0,
        date: DateTime(2024, 1, 15),
        category: TransactionCategory.taxableIncome,
        description: 'Income',
        createdAt: DateTime.now(),
      );

      final nonTaxableIncome = Transaction(
        id: 'txn_2',
        amount: 1000.0,
        date: DateTime(2024, 1, 15),
        category: TransactionCategory.nonTaxableIncome,
        description: 'Gift',
        createdAt: DateTime.now(),
      );

      expect(taxableIncome.isIncome, true);
      expect(nonTaxableIncome.isIncome, true);
    });

    test('Transaction should identify expense transactions', () {
      final deductibleExpense = Transaction(
        id: 'txn_1',
        amount: 500.0,
        date: DateTime(2024, 1, 15),
        category: TransactionCategory.deductibleExpense,
        description: 'Office supplies',
        createdAt: DateTime.now(),
      );

      final nonDeductibleExpense = Transaction(
        id: 'txn_2',
        amount: 200.0,
        date: DateTime(2024, 1, 15),
        category: TransactionCategory.nonDeductibleExpense,
        description: 'Personal expense',
        createdAt: DateTime.now(),
      );

      expect(deductibleExpense.isExpense, true);
      expect(nonDeductibleExpense.isExpense, true);
    });

    test('Transaction should use custom tax rate when set', () {
      final transaction = Transaction(
        id: 'txn_1',
        amount: 5000.0,
        date: DateTime(2024, 1, 15),
        category: TransactionCategory.taxableIncome,
        description: 'Special rate income',
        createdAt: DateTime.now(),
        customTaxRate: 0.05, // Custom 5% rate
      );

      final effectiveRate = transaction.getEffectiveTaxRate();
      expect(effectiveRate, 0.05);
    });

    test('Transaction should use 3% rate for IT CAEN codes', () {
      final transaction = Transaction(
        id: 'txn_1',
        amount: 5000.0,
        date: DateTime(2024, 1, 15),
        category: TransactionCategory.taxableIncome,
        description: 'Software development',
        createdAt: DateTime.now(),
        caenCode: '6201',
      );

      final specialRateCodes = ['6201', '6202', '6209', '6210'];
      final effectiveRate = transaction.getEffectiveTaxRate(
        specialRateCodes: specialRateCodes,
      );
      expect(effectiveRate, 0.03);
    });

    test('Transaction should use 10% standard rate for non-IT CAEN codes', () {
      final transaction = Transaction(
        id: 'txn_1',
        amount: 5000.0,
        date: DateTime(2024, 1, 15),
        category: TransactionCategory.taxableIncome,
        description: 'Consulting services',
        createdAt: DateTime.now(),
        caenCode: '7022', // Business consulting
      );

      final specialRateCodes = ['6201', '6202', '6209', '6210'];
      final effectiveRate = transaction.getEffectiveTaxRate(
        specialRateCodes: specialRateCodes,
      );
      expect(effectiveRate, 0.10);
    });

    test('Transaction should use 10% default rate when no CAEN code', () {
      final transaction = Transaction(
        id: 'txn_1',
        amount: 5000.0,
        date: DateTime(2024, 1, 15),
        category: TransactionCategory.taxableIncome,
        description: 'General income',
        createdAt: DateTime.now(),
      );

      final effectiveRate = transaction.getEffectiveTaxRate();
      expect(effectiveRate, 0.10);
    });

    test('Transaction should prioritize custom rate over CAEN rate', () {
      final transaction = Transaction(
        id: 'txn_1',
        amount: 5000.0,
        date: DateTime(2024, 1, 15),
        category: TransactionCategory.taxableIncome,
        description: 'Special case',
        createdAt: DateTime.now(),
        caenCode: '6201', // Would normally be 3%
        customTaxRate: 0.15, // Custom 15% rate
      );

      final specialRateCodes = ['6201', '6202'];
      final effectiveRate = transaction.getEffectiveTaxRate(
        specialRateCodes: specialRateCodes,
      );
      expect(effectiveRate, 0.15); // Custom rate takes priority
    });

    test('Transaction.copyWith should update specified fields', () {
      final original = Transaction(
        id: 'txn_1',
        amount: 5000.0,
        date: DateTime(2024, 1, 15),
        category: TransactionCategory.taxableIncome,
        description: 'Original description',
        createdAt: DateTime.now(),
      );

      final updated = original.copyWith(
        amount: 6000.0,
        description: 'Updated description',
      );

      expect(updated.amount, 6000.0);
      expect(updated.description, 'Updated description');
      expect(updated.id, 'txn_1'); // Unchanged
      expect(updated.category, TransactionCategory.taxableIncome); // Unchanged
    });

    test('Transaction should accept optional invoice number and notes', () {
      final transaction = Transaction(
        id: 'txn_1',
        amount: 5000.0,
        date: DateTime(2024, 1, 15),
        category: TransactionCategory.taxableIncome,
        description: 'Services',
        invoiceNumber: 'INV-2024-001',
        notes: 'Additional details about this transaction',
        createdAt: DateTime.now(),
      );

      expect(transaction.invoiceNumber, 'INV-2024-001');
      expect(transaction.notes, 'Additional details about this transaction');
    });
  });
}
