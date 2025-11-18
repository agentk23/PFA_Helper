import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../models/pfa.dart';
import '../models/caen_code.dart';
import '../services/storage_service.dart';
import '../services/anaf_api_service.dart';
import 'caen_picker_screen.dart';
import 'dart:developer' as developer;

/// Accessible PFA registration screen
///
/// Features:
/// - Full keyboard navigation and screen reader support
/// - ANAF CUI validation
/// - CAEN code selection with repository integration
/// - Step-by-step form with clear visual hierarchy
/// - Responsive layout for different screen sizes
/// - Clear error messaging and validation
/// - Auto-save functionality
class PFARegistrationScreen extends StatefulWidget {
  const PFARegistrationScreen({super.key});

  @override
  State<PFARegistrationScreen> createState() => _PFARegistrationScreenState();
}

class _PFARegistrationScreenState extends State<PFARegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cuiController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _activityTypeController = TextEditingController();

  final _cuiFocusNode = FocusNode();
  final _nameFocusNode = FocusNode();
  final _addressFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();

  DateTime _registrationDate = DateTime.now();
  bool _isRealSystem = true;
  List<CAENCode> _selectedCAENCodes = [];
  bool _isValidatingCUI = false;
  bool _isSaving = false;
  String? _cuiValidationMessage;

  final ANAFApiService _anafService = ANAFApiService();

  @override
  void initState() {
    super.initState();
    _initializeANAF();
  }

  Future<void> _initializeANAF() async {
    await _anafService.initialize();
  }

  @override
  void dispose() {
    _cuiController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _activityTypeController.dispose();
    _cuiFocusNode.dispose();
    _nameFocusNode.dispose();
    _addressFocusNode.dispose();
    _phoneFocusNode.dispose();
    _emailFocusNode.dispose();
    _anafService.dispose();
    super.dispose();
  }

  /// Validate CUI with ANAF
  Future<void> _validateCUI() async {
    final cui = _cuiController.text.trim();
    if (cui.isEmpty) return;

    setState(() {
      _isValidatingCUI = true;
      _cuiValidationMessage = null;
    });

    try {
      final result = await _anafService.validateCUI(cui);

      if (result.isSuccess && result.data == true) {
        // Try to get company info
        final infoResult = await _anafService.getCompanyInfo(cui);

        if (mounted) {
          setState(() {
            _cuiValidationMessage = 'CUI valid ✓';
            _isValidatingCUI = false;
          });

          if (infoResult.isSuccess) {
            final companyData = infoResult.data!;
            final dateGenerale = companyData['date_generale'] as Map<String, dynamic>?;

            if (dateGenerale != null) {
              // Auto-fill company name if empty
              if (_nameController.text.isEmpty) {
                final denumire = dateGenerale['denumire'] as String?;
                if (denumire != null) {
                  _nameController.text = denumire;
                }
              }

              // Auto-fill address if empty
              if (_addressController.text.isEmpty) {
                final adresa = dateGenerale['adresa'] as String?;
                if (adresa != null) {
                  _addressController.text = adresa;
                }
              }
            }
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _cuiValidationMessage = 'CUI invalid sau nu a fost găsit';
            _isValidatingCUI = false;
          });
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        'Failed to validate CUI',
        name: 'PFARegistrationScreen',
        error: e,
        stackTrace: stackTrace,
      );

      if (mounted) {
        setState(() {
          _cuiValidationMessage = 'Eroare la validare. Verificați conexiunea.';
          _isValidatingCUI = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _registrationDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Selectați data înregistrării',
      cancelText: 'Anulează',
      confirmText: 'Confirmă',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            dialogTheme: DialogTheme(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _registrationDate) {
      setState(() {
        _registrationDate = picked;
      });

      if (mounted) {
        // Announce date change to screen readers
        SemanticsService.announce(
          'Data înregistrării selectată: ${DateFormat('dd MMMM yyyy').format(picked)}',
          TextDirection.ltr,
        );
      }
    }
  }

  Future<void> _selectCAENCodes() async {
    final result = await Navigator.of(context).push<List<CAENCode>>(
      MaterialPageRoute(
        builder: (context) => CAENPickerScreen(
          maxSelection: PFA.maxCAENCodes,
          selectedCodes: _selectedCAENCodes.map((c) => c.code).toList(),
          multiSelect: true,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedCAENCodes = result;
      });

      if (mounted) {
        SemanticsService.announce(
          '${result.length} coduri CAEN selectate',
          TextDirection.ltr,
        );
      }
    }
  }

  void _setPrimaryCAENCode(int index) {
    setState(() {
      // Clear all primary flags
      for (var code in _selectedCAENCodes) {
        code.isPrimary = false;
      }
      // Set the selected one as primary
      _selectedCAENCodes[index].isPrimary = true;
    });

    if (mounted) {
      SemanticsService.announce(
        '${_selectedCAENCodes[index].code} setat ca activitate principală',
        TextDirection.ltr,
      );
    }
  }

  void _removeCAENCode(int index) {
    setState(() {
      _selectedCAENCodes.removeAt(index);
    });

    if (mounted) {
      SemanticsService.announce(
        'Cod CAEN eliminat. ${_selectedCAENCodes.length} coduri rămase',
        TextDirection.ltr,
      );
    }
  }

  Future<void> _savePFA() async {
    if (!_formKey.currentState!.validate()) {
      // Announce validation errors to screen readers
      SemanticsService.announce(
        'Formularul conține erori. Verificați câmpurile marcate.',
        TextDirection.ltr,
      );
      return;
    }

    if (_selectedCAENCodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Selectați cel puțin un cod CAEN',
            semanticsLabel: 'Eroare: Selectați cel puțin un cod CAEN pentru activitatea dumneavoastră',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final pfa = PFA(
        cui: _cuiController.text.trim(),
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        registrationDate: _registrationDate,
        isRealSystem: _isRealSystem,
        activityType: _activityTypeController.text.trim().isEmpty
            ? _selectedCAENCodes.first.description
            : _activityTypeController.text.trim(),
        caenCodes: _selectedCAENCodes,
      );

      await StorageService.savePFA(pfa);

      if (mounted) {
        SemanticsService.announce(
          'PFA înregistrat cu succes',
          TextDirection.ltr,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'PFA înregistrat cu succes!',
              semanticsLabel: 'Succes: PFA a fost înregistrat',
            ),
            backgroundColor: Colors.green,
          ),
        );

        context.go('/');
      }
    } catch (e, stackTrace) {
      developer.log(
        'Failed to save PFA',
        name: 'PFARegistrationScreen',
        error: e,
        stackTrace: stackTrace,
      );

      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Eroare la salvare: ${e.toString()}',
              semanticsLabel: 'Eroare: Nu s-a putut salva PFA',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
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
        title: const Text('Înregistrare PFA'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Semantics(
                  header: true,
                  child: Text(
                    'Completați informațiile PFA',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Câmpurile marcate cu * sunt obligatorii',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),

                // CUI Field with validation
                Semantics(
                  label: 'Cod Unic de Identificare CUI - câmp obligatoriu',
                  textField: true,
                  child: TextFormField(
                    controller: _cuiController,
                    focusNode: _cuiFocusNode,
                    decoration: InputDecoration(
                      labelText: 'CUI *',
                      hintText: 'Ex: 12345678 sau RO12345678',
                      helperText: _cuiValidationMessage,
                      helperStyle: TextStyle(
                        color: _cuiValidationMessage?.contains('✓') == true
                            ? Colors.green
                            : colorScheme.error,
                      ),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.badge),
                      suffixIcon: _isValidatingCUI
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Icons.check_circle_outline),
                              tooltip: 'Validează CUI cu ANAF',
                              onPressed: _validateCUI,
                            ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9RO]')),
                    ],
                    textInputAction: TextInputAction.next,
                    onEditingComplete: () {
                      _validateCUI();
                      _nameFocusNode.requestFocus();
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'CUI este obligatoriu';
                      }
                      final cleanCUI = value.replaceAll('RO', '').trim();
                      if (cleanCUI.length < 6) {
                        return 'CUI trebuie să aibă cel puțin 6 cifre';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Name Field
                Semantics(
                  label: 'Nume complet - câmp obligatoriu',
                  textField: true,
                  child: TextFormField(
                    controller: _nameController,
                    focusNode: _nameFocusNode,
                    decoration: const InputDecoration(
                      labelText: 'Nume complet *',
                      hintText: 'Ex: Popescu Ion PFA',
                      helperText: 'Numele complet așa cum apare în certificatul de înregistrare',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    onEditingComplete: () => _addressFocusNode.requestFocus(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Numele este obligatoriu';
                      }
                      if (value.length < 3) {
                        return 'Numele trebuie să aibă cel puțin 3 caractere';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Address Field
                Semantics(
                  label: 'Adresă - câmp obligatoriu',
                  textField: true,
                  child: TextFormField(
                    controller: _addressController,
                    focusNode: _addressFocusNode,
                    decoration: const InputDecoration(
                      labelText: 'Adresă *',
                      hintText: 'Ex: Str. Principală nr. 1, București',
                      helperText: 'Adresa sediului PFA',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    onEditingComplete: () => _phoneFocusNode.requestFocus(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Adresa este obligatorie';
                      }
                      if (value.length < 10) {
                        return 'Introduceți o adresă completă';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // CAEN Codes Section
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.work, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Semantics(
                                header: true,
                                child: Text(
                                  'Coduri CAEN',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Selectați până la ${PFA.maxCAENCodes} coduri CAEN pentru activitățile dumneavoastră',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Selected CAEN codes
                        if (_selectedCAENCodes.isNotEmpty) ...[
                          Semantics(
                            label: '${_selectedCAENCodes.length} coduri CAEN selectate',
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _selectedCAENCodes.length,
                              itemBuilder: (context, index) {
                                final code = _selectedCAENCodes[index];
                                return Semantics(
                                  label: 'Cod CAEN ${code.code} - ${code.description}. '
                                      '${code.isPrimary ? 'Activitate principală. ' : ''}'
                                      '${code.hasSpecialTaxRate ? 'Cotă specială 3%' : 'Cotă standard 10%'}',
                                  button: true,
                                  child: Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    color: code.isPrimary
                                        ? colorScheme.primaryContainer.withOpacity(0.3)
                                        : null,
                                    child: ListTile(
                                      leading: code.isPrimary
                                          ? Icon(Icons.star, color: colorScheme.primary)
                                          : Icon(Icons.star_border, color: colorScheme.onSurfaceVariant),
                                      title: Row(
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
                                                style: textTheme.labelMedium?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (code.hasSpecialTaxRate) ...[
                                            const SizedBox(width: 6),
                                            ExcludeSemantics(
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 4,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: colorScheme.tertiary,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  '3%',
                                                  style: textTheme.labelSmall?.copyWith(
                                                    color: colorScheme.onTertiary,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      subtitle: ExcludeSemantics(
                                        child: Text(
                                          code.description,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (!code.isPrimary)
                                            IconButton(
                                              icon: const Icon(Icons.star_border),
                                              tooltip: 'Setează ca activitate principală',
                                              onPressed: () => _setPrimaryCAENCode(index),
                                            ),
                                          IconButton(
                                            icon: const Icon(Icons.delete),
                                            tooltip: 'Elimină codul CAEN',
                                            onPressed: () => _removeCAENCode(index),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],

                        // Add CAEN Code button
                        if (_selectedCAENCodes.length < PFA.maxCAENCodes)
                          Semantics(
                            label: 'Adaugă coduri CAEN. ${_selectedCAENCodes.length} din ${PFA.maxCAENCodes} selectate',
                            button: true,
                            child: OutlinedButton.icon(
                              onPressed: _selectCAENCodes,
                              icon: const Icon(Icons.add),
                              label: Text(_selectedCAENCodes.isEmpty
                                  ? 'Selectează coduri CAEN *'
                                  : 'Adaugă cod CAEN (${_selectedCAENCodes.length}/${PFA.maxCAENCodes})'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Phone Field (Optional)
                Semantics(
                  label: 'Telefon - câmp opțional',
                  textField: true,
                  child: TextFormField(
                    controller: _phoneController,
                    focusNode: _phoneFocusNode,
                    decoration: const InputDecoration(
                      labelText: 'Telefon',
                      hintText: 'Ex: 0712345678',
                      helperText: 'Opțional - număr de telefon de contact',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s()-]')),
                    ],
                    textInputAction: TextInputAction.next,
                    onEditingComplete: () => _emailFocusNode.requestFocus(),
                  ),
                ),
                const SizedBox(height: 20),

                // Email Field (Optional)
                Semantics(
                  label: 'Email - câmp opțional',
                  textField: true,
                  child: TextFormField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'Ex: contact@pfa.ro',
                      helperText: 'Opțional - adresă de email de contact',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(value)) {
                          return 'Email invalid';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Registration Date
                Semantics(
                  label: 'Data înregistrării: ${DateFormat('dd MMMM yyyy').format(_registrationDate)}',
                  button: true,
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Data înregistrării'),
                      subtitle: Text(
                        DateFormat('dd.MM.yyyy').format(_registrationDate),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: const Icon(Icons.edit),
                      onTap: () => _selectDate(context),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Tax System
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Row(
                            children: [
                              Icon(Icons.account_balance, color: colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Sistem de taxare',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Semantics(
                          label: _isRealSystem
                              ? 'Sistem Real selectat - Impozit pe profit real bazat pe venituri minus cheltuieli'
                              : 'Norme de venit selectat - Impozit pe venit normat fix',
                          child: Column(
                            children: [
                              RadioListTile<bool>(
                                title: const Text('Sistem Real'),
                                subtitle: const Text(
                                  'Impozit pe profit real (venituri - cheltuieli)',
                                ),
                                value: true,
                                groupValue: _isRealSystem,
                                onChanged: (value) {
                                  setState(() {
                                    _isRealSystem = value!;
                                  });
                                  SemanticsService.announce(
                                    'Sistem Real selectat',
                                    TextDirection.ltr,
                                  );
                                },
                              ),
                              RadioListTile<bool>(
                                title: const Text('Norme de venit'),
                                subtitle: const Text('Impozit pe venit normat (fix)'),
                                value: false,
                                groupValue: _isRealSystem,
                                onChanged: (value) {
                                  setState(() {
                                    _isRealSystem = value!;
                                  });
                                  SemanticsService.announce(
                                    'Norme de venit selectat',
                                    TextDirection.ltr,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Save Button
                Semantics(
                  label: _isSaving
                      ? 'Se salvează PFA...'
                      : 'Salvează PFA - buton',
                  button: true,
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _savePFA,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Se salvează...' : 'Salvează PFA'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
