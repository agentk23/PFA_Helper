import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/pfa.dart';
import '../services/storage_service.dart';
import '../services/pdf_service.dart';
import '../utils/tax_calculator.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _selectedYear = DateTime.now().year;
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final pfa = StorageService.getCurrentPFA();
    if (pfa == null) {
      return const Scaffold(
        body: Center(
          child: Text('PFA nu este înregistrat'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapoarte'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Year Selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selectează anul',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _selectedYear,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    items: List.generate(10, (index) {
                      final year = DateTime.now().year - index;
                      return DropdownMenuItem(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }),
                    onChanged: (value) {
                      setState(() {
                        _selectedYear = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Report Types
          const Text(
            'Tipuri de rapoarte',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Annual Tax Report
          _buildReportCard(
            title: 'Raport Fiscal Anual',
            description:
                'Raport complet cu venituri, cheltuieli și calcul taxe pentru ANAF',
            icon: Icons.assessment,
            color: Colors.blue,
            onGenerate: () => _generateAnnualTaxReport(pfa),
          ),
          const SizedBox(height: 12),

          // Transactions List
          _buildReportCard(
            title: 'Registru Venituri și Cheltuieli',
            description:
                'Lista completă a tuturor tranzacțiilor pentru anul selectat',
            icon: Icons.receipt_long,
            color: Colors.green,
            onGenerate: () => _generateTransactionsList(pfa),
          ),

          const SizedBox(height: 24),

          // Info Card
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        'Informații importante',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '• Declarația anuală unică se depune până la 25 mai',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Toate rapoartele PDF pot fi trimise direct la ANAF',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Păstrează copii ale tuturor facturilor și documentelor justificative',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onGenerate,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: _isGenerating ? null : onGenerate,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateAnnualTaxReport(PFA pfa) async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final transactions = StorageService.getTransactionsByYear(_selectedYear);

      if (transactions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Nu există tranzacții pentru anul $_selectedYear'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final taxReport =
          TaxCalculator.calculateAnnualReport(transactions, _selectedYear);

      final file = await PDFService.generateAnnualTaxReport(
        pfa: pfa,
        taxReport: taxReport,
        transactions: transactions,
      );

      if (mounted) {
        _showShareDialog(file, 'Raport Fiscal $_selectedYear');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la generarea raportului: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _generateTransactionsList(PFA pfa) async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final transactions = StorageService.getTransactionsByYear(_selectedYear);

      if (transactions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Nu există tranzacții pentru anul $_selectedYear'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final file = await PDFService.generateTransactionsList(
        pfa: pfa,
        transactions: transactions,
        year: _selectedYear,
      );

      if (mounted) {
        _showShareDialog(file, 'Registru Tranzacții $_selectedYear');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la generarea listei: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  void _showShareDialog(File file, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700),
            const SizedBox(width: 8),
            const Text('PDF Generat'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Raportul "$title" a fost generat cu succes!'),
            const SizedBox(height: 8),
            Text(
              'Locație: ${file.path}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Închide'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await Share.shareXFiles(
                [XFile(file.path)],
                subject: title,
                text: 'Raport fiscal generat de PFA Helper',
              );
            },
            icon: const Icon(Icons.share),
            label: const Text('Distribuie'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade800,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
