import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../services/pdf_service.dart';
import '../utils/tax_calculator.dart';
import '../models/tax_report.dart';

/// Screen for viewing and generating tax reports
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _startDate = DateTime(DateTime.now().year, 1, 1);
  DateTime _endDate = DateTime.now();
  TaxReport? _report;
  final _currencyFormat = NumberFormat.currency(locale: 'ro_RO', symbol: 'RON');

  @override
  void initState() {
    super.initState();
    _generateReport();
  }

  void _generateReport() {
    final pfa = StorageService.getPFA();
    if (pfa == null) return;

    final transactions = StorageService.getAllTransactions();

    setState(() {
      _report = TaxCalculator.calculateTaxReport(
        transactions: transactions,
        startDate: _startDate,
        endDate: _endDate,
        taxationSystem: pfa.taxationSystem,
      );
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _generateReport();
    }
  }

  Future<void> _generatePDF() async {
    if (_report == null) return;

    final pfa = StorageService.getPFA();
    if (pfa == null) return;

    try {
      final pdfService = PDFService();
      await pdfService.generateTaxReport(
        pfa: pfa,
        report: _report!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Raportul PDF a fost generat și salvat'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la generarea PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rapoarte')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapoarte fiscale'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Generează PDF',
            onPressed: _generatePDF,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date Range Selector
            Card(
              child: ListTile(
                leading: const Icon(Icons.date_range),
                title: const Text('Perioada raportului'),
                subtitle: Text(
                  '${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
                ),
                trailing: const Icon(Icons.edit),
                onTap: _selectDateRange,
              ),
            ),
            const SizedBox(height: 24),

            // Income Section
            Text(
              'Venituri',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildReportRow(
                      'Venituri totale',
                      _currencyFormat.format(_report!.totalIncome),
                      Colors.green,
                    ),
                    const Divider(),
                    _buildReportRow(
                      'Cheltuieli totale',
                      _currencyFormat.format(_report!.totalExpenses),
                      Colors.grey,
                    ),
                    _buildReportRow(
                      'Cheltuieli deductibile',
                      _currencyFormat.format(_report!.deductibleExpenses),
                      Colors.orange,
                    ),
                    const Divider(),
                    _buildReportRow(
                      'Venit net (venit - cheltuieli deductibile)',
                      _currencyFormat.format(_report!.netIncome),
                      Colors.blue,
                      isLarge: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Taxes Section
            Text(
              'Taxe de plată',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildReportRow(
                      'Impozit pe venit (10%)',
                      _currencyFormat.format(_report!.incomeTax),
                      Colors.red,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Calculat pe venitul net: ${_currencyFormat.format(_report!.netIncome)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Divider(height: 24),
                    _buildReportRow(
                      'CAS - Contribuție asigurări sociale (25%)',
                      _currencyFormat.format(_report!.cas),
                      Colors.red,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Minim: ${_currencyFormat.format(TaxCalculator.annualCasMinimum)} (anual)\n'
                      'Maxim: ${_currencyFormat.format(TaxCalculator.annualCasMaximum)} (anual)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Divider(height: 24),
                    _buildReportRow(
                      'CASS - Contribuție asigurări sănătate (10%)',
                      _currencyFormat.format(_report!.cass),
                      Colors.red,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Minim: ${_currencyFormat.format(TaxCalculator.annualCassMinimum)} (anual)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Divider(height: 24),
                    _buildReportRow(
                      'TOTAL TAXE DE PLATĂ',
                      _currencyFormat.format(_report!.totalTaxes),
                      Colors.red.shade900,
                      isLarge: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Net Profit
            Text(
              'Rezultat final',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildReportRow(
                      'Venit net',
                      _currencyFormat.format(_report!.netIncome),
                      Colors.grey.shade700,
                    ),
                    _buildReportRow(
                      'Total taxe',
                      '- ${_currencyFormat.format(_report!.totalTaxes)}',
                      Colors.red.shade700,
                    ),
                    const Divider(height: 24),
                    _buildReportRow(
                      'PROFIT NET (după taxe)',
                      _currencyFormat.format(_report!.netProfit),
                      Colors.green.shade700,
                      isLarge: true,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Rată efectivă de taxare',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '${_report!.effectiveTaxRate.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Statistics
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Statistici',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    _buildStatRow(
                      'Număr tranzacții',
                      _report!.transactionCount.toString(),
                    ),
                    const SizedBox(height: 8),
                    _buildStatRow(
                      'Perioada',
                      '${_report!.endDate.difference(_report!.startDate).inDays + 1} zile',
                    ),
                    const SizedBox(height: 8),
                    _buildStatRow(
                      'Venit mediu zilnic',
                      _currencyFormat.format(
                        _report!.totalIncome / (_report!.endDate.difference(_report!.startDate).inDays + 1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generatePDF,
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text('Generează PDF'),
      ),
    );
  }

  Widget _buildReportRow(String label, String value, Color color, {bool isLarge = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isLarge ? 16 : 14,
                fontWeight: isLarge ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isLarge ? 20 : 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
