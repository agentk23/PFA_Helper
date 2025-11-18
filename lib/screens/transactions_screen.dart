import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/transaction_category.dart';
import '../services/storage_service.dart';

/// Screen for managing transactions (income and expenses)
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Transaction> _transactions = [];
  final _currencyFormat = NumberFormat.currency(locale: 'ro_RO', symbol: 'RON');
  TransactionType _filterType = TransactionType.income;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  void _loadTransactions() {
    setState(() {
      _transactions = StorageService.getAllTransactions()
        ..sort((a, b) => b.date.compareTo(a.date));
    });
  }

  Future<void> _addTransaction() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _TransactionForm(),
    );

    if (result == true) {
      _loadTransactions();
    }
  }

  Future<void> _deleteTransaction(Transaction transaction) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmare ștergere'),
        content: Text('Ștergeți tranzacția "${transaction.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anulare'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Șterge'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.deleteTransaction(transaction.id);
      _loadTransactions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tranzacția a fost ștearsă')),
        );
      }
    }
  }

  List<Transaction> get _filteredTransactions {
    return _transactions.where((t) => t.type == _filterType).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredTransactions = _filteredTransactions;
    final total = filteredTransactions.fold<double>(
      0,
      (sum, t) => sum + t.amountWithoutVAT,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tranzacții'),
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Expanded(
                  child: _FilterTab(
                    label: 'Venituri',
                    count: _transactions.where((t) => t.type == TransactionType.income).length,
                    isSelected: _filterType == TransactionType.income,
                    onTap: () {
                      setState(() {
                        _filterType = TransactionType.income;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: _FilterTab(
                    label: 'Cheltuieli',
                    count: _transactions.where((t) => t.type == TransactionType.expense).length,
                    isSelected: _filterType == TransactionType.expense,
                    onTap: () {
                      setState(() {
                        _filterType = TransactionType.expense;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // Total Summary
          Container(
            padding: const EdgeInsets.all(16),
            color: _filterType == TransactionType.income
                ? Colors.green.shade50
                : Colors.orange.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total ${_filterType == TransactionType.income ? "venituri" : "cheltuieli"}:',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _currencyFormat.format(total),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _filterType == TransactionType.income
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),

          // Transaction List
          Expanded(
            child: filteredTransactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _filterType == TransactionType.income
                              ? Icons.attach_money
                              : Icons.shopping_cart,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nicio ${_filterType == TransactionType.income ? "venit" : "cheltuială"}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = filteredTransactions[index];
                      return _TransactionListItem(
                        transaction: transaction,
                        currencyFormat: _currencyFormat,
                        onDelete: () => _deleteTransaction(transaction),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTransaction,
        icon: const Icon(Icons.add),
        label: const Text('Adaugă tranzacție'),
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionListItem extends StatelessWidget {
  final Transaction transaction;
  final NumberFormat currencyFormat;
  final VoidCallback onDelete;

  const _TransactionListItem({
    required this.transaction,
    required this.currencyFormat,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy', 'ro_RO');

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmare ștergere'),
            content: const Text('Ștergeți această tranzacție?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Anulare'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Șterge'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: transaction.type == TransactionType.income
                ? Colors.green.shade100
                : Colors.orange.shade100,
            child: Icon(
              transaction.type == TransactionType.income
                  ? Icons.arrow_downward
                  : Icons.arrow_upward,
              color: transaction.type == TransactionType.income
                  ? Colors.green.shade700
                  : Colors.orange.shade700,
            ),
          ),
          title: Text(transaction.description),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dateFormat.format(transaction.date)),
              Text(
                transaction.category,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              if (transaction.type == TransactionType.expense && !transaction.isDeductible)
                Text(
                  'Nedeductibil',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(transaction.amountWithoutVAT),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: transaction.type == TransactionType.income
                      ? Colors.green.shade700
                      : Colors.orange.shade700,
                ),
              ),
              if (transaction.includesVAT)
                Text(
                  'incl. TVA',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
          isThreeLine: true,
        ),
      ),
    );
  }
}

class _TransactionForm extends StatefulWidget {
  const _TransactionForm();

  @override
  State<_TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<_TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _invoiceController = TextEditingController();
  final _clientSupplierController = TextEditingController();

  TransactionType _type = TransactionType.income;
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategory;
  bool _includesVAT = false;
  bool _isDeductible = true;
  List<TransactionCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() {
    setState(() {
      _categories = StorageService.getAllCategories();
      if (_categories.isNotEmpty) {
        _selectedCategory = _categories.first.name;
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _invoiceController.dispose();
    _clientSupplierController.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final transaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: _type,
      amount: double.parse(_amountController.text),
      date: _selectedDate,
      description: _descriptionController.text.trim(),
      category: _selectedCategory ?? 'Altele',
      includesVAT: _includesVAT,
      vatRate: _includesVAT ? 19.0 : null,
      invoiceNumber: _invoiceController.text.trim().isEmpty
          ? null
          : _invoiceController.text.trim(),
      clientSupplier: _clientSupplierController.text.trim().isEmpty
          ? null
          : _clientSupplierController.text.trim(),
      isDeductible: _type == TransactionType.expense ? _isDeductible : true,
    );

    await StorageService.saveTransaction(transaction);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tranzacție nouă',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              // Type Selection
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('Venit'),
                    icon: Icon(Icons.arrow_downward),
                  ),
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('Cheltuială'),
                    icon: Icon(Icons.arrow_upward),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (Set<TransactionType> newSelection) {
                  setState(() {
                    _type = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Amount
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Sumă',
                  prefixIcon: Icon(Icons.attach_money),
                  suffixText: 'RON',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Introduceți suma';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Sumă invalidă';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descriere',
                  prefixIcon: Icon(Icons.description),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Introduceți descrierea';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Categorie',
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat.name,
                    child: Text(cat.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Date
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Data'),
                subtitle: Text(DateFormat('dd MMMM yyyy', 'ro_RO').format(_selectedDate)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDate = date;
                    });
                  }
                },
              ),

              // VAT Toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Include TVA (19%)'),
                value: _includesVAT,
                onChanged: (value) {
                  setState(() {
                    _includesVAT = value;
                  });
                },
              ),

              // Deductible (for expenses)
              if (_type == TransactionType.expense)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Cheltuială deductibilă'),
                  value: _isDeductible,
                  onChanged: (value) {
                    setState(() {
                      _isDeductible = value;
                    });
                  },
                ),

              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Salvează'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
