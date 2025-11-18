import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/transaction_category.dart';
import '../models/caen_code.dart';
import '../services/storage_service.dart';
import 'caen_picker_screen.dart';
import 'dart:developer' as developer;

/// Accessible transactions management screen
///
/// Features:
/// - Full keyboard navigation and screen reader support
/// - Transaction filtering by category
/// - Add/edit/delete transactions
/// - CAEN code assignment
/// - Responsive layout with visual hierarchy
/// - Search and sort functionality
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Transaction> _transactions = [];
  List<Transaction> _filteredTransactions = [];
  TransactionCategory? _filterCategory;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadTransactions() {
    setState(() {
      _transactions = StorageService.getAllTransactions();
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      _applyFilters();
    });
  }

  void _applyFilters() {
    var filtered = _transactions;

    // Filter by category
    if (_filterCategory != null) {
      filtered = filtered.where((t) => t.category == _filterCategory).toList();
    }

    // Filter by search term
    final searchTerm = _searchController.text.toLowerCase();
    if (searchTerm.isNotEmpty) {
      filtered = filtered.where((t) {
        return t.description.toLowerCase().contains(searchTerm) ||
            (t.invoiceNumber?.toLowerCase().contains(searchTerm) ?? false) ||
            (t.notes?.toLowerCase().contains(searchTerm) ?? false);
      }).toList();
    }

    setState(() {
      _filteredTransactions = filtered;
    });
  }

  Future<void> _deleteTransaction(Transaction transaction) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmare ștergere'),
        content: Text(
          'Sigur doriți să ștergeți tranzacția "${transaction.description}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anulează'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Șterge'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await StorageService.deleteTransaction(transaction.id);
        _loadTransactions();

        if (mounted) {
          SemanticsService.announce(
            'Tranzacție ștearsă',
            Assertiveness.polite,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Tranzacție ștearsă cu succes',
                semanticsLabel: 'Succes: Tranzacție ștearsă',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e, stackTrace) {
        developer.log(
          'Failed to delete transaction',
          name: 'TransactionsScreen',
          error: e,
          stackTrace: stackTrace,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Eroare la ștergere: ${e.toString()}',
                semanticsLabel: 'Eroare: Nu s-a putut șterge tranzacția',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tranzacții'),
        centerTitle: true,
        actions: [
          Semantics(
            label: 'Filtrează tranzacții după categorie',
            button: true,
            child: PopupMenuButton<TransactionCategory?>(
              icon: Icon(
                _filterCategory != null ? Icons.filter_alt : Icons.filter_alt_outlined,
              ),
              tooltip: 'Filtrează după categorie',
              onSelected: (category) {
                setState(() {
                  _filterCategory = category;
                  _applyFilters();
                });

                SemanticsService.announce(
                  category == null
                      ? 'Afișare toate categoriile'
                      : 'Filtru: ${category.displayName}',
                  Assertiveness.polite,
                );
              },
              itemBuilder: (context) => [
                const PopupMenuItem<TransactionCategory?>(
                  value: null,
                  child: Row(
                    children: [
                      Icon(Icons.clear_all),
                      SizedBox(width: 12),
                      Text('Toate categoriile'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                ...TransactionCategory.values.map((category) {
                  return PopupMenuItem<TransactionCategory>(
                    value: category,
                    child: Row(
                      children: [
                        Icon(
                          category.isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 20,
                          color: category.isIncome ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 12),
                        Text(category.displayName),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Semantics(
              label: 'Caută tranzacții',
              textField: true,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Caută după descriere, factură...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: 'Șterge căutarea',
                          onPressed: () {
                            _searchController.clear();
                            _applyFilters();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                ),
                onChanged: (_) => _applyFilters(),
              ),
            ),
          ),

          // Filter chip
          if (_filterCategory != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Semantics(
                  label: 'Filtru activ: ${_filterCategory!.displayName}',
                  button: true,
                  child: Chip(
                    avatar: Icon(
                      _filterCategory!.isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 18,
                    ),
                    label: Text(_filterCategory!.displayName),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() {
                        _filterCategory = null;
                        _applyFilters();
                      });
                      SemanticsService.announce(
                        'Filtru eliminat',
                        Assertiveness.polite,
                      );
                    },
                  ),
                ),
              ),
            ),

          // Transactions list
          Expanded(
            child: _filteredTransactions.isEmpty
                ? Center(
                    child: Semantics(
                      label: _transactions.isEmpty
                          ? 'Nicio tranzacție adăugată'
                          : 'Nicio tranzacție corespunde filtrului',
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _transactions.isEmpty ? Icons.receipt_long : Icons.search_off,
                            size: 64,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _transactions.isEmpty
                                ? 'Nicio tranzacție'
                                : 'Niciun rezultat',
                            style: textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _transactions.isEmpty
                                ? 'Apăsați + pentru a adăuga prima tranzacție'
                                : 'Încercați un alt filtru sau termen de căutare',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _filteredTransactions[index];
                      return _buildTransactionCard(transaction, colorScheme, textTheme);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Semantics(
        label: 'Adaugă tranzacție nouă',
        button: true,
        child: FloatingActionButton.extended(
          onPressed: () async {
            await _showAddTransactionDialog();
            _loadTransactions();
          },
          icon: const Icon(Icons.add),
          label: const Text('Adaugă tranzacție'),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(
    Transaction transaction,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final isIncome = transaction.isIncome;
    final color = isIncome ? Colors.green : Colors.red;

    return Semantics(
      label: '${transaction.description}. '
          '${isIncome ? 'Venit' : 'Cheltuială'} de ${transaction.amount.toStringAsFixed(2)} RON. '
          '${transaction.category.displayName}. '
          'Data: ${DateFormat('dd MMMM yyyy').format(transaction.date)}',
      button: true,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onLongPress: () => _deleteTransaction(transaction),
          onTap: () => _showTransactionDetails(transaction),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icon
                    ExcludeSemantics(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                          color: color,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Description and category
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ExcludeSemantics(
                            child: Text(
                              transaction.description,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          ExcludeSemantics(
                            child: Text(
                              transaction.category.displayName,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Amount
                    ExcludeSemantics(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isIncome ? '+' : '-'}${transaction.amount.toStringAsFixed(2)}',
                            style: textTheme.titleLarge?.copyWith(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'RON',
                            style: textTheme.bodySmall?.copyWith(
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Additional info
                const SizedBox(height: 12),
                ExcludeSemantics(
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd.MM.yyyy').format(transaction.date),
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (transaction.invoiceNumber != null) ...[
                        const SizedBox(width: 16),
                        Icon(
                          Icons.receipt,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Nr. ${transaction.invoiceNumber}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (transaction.caenCode != null) ...[
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'CAEN ${transaction.caenCode}',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onTertiaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTransactionDetails(Transaction transaction) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalii tranzacție',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Descriere', transaction.description),
            _buildDetailRow('Sumă', '${transaction.amount.toStringAsFixed(2)} RON'),
            _buildDetailRow('Categorie', transaction.category.displayName),
            _buildDetailRow('Data', DateFormat('dd MMMM yyyy').format(transaction.date)),
            if (transaction.invoiceNumber != null)
              _buildDetailRow('Nr. factură', transaction.invoiceNumber!),
            if (transaction.caenCode != null)
              _buildDetailRow('Cod CAEN', transaction.caenCode!),
            if (transaction.notes != null)
              _buildDetailRow('Notițe', transaction.notes!),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteTransaction(transaction);
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Șterge'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
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
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddTransactionDialog() async {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    final invoiceController = TextEditingController();
    final notesController = TextEditingController();

    DateTime selectedDate = DateTime.now();
    TransactionCategory selectedCategory = TransactionCategory.taxableIncome;
    CAENCode? selectedCAEN;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Adaugă tranzacție'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Amount
                  Semantics(
                    label: 'Sumă tranzacție - câmp obligatoriu',
                    textField: true,
                    child: TextFormField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        labelText: 'Sumă (RON) *',
                        prefixIcon: Icon(Icons.attach_money),
                        border: OutlineInputBorder(),
                        helperText: 'Suma în lei fără TVA',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Suma este obligatorie';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Sumă invalidă';
                        }
                        if (double.parse(value) <= 0) {
                          return 'Suma trebuie să fie pozitivă';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Semantics(
                    label: 'Descriere tranzacție - câmp obligatoriu',
                    textField: true,
                    child: TextFormField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descriere *',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                        helperText: 'Descriere scurtă a tranzacției',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Descrierea este obligatorie';
                        }
                        if (value.length < 3) {
                          return 'Descrierea trebuie să aibă cel puțin 3 caractere';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category
                  Semantics(
                    label: 'Selectează categoria tranzacției',
                    child: DropdownButtonFormField<TransactionCategory>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Categorie *',
                        prefixIcon: Icon(Icons.category),
                        border: OutlineInputBorder(),
                      ),
                      items: TransactionCategory.values.map((category) {
                        return DropdownMenuItem<TransactionCategory>(
                          value: category,
                          child: Row(
                            children: [
                              Icon(
                                category.isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                                size: 18,
                                color: category.isIncome ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(category.displayName),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedCategory = value!;
                        });
                        SemanticsService.announce(
                          'Categorie selectată: ${value!.displayName}',
                          TextDirection.ltr,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // CAEN Code (optional)
                  Semantics(
                    label: 'Cod CAEN opțional${selectedCAEN != null ? '. Selectat: ${selectedCAEN!.code}' : ''}',
                    button: true,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.of(context).push<CAENCode>(
                          MaterialPageRoute(
                            builder: (context) => const CAENPickerScreen(
                              multiSelect: false,
                            ),
                          ),
                        );
                        if (result != null) {
                          setDialogState(() {
                            selectedCAEN = result;
                          });
                          SemanticsService.announce(
                            'Cod CAEN selectat: ${result.code}',
                            TextDirection.ltr,
                          );
                        }
                      },
                      icon: Icon(selectedCAEN != null ? Icons.check_circle : Icons.work),
                      label: Text(
                        selectedCAEN != null
                            ? 'CAEN: ${selectedCAEN!.code}'
                            : 'Selectează cod CAEN (opțional)',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date
                  Semantics(
                    label: 'Data tranzacției: ${DateFormat('dd MMMM yyyy').format(selectedDate)}',
                    button: true,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Data'),
                      subtitle: Text(
                        DateFormat('dd.MM.yyyy').format(selectedDate),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      leading: const Icon(Icons.calendar_today),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade400),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          helpText: 'Selectați data tranzacției',
                          cancelText: 'Anulează',
                          confirmText: 'Confirmă',
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = picked;
                          });
                          SemanticsService.announce(
                            'Data selectată: ${DateFormat('dd MMMM yyyy').format(picked)}',
                            TextDirection.ltr,
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Invoice Number
                  Semantics(
                    label: 'Număr factură - câmp opțional',
                    textField: true,
                    child: TextFormField(
                      controller: invoiceController,
                      decoration: const InputDecoration(
                        labelText: 'Nr. factură (opțional)',
                        prefixIcon: Icon(Icons.receipt),
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  Semantics(
                    label: 'Notițe - câmp opțional',
                    textField: true,
                    child: TextFormField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notițe (opțional)',
                        prefixIcon: Icon(Icons.note),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
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
            FilledButton.icon(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    final transaction = Transaction(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      amount: double.parse(amountController.text),
                      date: selectedDate,
                      category: selectedCategory,
                      description: descriptionController.text.trim(),
                      caenCode: selectedCAEN?.code,
                      invoiceNumber: invoiceController.text.trim().isEmpty
                          ? null
                          : invoiceController.text.trim(),
                      notes: notesController.text.trim().isEmpty
                          ? null
                          : notesController.text.trim(),
                      createdAt: DateTime.now(),
                    );

                    await StorageService.addTransaction(transaction);

                    if (context.mounted) {
                      Navigator.pop(context);

                      SemanticsService.announce(
                        'Tranzacție adăugată cu succes',
                        TextDirection.ltr,
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Tranzacție adăugată cu succes',
                            semanticsLabel: 'Succes: Tranzacție adăugată',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e, stackTrace) {
                    developer.log(
                      'Failed to add transaction',
                      name: 'TransactionsScreen',
                      error: e,
                      stackTrace: stackTrace,
                    );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Eroare la salvare: ${e.toString()}',
                            semanticsLabel: 'Eroare: Nu s-a putut adăuga tranzacția',
                          ),
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
                    }
                  }
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Salvează'),
            ),
          ],
        ),
      ),
    );
  }
}
