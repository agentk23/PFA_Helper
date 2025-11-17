import 'package:flutter/material.dart';
import '../models/pfa.dart';
import '../models/transaction.dart';
import '../services/storage_service.dart';
import '../utils/tax_calculator.dart';
import '../utils/safe_formatters.dart';
import '../utils/error_handler.dart';
import 'transactions_screen.dart';
import 'reports_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PFA? _pfa;
  List<Transaction> _transactions = [];
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    try {
      setState(() {
        _pfa = StorageService.getCurrentPFA();
        _transactions = StorageService.getTransactionsByYear(_selectedYear);
      });
    } catch (e, stackTrace) {
      ErrorHandler.logError('_loadData', e, stackTrace);
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          'Eroare la încărcarea datelor. Vă rugăm să reporniți aplicația.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pfa == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final taxReport = TaxCalculator.calculateAnnualReport(_transactions, _selectedYear);
    final currentMonthSummary = TaxCalculator.calculateMonthlySummary(
      StorageService.getAllTransactions(),
      DateTime.now().year,
      DateTime.now().month,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('PFA Helper'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'year') {
                _showYearPicker();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'year',
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 8),
                    Text('An: $_selectedYear'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // PFA Info Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue.shade800,
                          child: const Icon(Icons.business, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _pfa!.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'CUI: ${_pfa!.cui}',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoChip(
                            Icons.work,
                            _pfa!.activityType,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildInfoChip(
                            Icons.calculate,
                            _pfa!.isRealSystem ? 'Sistem Real' : 'Norme',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Current Month Summary
            Text(
              'Luna curentă (${SafeFormatters.formatDateWithMonth(DateTime.now())})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Venituri',
                    currentMonthSummary['totalIncome']!,
                    Colors.green,
                    Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryCard(
                    'Cheltuieli',
                    currentMonthSummary['totalExpenses']!,
                    Colors.red,
                    Icons.trending_down,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildSummaryCard(
              'Profit net',
              currentMonthSummary['netProfit']!,
              Colors.blue,
              Icons.account_balance_wallet,
            ),
            const SizedBox(height: 24),

            // Annual Summary
            Text(
              'Rezumat anual $_selectedYear',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildReportRow(
                      'Venituri totale',
                      taxReport.totalIncome,
                      Colors.green.shade700,
                    ),
                    const SizedBox(height: 8),
                    _buildReportRow(
                      'Cheltuieli totale',
                      taxReport.totalExpenses,
                      Colors.red.shade700,
                    ),
                    const Divider(height: 24),
                    _buildReportRow(
                      'Venit net impozabil',
                      taxReport.netTaxableIncome,
                      Colors.blue.shade900,
                      true,
                    ),
                    const SizedBox(height: 16),
                    _buildReportRow('Impozit venit (10%)', taxReport.incomeTax),
                    const SizedBox(height: 8),
                    _buildReportRow('CAS (25%)', taxReport.casContribution),
                    const SizedBox(height: 8),
                    _buildReportRow('CASS (10%)', taxReport.cassContribution),
                    const Divider(height: 24),
                    _buildReportRow(
                      'Total taxe',
                      taxReport.totalTaxes,
                      Colors.orange.shade900,
                      true,
                    ),
                    const SizedBox(height: 8),
                    _buildReportRow(
                      'Profit după taxe',
                      taxReport.netProfitAfterTaxes,
                      Colors.green.shade900,
                      true,
                    ),
                  ],
                ),
              ),
            ),

            // VAT Warning
            if (taxReport.requiresVATRegistration) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Atenție! Venit depășește pragul TVA (395.000 RON)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Quick Actions
            const Text(
              'Acțiuni rapide',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TransactionsScreen(),
                        ),
                      );
                      _loadData();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Tranzacții'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReportsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.assessment),
                    label: const Text('Rapoarte'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildSummaryCard(
    String title,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              TaxCalculator.formatCurrency(amount),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportRow(String label, double amount, [Color? color, bool isBold = false]) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 15 : 14,
          ),
        ),
        Text(
          TaxCalculator.formatCurrency(amount),
          style: TextStyle(
            color: color,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 15 : 14,
          ),
        ),
      ],
    );
  }

  void _showYearPicker() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Selectează anul'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: 10,
              itemBuilder: (context, index) {
                final year = DateTime.now().year - index;
                return ListTile(
                  title: Text(year.toString()),
                  selected: year == _selectedYear,
                  onTap: () {
                    setState(() {
                      _selectedYear = year;
                      _loadData();
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
