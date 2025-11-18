import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:intl/intl.dart';
import '../models/anaf_invoice.dart';
import '../services/anaf_api_service.dart';
import '../services/storage_service.dart';

/// ANAF eFactura Invoice Management Screen
///
/// Provides comprehensive invoice management functionality:
/// - List invoices with filtering and search
/// - Submit new invoices to ANAF
/// - View invoice details
/// - Track invoice status
/// - Full WCAG 2.1 Level AA accessibility compliance
class ANAFInvoicesScreen extends StatefulWidget {
  const ANAFInvoicesScreen({super.key});

  @override
  State<ANAFInvoicesScreen> createState() => _ANAFInvoicesScreenState();
}

class _ANAFInvoicesScreenState extends State<ANAFInvoicesScreen> {
  final ANAFApiService _anafService = ANAFApiService();

  List<ANAFInvoice> _invoices = [];
  List<ANAFInvoice> _filteredInvoices = [];
  bool _isLoading = true;
  bool _isAuthenticated = false;
  String? _errorMessage;

  final TextEditingController _searchController = TextEditingController();
  ANAFInvoiceStatus? _filterStatus;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _anafService.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _anafService.initialize();
      _isAuthenticated = _anafService.isAuthenticated;

      if (_isAuthenticated) {
        await _loadInvoices();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Eroare la inițializare: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadInvoices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _anafService.listInvoices(
        startDate: _dateRange?.start,
        endDate: _dateRange?.end,
        status: _filterStatus,
      );

      if (response.success && response.data != null) {
        setState(() {
          _invoices = response.data!;
          _applyFilters();
          _isLoading = false;
        });

        if (mounted) {
          SemanticsService.announce(
            '${_invoices.length} facturi încărcate',
            Assertiveness.polite,
          );
        }
      } else {
        setState(() {
          _errorMessage = response.error ?? 'Eroare la încărcarea facturilor';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Eroare la încărcarea facturilor: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    var filtered = _invoices;

    // Apply status filter
    if (_filterStatus != null) {
      filtered = filtered.where((inv) => inv.status == _filterStatus).toList();
    }

    // Apply search filter
    final searchTerm = _searchController.text.toLowerCase();
    if (searchTerm.isNotEmpty) {
      filtered = filtered.where((inv) {
        return inv.invoiceNumber.toLowerCase().contains(searchTerm) ||
            inv.buyerName.toLowerCase().contains(searchTerm) ||
            inv.buyerCIF.toLowerCase().contains(searchTerm);
      }).toList();
    }

    // Sort by date descending
    filtered.sort((a, b) => b.issueDate.compareTo(a.issueDate));

    setState(() {
      _filteredInvoices = filtered;
    });
  }

  Future<void> _showAuthenticationDialog() async {
    final clientIdController = TextEditingController();
    final clientSecretController = TextEditingController();
    final redirectUriController = TextEditingController(text: 'urn:ietf:wg:oauth:2.0:oob');

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Autentificare ANAF'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pentru a utiliza serviciul eFactura, trebuie să vă autentificați cu credențialele ANAF OAuth2.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              Semantics(
                label: 'Client ID',
                textField: true,
                child: TextField(
                  controller: clientIdController,
                  decoration: const InputDecoration(
                    labelText: 'Client ID',
                    helperText: 'Obținut din SPV ANAF',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                label: 'Client Secret',
                textField: true,
                obscured: true,
                child: TextField(
                  controller: clientSecretController,
                  decoration: const InputDecoration(
                    labelText: 'Client Secret',
                    helperText: 'Obținut din SPV ANAF',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                label: 'Redirect URI',
                textField: true,
                child: TextField(
                  controller: redirectUriController,
                  decoration: const InputDecoration(
                    labelText: 'Redirect URI',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anulează'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);

              final response = await _anafService.authenticate(
                clientId: clientIdController.text.trim(),
                clientSecret: clientSecretController.text.trim(),
                redirectUri: redirectUriController.text.trim(),
              );

              if (response.success) {
                setState(() {
                  _isAuthenticated = true;
                });
                await _loadInvoices();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Autentificare reușită'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Eroare: ${response.error}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Autentifică'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateInvoiceDialog() async {
    if (!_isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trebuie să vă autentificați mai întâi'),
        ),
      );
      return;
    }

    final pfa = StorageService.getCurrentPFA();
    if (pfa == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PFA neînregistrat. Vă rugăm configurați profilul mai întâi.'),
          ),
        );
      }
      return;
    }

    final invoiceNumberController = TextEditingController();
    final buyerCIFController = TextEditingController();
    final buyerNameController = TextEditingController();
    final descriptionController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final unitPriceController = TextEditingController();
    final vatRateController = TextEditingController(text: '19');
    DateTime selectedDate = DateTime.now();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Factură nouă'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    label: 'Număr factură',
                    textField: true,
                    child: TextField(
                      controller: invoiceNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Număr factură',
                        border: OutlineInputBorder(),
                        hintText: 'Ex: FAC001',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    label: 'Data emiterii: ${DateFormat('dd MMM yyyy').format(selectedDate)}',
                    button: true,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setDialogState(() {
                            selectedDate = date;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        'Data: ${DateFormat('dd MMM yyyy').format(selectedDate)}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    label: 'CIF cumpărător',
                    textField: true,
                    child: TextField(
                      controller: buyerCIFController,
                      decoration: const InputDecoration(
                        labelText: 'CIF Cumpărător',
                        border: OutlineInputBorder(),
                        hintText: 'Ex: RO12345678',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    label: 'Nume cumpărător',
                    textField: true,
                    child: TextField(
                      controller: buyerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nume Cumpărător',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const Text(
                    'Linie factură',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    label: 'Descriere serviciu sau produs',
                    textField: true,
                    child: TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descriere',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          label: 'Cantitate',
                          textField: true,
                          child: TextField(
                            controller: quantityController,
                            decoration: const InputDecoration(
                              labelText: 'Cantitate',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Semantics(
                          label: 'Preț unitar în RON',
                          textField: true,
                          child: TextField(
                            controller: unitPriceController,
                            decoration: const InputDecoration(
                              labelText: 'Preț unitar',
                              border: OutlineInputBorder(),
                              suffixText: 'RON',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    label: 'Cotă TVA în procente',
                    textField: true,
                    child: TextField(
                      controller: vatRateController,
                      decoration: const InputDecoration(
                        labelText: 'Cotă TVA (%)',
                        border: OutlineInputBorder(),
                        helperText: 'Standard: 19%',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anulează'),
            ),
            FilledButton(
              onPressed: () async {
                // Validate inputs
                if (invoiceNumberController.text.trim().isEmpty ||
                    buyerCIFController.text.trim().isEmpty ||
                    buyerNameController.text.trim().isEmpty ||
                    descriptionController.text.trim().isEmpty ||
                    unitPriceController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Completați toate câmpurile obligatorii'),
                    ),
                  );
                  return;
                }

                final quantity = double.tryParse(quantityController.text) ?? 1.0;
                final unitPrice = double.tryParse(unitPriceController.text) ?? 0.0;
                final vatRate = double.tryParse(vatRateController.text) ?? 19.0;

                final lineTotal = quantity * unitPrice;
                final vatAmount = lineTotal * (vatRate / 100);
                final totalAmount = lineTotal + vatAmount;

                // Create invoice
                final invoice = ANAFInvoice(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  cif: pfa.cui,
                  invoiceNumber: invoiceNumberController.text.trim(),
                  issueDate: selectedDate,
                  totalAmount: totalAmount,
                  vatAmount: vatAmount,
                  currency: 'RON',
                  buyerCIF: buyerCIFController.text.trim(),
                  buyerName: buyerNameController.text.trim(),
                  lines: [
                    ANAFInvoiceLine(
                      description: descriptionController.text.trim(),
                      quantity: quantity,
                      unitPrice: unitPrice,
                      vatRate: vatRate,
                      totalAmount: lineTotal,
                    ),
                  ],
                  status: ANAFInvoiceStatus.draft,
                );

                Navigator.pop(context);

                // Submit invoice
                final response = await _anafService.submitInvoice(invoice);

                if (response.success) {
                  await _loadInvoices();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Factură trimisă cu succes'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Eroare: ${response.error}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Trimite'),
            ),
          ],
        ),
      ),
    );
  }

  void _showInvoiceDetails(ANAFInvoice invoice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Factură ${invoice.invoiceNumber}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  _buildStatusBadge(invoice.status, large: true),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Număr factură', invoice.invoiceNumber),
              _buildDetailRow(
                'Data emiterii',
                DateFormat('dd MMMM yyyy').format(invoice.issueDate),
              ),
              _buildDetailRow('CIF emitent', invoice.cif),
              const Divider(height: 32),
              Text(
                'Cumpărător',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _buildDetailRow('Nume', invoice.buyerName),
              _buildDetailRow('CIF', invoice.buyerCIF),
              const Divider(height: 32),
              Text(
                'Linii factură',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              ...invoice.lines.map((line) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            line.description,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Cantitate: ${line.quantity}'),
                              Text(
                                '${line.unitPrice.toStringAsFixed(2)} RON/buc',
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('TVA: ${line.vatRate}%'),
                              Text(
                                'Total: ${line.totalAmount.toStringAsFixed(2)} RON',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )),
              const Divider(height: 32),
              _buildDetailRow(
                'Total fără TVA',
                '${(invoice.totalAmount - invoice.vatAmount).toStringAsFixed(2)} RON',
              ),
              _buildDetailRow(
                'TVA',
                '${invoice.vatAmount.toStringAsFixed(2)} RON',
              ),
              _buildDetailRow(
                'Total cu TVA',
                '${invoice.totalAmount.toStringAsFixed(2)} RON',
                bold: true,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Închide'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                fontSize: bold ? 16 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ANAFInvoiceStatus status, {bool large = false}) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String label;

    switch (status) {
      case ANAFInvoiceStatus.draft:
        backgroundColor = Colors.grey[300]!;
        textColor = Colors.grey[800]!;
        icon = Icons.edit;
        label = 'Ciornă';
        break;
      case ANAFInvoiceStatus.sent:
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[900]!;
        icon = Icons.send;
        label = 'Trimisă';
        break;
      case ANAFInvoiceStatus.validated:
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[900]!;
        icon = Icons.check_circle;
        label = 'Validată';
        break;
      case ANAFInvoiceStatus.rejected:
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[900]!;
        icon = Icons.cancel;
        label = 'Respinsă';
        break;
      case ANAFInvoiceStatus.cancelled:
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[900]!;
        icon = Icons.block;
        label = 'Anulată';
        break;
    }

    return ExcludeSemantics(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: large ? 12 : 8,
          vertical: large ? 8 : 4,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(large ? 8 : 6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: large ? 18 : 14,
              color: textColor,
            ),
            SizedBox(width: large ? 6 : 4),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: large ? 14 : 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(ANAFInvoice invoice) {
    final statusLabel = _getStatusLabel(invoice.status);

    return Semantics(
      label: 'Factură ${invoice.invoiceNumber}. '
          'Status: $statusLabel. '
          'Cumpărător: ${invoice.buyerName}. '
          'Total: ${invoice.totalAmount.toStringAsFixed(2)} RON. '
          'Data: ${DateFormat('dd MMMM yyyy').format(invoice.issueDate)}',
      button: true,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () => _showInvoiceDetails(invoice),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          invoice.invoiceNumber,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      _buildStatusBadge(invoice.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.business,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          invoice.buyerName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('dd MMM yyyy').format(invoice.issueDate),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${invoice.totalAmount.toStringAsFixed(2)} ${invoice.currency}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getStatusLabel(ANAFInvoiceStatus status) {
    switch (status) {
      case ANAFInvoiceStatus.draft:
        return 'Ciornă';
      case ANAFInvoiceStatus.sent:
        return 'Trimisă';
      case ANAFInvoiceStatus.validated:
        return 'Validată';
      case ANAFInvoiceStatus.rejected:
        return 'Respinsă';
      case ANAFInvoiceStatus.cancelled:
        return 'Anulată';
    }
  }

  Future<void> _selectDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );

    if (range != null) {
      setState(() {
        _dateRange = range;
      });
      await _loadInvoices();
      if (mounted) {
        SemanticsService.announce(
          'Interval selectat: ${DateFormat('dd MMM').format(range.start)} - ${DateFormat('dd MMM yyyy').format(range.end)}',
          Assertiveness.polite,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facturi ANAF'),
        actions: [
          if (_isAuthenticated) ...[
            Semantics(
              label: 'Filtrează după perioadă${_dateRange != null ? '. Perioadă selectată' : ''}',
              button: true,
              child: IconButton(
                icon: Icon(_dateRange != null ? Icons.date_range : Icons.calendar_today),
                tooltip: 'Filtrează după perioadă',
                onPressed: _selectDateRange,
              ),
            ),
            Semantics(
              label: 'Reîmprospătează lista de facturi',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Reîmprospătează',
                onPressed: _loadInvoices,
              ),
            ),
          ],
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _isAuthenticated
          ? Semantics(
              label: 'Adaugă factură nouă',
              button: true,
              child: FloatingActionButton.extended(
                onPressed: _showCreateInvoiceDialog,
                icon: const Icon(Icons.add),
                label: const Text('Factură nouă'),
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Se încarcă...'),
          ],
        ),
      );
    }

    if (!_isAuthenticated) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                'Autentificare necesară',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                'Pentru a accesa facturile electronice ANAF, trebuie să vă autentificați cu credențialele SPV.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _showAuthenticationDialog,
                icon: const Icon(Icons.login),
                label: const Text('Autentificare ANAF'),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red[300],
              ),
              const SizedBox(height: 24),
              Text(
                'Eroare',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _loadInvoices,
                icon: const Icon(Icons.refresh),
                label: const Text('Încearcă din nou'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Search and filter bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Column(
            children: [
              Semantics(
                label: 'Caută facturi după număr, cumpărător sau CIF',
                textField: true,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Caută după număr, cumpărător, CIF...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? Semantics(
                            label: 'Șterge căutarea',
                            button: true,
                            child: IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _applyFilters();
                                SemanticsService.announce(
                                  'Căutare ștearsă',
                                  Assertiveness.polite,
                                );
                              },
                            ),
                          )
                        : null,
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  onChanged: (_) => _applyFilters(),
                ),
              ),
              const SizedBox(height: 12),
              // Status filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Semantics(
                      label: 'Toate facturile${_filterStatus == null ? '. Selectat' : ''}',
                      button: true,
                      selected: _filterStatus == null,
                      child: FilterChip(
                        label: const Text('Toate'),
                        selected: _filterStatus == null,
                        onSelected: (selected) {
                          setState(() {
                            _filterStatus = null;
                            _applyFilters();
                          });
                          SemanticsService.announce(
                            'Afișează toate facturile',
                            Assertiveness.polite,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ...ANAFInvoiceStatus.values.map((status) {
                      final isSelected = _filterStatus == status;
                      final statusLabel = _getStatusLabel(status);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Semantics(
                          label: '$statusLabel${isSelected ? '. Selectat' : ''}',
                          button: true,
                          selected: isSelected,
                          child: FilterChip(
                            label: Text(statusLabel),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _filterStatus = selected ? status : null;
                                _applyFilters();
                              });
                              SemanticsService.announce(
                                selected
                                    ? 'Filtrat după $statusLabel'
                                    : 'Filtru șters',
                                Assertiveness.polite,
                              );
                            },
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Invoice list
        Expanded(
          child: _filteredInvoices.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Nicio factură',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _searchController.text.isNotEmpty || _filterStatus != null
                              ? 'Nu au fost găsite facturi care să corespundă criteriilor de filtrare.'
                              : 'Nu aveți încă facturi în sistem. Apăsați butonul pentru a adăuga prima factură.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredInvoices.length,
                  itemBuilder: (context, index) {
                    return _buildInvoiceCard(_filteredInvoices[index]);
                  },
                ),
        ),
      ],
    );
  }
}
