import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../models/pfa.dart';
import '../models/transaction.dart';
import '../models/tax_report.dart';
import '../utils/tax_calculator.dart';

/// Home screen showing PFA overview and quick stats
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PFA? _pfa;
  List<Transaction> _transactions = [];
  final _currencyFormat = NumberFormat.currency(locale: 'ro_RO', symbol: 'RON');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _pfa = StorageService.getPFA();
      _transactions = StorageService.getAllTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final endOfYear = DateTime(now.year, 12, 31, 23, 59, 59);

    final yearReport = TaxCalculator.calculateTaxReport(
      transactions: _transactions,
      startDate: startOfYear,
      endDate: endOfYear,
      taxationSystem: _pfa?.taxationSystem ?? TaxationSystem.realIncome,
    );

    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final monthReport = TaxCalculator.calculateTaxReport(
      transactions: _transactions,
      startDate: startOfMonth,
      endDate: endOfMonth,
      taxationSystem: _pfa?.taxationSystem ?? TaxationSystem.realIncome,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('PFA Helper'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.push('/register');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PFA Info Card
              _buildPFAInfoCard(),
              const SizedBox(height: 24),

              // Quick Stats
              Text(
                'Luna curentă',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _buildMonthlyStatsCard(monthReport),
              const SizedBox(height: 24),

              // Year Stats
              Text(
                'Anul ${now.year}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _buildYearlyStatsCard(yearReport),
              const SizedBox(height: 24),

              // Quick Actions
              _buildQuickActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPFAInfoCard() {
    if (_pfa == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _pfa!.fullName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'CUI: ${_pfa!.cui}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Cod CAEN', '${_pfa!.caenCode} - ${_pfa!.caenDescription}'),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Sistem taxare',
              _pfa!.taxationSystem == TaxationSystem.realIncome
                  ? 'Venit real'
                  : 'Norme de venit',
            ),
            if (_pfa!.isVATRegistered) ...[
              const SizedBox(height: 8),
              _buildInfoRow('TVA', 'Înregistrat'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyStatsCard(TaxReport report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatRow(
              'Venituri',
              _currencyFormat.format(report.totalIncome),
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              'Cheltuieli deductibile',
              _currencyFormat.format(report.deductibleExpenses),
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              'Venit net',
              _currencyFormat.format(report.netIncome),
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearlyStatsCard(TaxReport report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatRow(
              'Venituri totale',
              _currencyFormat.format(report.totalIncome),
              Colors.green,
            ),
            const Divider(height: 24),
            _buildStatRow(
              'Impozit venit (10%)',
              _currencyFormat.format(report.incomeTax),
              Colors.red,
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              'CAS (25%)',
              _currencyFormat.format(report.cas),
              Colors.red,
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              'CASS (10%)',
              _currencyFormat.format(report.cass),
              Colors.red,
            ),
            const Divider(height: 24),
            _buildStatRow(
              'Total taxe',
              _currencyFormat.format(report.totalTaxes),
              Colors.red.shade700,
              isLarge: true,
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              'Profit net',
              _currencyFormat.format(report.netProfit),
              Colors.green.shade700,
              isLarge: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color, {bool isLarge = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isLarge ? 16 : 14,
            fontWeight: isLarge ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isLarge ? 18 : 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            context.push('/transactions');
          },
          icon: const Icon(Icons.add),
          label: const Text('Adaugă tranzacție'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            context.push('/reports');
          },
          icon: const Icon(Icons.assessment),
          label: const Text('Vezi rapoarte detaliate'),
        ),
      ],
    );
  }
}
