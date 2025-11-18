import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:go_router/go_router.dart';
import '../models/pfa.dart';
import '../models/transaction.dart';
import '../services/storage_service.dart';
import '../utils/tax_calculator.dart';
import '../utils/safe_formatters.dart';
import '../utils/error_handler.dart';
import '../widgets/fiscal_term_tooltip.dart';

/// Home screen displaying financial overview and quick actions
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

  Future<void> _loadData() async {
    try {
      setState(() {
        _pfa = StorageService.getCurrentPFA();
        _transactions = StorageService.getAllTransactions();
      });
    } catch (e, stackTrace) {
      ErrorHandler.logError('loadData', e, stackTrace);
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          'Eroare la încărcarea datelor.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pfa == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final taxReport = TaxCalculator.calculateAnnualReport(
      _transactions,
      _selectedYear,
    );

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar.large(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
            actions: [
              Semantics(
                label: 'Ajutor și glosar fiscal',
                button: true,
                child: IconButton(
                  icon: const Icon(Icons.help_outline),
                  tooltip: 'Ajutor',
                  onPressed: () => context.push('/help'),
                ),
              ),
              Semantics(
                label: 'Profil și setări PFA',
                button: true,
                child: IconButton(
                  icon: const Icon(Icons.account_circle),
                  tooltip: 'Profil PFA',
                  onPressed: () => context.push('/profile'),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'PFA Helper',
                style: textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      colorScheme.secondary,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PFA Info Card
                  _buildPFAInfoCard(colorScheme, textTheme),
                  const SizedBox(height: 24),

                  // Year Selector
                  _buildYearSelector(colorScheme, textTheme),
                  const SizedBox(height: 24),

                  // Financial Overview
                  Text(
                    'Situație Financiară $_selectedYear',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFinancialOverview(
                    colorScheme,
                    textTheme,
                    taxReport,
                  ),
                  const SizedBox(height: 24),

                  // Tax Summary
                  Text(
                    'Taxe și Contribuții',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTaxSummary(colorScheme, textTheme, taxReport),
                  const SizedBox(height: 24),

                  // Quick Actions
                  Text(
                    'Acțiuni Rapide',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildQuickActions(colorScheme),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPFAInfoCard(ColorScheme colorScheme, TextTheme textTheme) {
    return Semantics(
      label: 'Informații PFA: ${_pfa!.name}, CUI: ${_pfa!.cui}',
      readOnly: true,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer,
              colorScheme.secondaryContainer,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20),
        child: ExcludeSemantics(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.business_rounded,
                  color: colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _pfa!.name,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'CUI: ${_pfa!.cui}',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(width: 4),
                        FiscalTermTooltip(
                          term: 'CUI',
                          iconSize: 14,
                          iconColor: colorScheme.onPrimaryContainer.withOpacity(0.7),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYearSelector(ColorScheme colorScheme, TextTheme textTheme) {
    return Semantics(
      label: 'Selector an fiscal. An selectat: $_selectedYear',
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final year = DateTime.now().year - index;
            final isSelected = year == _selectedYear;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Semantics(
                label: 'Selectează anul $year${isSelected ? '. Selectat' : ''}',
                button: true,
                selected: isSelected,
                child: Material(
                  color: isSelected ? colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedYear = year;
                      });
                      SemanticsService.announce(
                        'An selectat: $year',
                        TextDirection.ltr,
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: ExcludeSemantics(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Text(
                          year.toString(),
                          style: textTheme.bodyLarge?.copyWith(
                            color: isSelected ? Colors.white : colorScheme.onSurface,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildFinancialOverview(
    ColorScheme colorScheme,
    TextTheme textTheme,
    dynamic taxReport,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                colorScheme,
                textTheme,
                title: 'Venituri',
                value: SafeFormatters.formatCurrency(
                  taxReport.totalTaxableIncome,
                ),
                icon: Icons.trending_up_rounded,
                iconColor: Colors.green,
                backgroundColor: Colors.green.shade50,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                colorScheme,
                textTheme,
                title: 'Cheltuieli',
                value: SafeFormatters.formatCurrency(
                  taxReport.totalDeductibleExpenses,
                ),
                icon: Icons.trending_down_rounded,
                iconColor: Colors.orange,
                backgroundColor: Colors.orange.shade50,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          colorScheme,
          textTheme,
          title: 'Profit Net',
          value: SafeFormatters.formatCurrency(
            taxReport.netTaxableIncome,
          ),
          icon: Icons.account_balance_wallet_rounded,
          iconColor: colorScheme.primary,
          backgroundColor: colorScheme.primaryContainer,
          large: true,
          helpTerm: 'VENIT NET',
        ),
      ],
    );
  }

  Widget _buildTaxSummary(
    ColorScheme colorScheme,
    TextTheme textTheme,
    dynamic taxReport,
  ) {
    return Column(
      children: [
        _buildTaxCard(
          colorScheme,
          textTheme,
          title: 'Impozit pe Venit',
          amount: taxReport.incomeTax,
          icon: Icons.receipt_long_rounded,
          color: Colors.blue,
          helpTerm: 'IMPOZIT PE VENIT',
        ),
        const SizedBox(height: 12),
        _buildTaxCard(
          colorScheme,
          textTheme,
          title: 'CAS (Pensie)',
          amount: taxReport.casContribution,
          icon: Icons.elderly_rounded,
          color: Colors.purple,
          helpTerm: 'CAS',
        ),
        const SizedBox(height: 12),
        _buildTaxCard(
          colorScheme,
          textTheme,
          title: 'CASS (Sănătate)',
          amount: taxReport.cassContribution,
          icon: Icons.local_hospital_rounded,
          color: Colors.red,
          helpTerm: 'CASS',
        ),
        const SizedBox(height: 16),
        Semantics(
          label: 'Total taxe și contribuții: ${SafeFormatters.formatCurrency(taxReport.totalTaxes)}',
          readOnly: true,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple.shade700,
                  Colors.deepPurple.shade500,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ExcludeSemantics(
              child: Row(
                children: [
                  const Icon(
                    Icons.calculate_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Taxe și Contribuții',
                          style: textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          SafeFormatters.formatCurrency(
                            taxReport.totalTaxes,
                          ),
                          style: textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    ColorScheme colorScheme,
    TextTheme textTheme, {
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    bool large = false,
    String? helpTerm,
  }) {
    return Semantics(
      label: '$title: $value',
      readOnly: true,
      child: Container(
        padding: EdgeInsets.all(large ? 20 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: large ? 28 : 24,
                    ),
                  ),
                  if (large) const Spacer(),
                ],
              ),
              SizedBox(height: large ? 16 : 12),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (helpTerm != null) ...[
                    const SizedBox(width: 4),
                    FiscalTermTooltip(
                      term: helpTerm,
                      iconSize: 16,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style:
                    (large ? textTheme.headlineMedium : textTheme.titleLarge)
                        ?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaxCard(
    ColorScheme colorScheme,
    TextTheme textTheme, {
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    String? helpTerm,
  }) {
    return Semantics(
      label: '$title: ${SafeFormatters.formatCurrency(amount)}',
      readOnly: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: ExcludeSemantics(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        if (helpTerm != null) ...[
                          const SizedBox(width: 4),
                          FiscalTermTooltip(
                            term: helpTerm,
                            iconSize: 16,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      SafeFormatters.formatCurrency(amount),
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(ColorScheme colorScheme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                colorScheme,
                label: 'Tranzacții',
                icon: Icons.receipt_rounded,
                color: colorScheme.primary,
                onTap: () async {
                  await context.push('/transactions');
                  _loadData();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                colorScheme,
                label: 'Rapoarte',
                icon: Icons.assessment_rounded,
                color: Colors.green.shade700,
                onTap: () {
                  context.push('/reports');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          colorScheme,
          label: 'Facturi ANAF',
          icon: Icons.description_rounded,
          color: Colors.deepOrange.shade700,
          onTap: () {
            context.push('/invoices');
          },
        ),
      ],
    );
  }

  Widget _buildActionButton(
    ColorScheme colorScheme, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Semantics(
      label: 'Deschide $label',
      button: true,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: ExcludeSemantics(
              child: Column(
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
