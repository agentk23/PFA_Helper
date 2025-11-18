import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import '../models/caen_code.dart';
import '../services/caen_repository.dart';
import 'dart:developer' as developer;

/// Accessible CAEN code picker screen with search and filtering
///
/// Features:
/// - Full keyboard navigation support
/// - Screen reader optimized with semantic labels
/// - Responsive layout for different screen sizes
/// - Search with debouncing for performance
/// - Visual hierarchy and clear contrast ratios
/// - Loading states and error handling
/// - Categorized browsing by divisions
class CAENPickerScreen extends StatefulWidget {
  /// Maximum number of codes that can be selected
  final int? maxSelection;

  /// Already selected CAEN codes (for multi-select)
  final List<String>? selectedCodes;

  /// Whether to allow multiple selection
  final bool multiSelect;

  /// Filter to show only special rate codes
  final bool onlySpecialRate;

  const CAENPickerScreen({
    super.key,
    this.maxSelection,
    this.selectedCodes,
    this.multiSelect = false,
    this.onlySpecialRate = false,
  });

  @override
  State<CAENPickerScreen> createState() => _CAENPickerScreenState();
}

class _CAENPickerScreenState extends State<CAENPickerScreen> {
  final CAENRepository _repository = CAENRepository();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<CAENCode> _allCodes = [];
  List<CAENCode> _filteredCodes = [];
  Map<String, String> _divisions = {};
  String? _selectedDivision;
  bool _isLoading = true;
  String? _errorMessage;
  final Set<String> _localSelectedCodes = {};

  @override
  void initState() {
    super.initState();
    _localSelectedCodes.addAll(widget.selectedCodes ?? []);
    _initializeRepository();
  }

  Future<void> _initializeRepository() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      await _repository.initialize();

      // Load codes
      final codes = widget.onlySpecialRate
          ? await _repository.getSpecialRateCodes()
          : await _repository.getAllCodes();

      // Load divisions for categorization
      final divisions = await _repository.getDivisions();

      setState(() {
        _allCodes = codes;
        _filteredCodes = codes;
        _divisions = divisions;
        _isLoading = false;
      });

      developer.log(
        'Loaded ${codes.length} CAEN codes',
        name: 'CAENPickerScreen',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Failed to load CAEN codes',
        name: 'CAENPickerScreen',
        error: e,
        stackTrace: stackTrace,
      );

      setState(() {
        _errorMessage = 'Nu s-au putut încărca codurile CAEN. Verificați conexiunea.';
        _isLoading = false;
        // Fallback to common codes
        _allCodes = CAENCode.getCommonCAENCodes();
        _filteredCodes = _allCodes;
      });
    }
  }

  void _performSearch(String query) {
    setState(() {
      if (query.isEmpty && _selectedDivision == null) {
        _filteredCodes = _allCodes;
      } else {
        _filteredCodes = _allCodes.where((code) {
          final matchesSearch = query.isEmpty ||
              code.code.toLowerCase().contains(query.toLowerCase()) ||
              code.description.toLowerCase().contains(query.toLowerCase());

          final matchesDivision = _selectedDivision == null ||
              code.code.padLeft(2, '0').startsWith(_selectedDivision!);

          return matchesSearch && matchesDivision;
        }).toList();
      }
    });
  }

  void _filterByDivision(String? division) {
    setState(() {
      _selectedDivision = division;
    });
    _performSearch(_searchController.text);
  }

  void _toggleCodeSelection(CAENCode code) {
    setState(() {
      if (_localSelectedCodes.contains(code.code)) {
        _localSelectedCodes.remove(code.code);
      } else {
        if (widget.multiSelect) {
          // Check max selection limit
          if (widget.maxSelection != null &&
              _localSelectedCodes.length >= widget.maxSelection!) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Puteți selecta maxim ${widget.maxSelection} coduri CAEN',
                  semanticsLabel: 'Limită de selecție atinsă. Maximum ${widget.maxSelection} coduri CAEN',
                ),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
            return;
          }
          _localSelectedCodes.add(code.code);
        } else {
          _localSelectedCodes.clear();
          _localSelectedCodes.add(code.code);
          // Auto-return for single selection
          _confirmSelection();
        }
      }
    });
  }

  void _confirmSelection() {
    if (_localSelectedCodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selectați cel puțin un cod CAEN',
            semanticsLabel: 'Eroare: Niciun cod CAEN selectat',
          ),
        ),
      );
      return;
    }

    final selectedCAENCodes = _allCodes
        .where((code) => _localSelectedCodes.contains(code.code))
        .toList();

    Navigator.of(context).pop(
      widget.multiSelect ? selectedCAENCodes : selectedCAENCodes.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          label: 'Selectare cod CAEN - Clasificare activități economice',
          child: const Text('Selectare cod CAEN'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Închide fără a salva',
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (widget.multiSelect)
            Semantics(
              label: 'Confirmă selecția curentă. ${_localSelectedCodes.length} coduri selectate',
              button: true,
              child: TextButton(
                onPressed: _localSelectedCodes.isEmpty ? null : _confirmSelection,
                child: Text(
                  'Confirmă (${_localSelectedCodes.length})',
                  style: TextStyle(
                    color: _localSelectedCodes.isEmpty
                        ? colorScheme.onSurface.withValues(alpha: 0.38)
                        : colorScheme.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Semantics(
                label: 'Se încarcă codurile CAEN',
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Se încarcă codurile CAEN...'),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // Search and filter section
                Container(
                  color: colorScheme.surface,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search field
                      Semantics(
                        label: 'Căutare cod CAEN după nume sau număr',
                        textField: true,
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          autofocus: false,
                          decoration: InputDecoration(
                            hintText: 'Căutare după cod sau descriere...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    tooltip: 'Șterge căutarea',
                                    onPressed: () {
                                      _searchController.clear();
                                      _performSearch('');
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest,
                          ),
                          onChanged: _performSearch,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Division filter chips
                      if (_divisions.isNotEmpty) ...[
                        Semantics(
                          label: 'Filtrare după diviziune economică',
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              // "All" chip
                              Semantics(
                                label: _selectedDivision == null
                                    ? 'Afișează toate diviziunile - selectat'
                                    : 'Afișează toate diviziunile',
                                button: true,
                                selected: _selectedDivision == null,
                                child: FilterChip(
                                  label: const Text('Toate'),
                                  selected: _selectedDivision == null,
                                  onSelected: (_) => _filterByDivision(null),
                                  selectedColor: colorScheme.primaryContainer,
                                ),
                              ),

                              // IT division chip (if exists)
                              if (_divisions.containsKey('62'))
                                Semantics(
                                  label: _selectedDivision == '62'
                                      ? 'IT și Software - selectat'
                                      : 'Filtrează doar activități IT și Software',
                                  button: true,
                                  selected: _selectedDivision == '62',
                                  child: FilterChip(
                                    label: const Text('IT și Software (62)'),
                                    selected: _selectedDivision == '62',
                                    onSelected: (_) => _filterByDivision('62'),
                                    selectedColor: colorScheme.primaryContainer,
                                    avatar: _selectedDivision == '62'
                                        ? null
                                        : const Icon(Icons.computer, size: 18),
                                  ),
                                ),

                              // Consulting division chip (if exists)
                              if (_divisions.containsKey('70'))
                                Semantics(
                                  label: _selectedDivision == '70'
                                      ? 'Consultanță - selectat'
                                      : 'Filtrează doar activități de consultanță',
                                  button: true,
                                  selected: _selectedDivision == '70',
                                  child: FilterChip(
                                    label: const Text('Consultanță (70)'),
                                    selected: _selectedDivision == '70',
                                    onSelected: (_) => _filterByDivision('70'),
                                    selectedColor: colorScheme.primaryContainer,
                                    avatar: _selectedDivision == '70'
                                        ? null
                                        : const Icon(Icons.business_center, size: 18),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Results counter
                      Semantics(
                        label: '${_filteredCodes.length} coduri CAEN găsite',
                        child: Text(
                          '${_filteredCodes.length} coduri găsite',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Results list
                Expanded(
                  child: _filteredCodes.isEmpty
                      ? Center(
                          child: Semantics(
                            label: 'Niciun cod CAEN găsit pentru căutarea curentă',
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Niciun cod găsit',
                                  style: theme.textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Încercați o altă căutare',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredCodes.length,
                          itemBuilder: (context, index) {
                            final code = _filteredCodes[index];
                            final isSelected = _localSelectedCodes.contains(code.code);

                            return Semantics(
                              label: '${code.code} - ${code.description}. '
                                  '${code.hasSpecialTaxRate ? 'Cotă specială 3%. ' : 'Cotă standard 10%. '}'
                                  '${isSelected ? 'Selectat' : 'Neselectat'}',
                              button: true,
                              selected: isSelected,
                              child: Material(
                                color: isSelected
                                    ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                                    : null,
                                child: InkWell(
                                  onTap: () => _toggleCodeSelection(code),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: colorScheme.outlineVariant,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Selection indicator
                                        if (widget.multiSelect)
                                          Padding(
                                            padding: const EdgeInsets.only(right: 12),
                                            child: ExcludeSemantics(
                                              child: Checkbox(
                                                value: isSelected,
                                                onChanged: (_) => _toggleCodeSelection(code),
                                              ),
                                            ),
                                          )
                                        else if (isSelected)
                                          Padding(
                                            padding: const EdgeInsets.only(right: 12, top: 2),
                                            child: Icon(
                                              Icons.check_circle,
                                              color: colorScheme.primary,
                                              size: 24,
                                            ),
                                          ),

                                        // Code and description
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Code number with badge
                                              Row(
                                                children: [
                                                  ExcludeSemantics(
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: code.hasSpecialTaxRate
                                                            ? colorScheme.tertiaryContainer
                                                            : colorScheme.secondaryContainer,
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        code.code,
                                                        style: theme.textTheme.labelLarge?.copyWith(
                                                          fontWeight: FontWeight.bold,
                                                          color: code.hasSpecialTaxRate
                                                              ? colorScheme.onTertiaryContainer
                                                              : colorScheme.onSecondaryContainer,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  if (code.hasSpecialTaxRate) ...[
                                                    const SizedBox(width: 8),
                                                    ExcludeSemantics(
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: colorScheme.tertiary,
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: Text(
                                                          '3%',
                                                          style: theme.textTheme.labelSmall?.copyWith(
                                                            color: colorScheme.onTertiary,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 6),

                                              // Description
                                              ExcludeSemantics(
                                                child: Text(
                                                  code.description,
                                                  style: theme.textTheme.bodyMedium,
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
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _repository.dispose();
    super.dispose();
  }
}
