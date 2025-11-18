import 'package:flutter_test/flutter_test.dart';
import 'package:pfa_helper/models/transaction.dart';
import 'package:pfa_helper/models/transaction_category.dart';
import 'package:pfa_helper/utils/tax_calculator.dart';

void main() {
  group('Tax Calculator Tests - Romanian PFA 2025', () {
    test('Should calculate 10% income tax for standard transactions', () {
      final transactions = [
        Transaction(
          id: 'txn_1',
          amount: 100000.0, // 100,000 RON income
          date: DateTime(2024, 1, 15),
          category: TransactionCategory.taxableIncome,
          description: 'Consulting services',
          createdAt: DateTime.now(),
        ),
        Transaction(
          id: 'txn_2',
          amount: 20000.0, // 20,000 RON expenses
          date: DateTime(2024, 2, 15),
          category: TransactionCategory.deductibleExpense,
          description: 'Office supplies',
          createdAt: DateTime.now(),
        ),
      ];

      final report = TaxCalculator.calculateAnnualReport(transactions, 2024);

      expect(report.totalTaxableIncome, 100000.0);
      expect(report.totalDeductibleExpenses, 20000.0);
      expect(report.netTaxableIncome, 80000.0);
      expect(report.incomeTax, 8000.0); // 10% of 80,000
    });

    test('Should calculate 3% income tax for IT CAEN codes', () {
      final transactions = [
        Transaction(
          id: 'txn_1',
          amount: 100000.0,
          date: DateTime(2024, 1, 15),
          category: TransactionCategory.taxableIncome,
          description: 'Software development',
          caenCode: '6201', // IT special rate
          createdAt: DateTime.now(),
        ),
        Transaction(
          id: 'txn_2',
          amount: 20000.0,
          date: DateTime(2024, 2, 15),
          category: TransactionCategory.deductibleExpense,
          description: 'Development tools',
          createdAt: DateTime.now(),
        ),
      ];

      final report = TaxCalculator.calculateAnnualReport(transactions, 2024);

      expect(report.incomeAt3PercentRate, 100000.0);
      expect(report.netTaxableIncome, 80000.0);
      expect(report.incomeTax, 2400.0); // 3% of 80,000
    });

    test('Should calculate mixed rates for multiple CAEN codes', () {
      final transactions = [
        Transaction(
          id: 'txn_1',
          amount: 60000.0,
          date: DateTime(2024, 1, 15),
          category: TransactionCategory.taxableIncome,
          description: 'Software development',
          caenCode: '6201', // 3% rate
          createdAt: DateTime.now(),
        ),
        Transaction(
          id: 'txn_2',
          amount: 40000.0,
          date: DateTime(2024, 2, 15),
          category: TransactionCategory.taxableIncome,
          description: 'Business consulting',
          caenCode: '7022', // 10% rate
          createdAt: DateTime.now(),
        ),
        Transaction(
          id: 'txn_3',
          amount: 20000.0,
          date: DateTime(2024, 3, 15),
          category: TransactionCategory.deductibleExpense,
          description: 'Office expenses',
          createdAt: DateTime.now(),
        ),
      ];

      final report = TaxCalculator.calculateAnnualReport(transactions, 2024);

      expect(report.totalTaxableIncome, 100000.0);
      expect(report.incomeAt3PercentRate, 60000.0);
      expect(report.incomeAt10PercentRate, 40000.0);
      expect(report.totalDeductibleExpenses, 20000.0);

      // Proportional expense allocation:
      // 60% of expenses to 3% income: 12,000
      // 40% of expenses to 10% income: 8,000
      // Tax: (60,000 - 12,000) * 0.03 + (40,000 - 8,000) * 0.10
      //    = 48,000 * 0.03 + 32,000 * 0.10 = 1,440 + 3,200 = 4,640
      expect(report.incomeTax, closeTo(4640.0, 0.1));
    });

    test('Should calculate zero CAS for income below 48,600 RON', () {
      final transactions = [
        Transaction(
          id: 'txn_1',
          amount: 40000.0,
          date: DateTime(2024, 1, 15),
          category: TransactionCategory.taxableIncome,
          description: 'Services',
          createdAt: DateTime.now(),
        ),
      ];

      final report = TaxCalculator.calculateAnnualReport(transactions, 2024);

      expect(report.netTaxableIncome, 40000.0);
      expect(report.casContribution, 0.0); // Below 12 minimum salaries
    });

    test('Should calculate 12,150 RON CAS for income >= 48,600 RON', () {
      final transactions = [
        Transaction(
          id: 'txn_1',
          amount: 50000.0,
          date: DateTime(2024, 1, 15),
          category: TransactionCategory.taxableIncome,
          description: 'Services',
          createdAt: DateTime.now(),
        ),
      ];

      final report = TaxCalculator.calculateAnnualReport(transactions, 2024);

      expect(report.netTaxableIncome, 50000.0);
      expect(report.casContribution, 12150.0); // Fixed for 12-24 min salaries
    });

    test('Should calculate 24,300 RON CAS for income >= 97,200 RON', () {
      final transactions = [
        Transaction(
          id: 'txn_1',
          amount: 100000.0,
          date: DateTime(2024, 1, 15),
          category: TransactionCategory.taxableIncome,
          description: 'Services',
          createdAt: DateTime.now(),
        ),
      ];

      final report = TaxCalculator.calculateAnnualReport(transactions, 2024);

      expect(report.netTaxableIncome, 100000.0);
      expect(report.casContribution, 24300.0); // Fixed for >= 24 min salaries
    });

    test('Should calculate minimum 2,430 RON CASS for low income', () {
      final transactions = [
        Transaction(
          id: 'txn_1',
          amount: 10000.0,
          date: DateTime(2024, 1, 15),
          category: TransactionCategory.taxableIncome,
          description: 'Services',
          createdAt: DateTime.now(),
        ),
      ];

      final report = TaxCalculator.calculateAnnualReport(transactions, 2024);

      expect(report.netTaxableIncome, 10000.0);
      expect(report.cassContribution, 2430.0); // Minimum CASS
    });

    test('Should calculate 10% CASS for medium income', () {
      final transactions = [
        Transaction(
          id: 'txn_1',
          amount: 100000.0,
          date: DateTime(2024, 1, 15),
          category: TransactionCategory.taxableIncome,
          description: 'Services',
          createdAt: DateTime.now(),
        ),
      ];

      final report = TaxCalculator.calculateAnnualReport(transactions, 2024);

      expect(report.netTaxableIncome, 100000.0);
      expect(report.cassContribution, 10000.0); // 10% of 100,000
    });

    test('Should calculate maximum 24,300 RON CASS for high income', () {
      final transactions = [
        Transaction(
          id: 'txn_1',
          amount: 300000.0,
          date: DateTime(2024, 1, 15),
          category: TransactionCategory.taxableIncome,
          description: 'Services',
          createdAt: DateTime.now(),
        ),
      ];

      final report = TaxCalculator.calculateAnnualReport(transactions, 2024);

      expect(report.netTaxableIncome, 300000.0);
      expect(report.cassContribution, 24300.0); // Maximum CASS
    });

    test('Should require VAT registration above 395,000 RON', () {
      final transactions = [
        Transaction(
          id: 'txn_1',
          amount: 400000.0,
          date: DateTime(2024, 1, 15),
          category: TransactionCategory.taxableIncome,
          description: 'Services',
          createdAt: DateTime.now(),
        ),
      ];

      final report = TaxCalculator.calculateAnnualReport(transactions, 2024);

      expect(report.totalIncome, 400000.0);
      expect(report.requiresVATRegistration, true);
    });

    test('Should not require VAT registration below 395,000 RON', () {
      final transactions = [
        Transaction(
          id: 'txn_1',
          amount: 390000.0,
          date: DateTime(2024, 1, 15),
          category: TransactionCategory.taxableIncome,
          description: 'Services',
          createdAt: DateTime.now(),
        ),
      ];

      final report = TaxCalculator.calculateAnnualReport(transactions, 2024);

      expect(report.totalIncome, 390000.0);
      expect(report.requiresVATRegistration, false);
    });

    test('Should exclude non-taxable income from tax calculations', () {
      final transactions = [
        Transaction(
          id: 'txn_1',
          amount: 50000.0,
          date: DateTime(2024, 1, 15),
          category: TransactionCategory.taxableIncome,
          description: 'Services',
          createdAt: DateTime.now(),
        ),
        Transaction(
          id: 'txn_2',
          amount: 10000.0,
          date: DateTime(2024, 2, 15),
          category: TransactionCategory.nonTaxableIncome,
          description: 'Gift',
          createdAt: DateTime.now(),
        ),
      ];

      final report = TaxCalculator.calculateAnnualReport(transactions, 2024);

      expect(report.totalIncome, 60000.0);
      expect(report.totalTaxableIncome, 50000.0);
      expect(report.totalNonTaxableIncome, 10000.0);
      expect(report.incomeTax, 5000.0); // 10% of 50,000 only
    });

    test('Should exclude non-deductible expenses from tax calculations', () {
      final transactions = [
        Transaction(
          id: 'txn_1',
          amount: 100000.0,
          date: DateTime(2024, 1, 15),
          category: TransactionCategory.taxableIncome,
          description: 'Services',
          createdAt: DateTime.now(),
        ),
        Transaction(
          id: 'txn_2',
          amount: 15000.0,
          date: DateTime(2024, 2, 15),
          category: TransactionCategory.deductibleExpense,
          description: 'Business expense',
          createdAt: DateTime.now(),
        ),
        Transaction(
          id: 'txn_3',
          amount: 5000.0,
          date: DateTime(2024, 3, 15),
          category: TransactionCategory.nonDeductibleExpense,
          description: 'Personal expense',
          createdAt: DateTime.now(),
        ),
      ];

      final report = TaxCalculator.calculateAnnualReport(transactions, 2024);

      expect(report.totalExpenses, 20000.0);
      expect(report.totalDeductibleExpenses, 15000.0);
      expect(report.totalNonDeductibleExpenses, 5000.0);
      expect(report.netTaxableIncome, 85000.0); // 100,000 - 15,000 only
    });

    test('Should filter transactions by year', () {
      final transactions = [
        Transaction(
          id: 'txn_1',
          amount: 50000.0,
          date: DateTime(2024, 1, 15),
          category: TransactionCategory.taxableIncome,
          description: '2024 income',
          createdAt: DateTime.now(),
        ),
        Transaction(
          id: 'txn_2',
          amount: 30000.0,
          date: DateTime(2023, 12, 15),
          category: TransactionCategory.taxableIncome,
          description: '2023 income',
          createdAt: DateTime.now(),
        ),
      ];

      final report2024 = TaxCalculator.calculateAnnualReport(transactions, 2024);
      final report2023 = TaxCalculator.calculateAnnualReport(transactions, 2023);

      expect(report2024.totalTaxableIncome, 50000.0);
      expect(report2023.totalTaxableIncome, 30000.0);
    });

    test('Should calculate total taxes correctly', () {
      final transactions = [
        Transaction(
          id: 'txn_1',
          amount: 100000.0,
          date: DateTime(2024, 1, 15),
          category: TransactionCategory.taxableIncome,
          description: 'Services',
          createdAt: DateTime.now(),
        ),
      ];

      final report = TaxCalculator.calculateAnnualReport(transactions, 2024);

      // Income tax: 10,000 (10% of 100,000)
      // CAS: 24,300 (>= 24 min salaries)
      // CASS: 10,000 (10% of 100,000)
      // Total: 44,300
      expect(report.totalTaxes, 44300.0);
    });

    test('Should calculate net profit after taxes', () {
      final transactions = [
        Transaction(
          id: 'txn_1',
          amount: 100000.0,
          date: DateTime(2024, 1, 15),
          category: TransactionCategory.taxableIncome,
          description: 'Services',
          createdAt: DateTime.now(),
        ),
        Transaction(
          id: 'txn_2',
          amount: 10000.0,
          date: DateTime(2024, 2, 15),
          category: TransactionCategory.deductibleExpense,
          description: 'Expenses',
          createdAt: DateTime.now(),
        ),
      ];

      final report = TaxCalculator.calculateAnnualReport(transactions, 2024);

      // Net taxable: 90,000
      // Income tax: 9,000 (10% of 90,000)
      // CAS: 12,150 (>= 12 min salaries, < 24 min salaries)
      // CASS: 9,000 (10% of 90,000)
      // Total taxes: 9,000 + 12,150 + 9,000 = 30,150
      // Net profit: 90,000 - 30,150 = 59,850
      expect(report.netTaxableIncome, 90000.0);
      expect(report.totalTaxes, 30150.0);
      expect(report.netProfitAfterTaxes, closeTo(59850.0, 0.1));
    });
  });
}
