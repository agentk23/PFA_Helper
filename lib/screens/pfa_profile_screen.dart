import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../models/pfa.dart';
import '../models/caen_code.dart';
import '../services/storage_service.dart';
import '../services/anaf_api_service.dart';
import 'caen_picker_screen.dart';
import 'dart:developer' as developer;

/// Accessible PFA profile and settings screen
///
/// Features:
/// - Edit all PFA information
/// - Manage CAEN codes (max 5 per legislation)
/// - ANAF CUI validation and company info refresh
/// - Change primary activity designation
/// - Full accessibility support
/// - Responsive layout
class PFAProfileScreen extends StatefulWidget {
  const PFAProfileScreen({super.key});

  @override
  State<PFAProfileScreen> createState() => _PFAProfileScreenState();
}

class _PFAProfileScreenState extends State<PFAProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cuiController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  final _cuiFocusNode = FocusNode();
  final _nameFocusNode = FocusNode();
  final _addressFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();

  PFA? _currentPFA;
  DateTime _registrationDate = DateTime.now();
  bool _isRealSystem = true;
  List<CAENCode> _selectedCAENCodes = [];
  bool _isValidatingCUI = false;
  bool _isSaving = false;
  bool _isLoading = true;
  String? _cuiValidationMessage;

  final ANAFApiService _anafService = ANAFApiService();

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await _anafService.initialize();
    await _loadPFAData();
  }

  Future<void> _loadPFAData() async {
    try {
      final pfa = StorageService.getCurrentPFA();

      if (pfa == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nu s-a găsit niciun PFA înregistrat'),
            ),
          );
          context.go('/registration');
        }
        return;
      }

      setState(() {
        _currentPFA = pfa;
        _cuiController.text = pfa.cui;
        _nameController.text = pfa.name;
        _addressController.text = pfa.address;
        _phoneController.text = pfa.phone ?? '';
        _emailController.text = pfa.email ?? '';
        _registrationDate = pfa.registrationDate;
        _isRealSystem = pfa.isRealSystem;
        _selectedCAENCodes = List.from(pfa.caenCodes ?? []);
        _isLoading = false;
      });

      developer.log('Loaded PFA data: ${pfa.name}', name: 'PFAProfileScreen');
    } catch (e, stackTrace) {
      developer.log(
        'Failed to load PFA data',
        name: 'PFAProfileScreen',
        error: e,
        stackTrace: stackTrace,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la încărcare: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _cuiController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
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

      if (result.success && result.data == true) {
        // Try to get company info
        final infoResult = await _anafService.getCompanyInfo(cui);

        if (mounted) {
          setState(() {
            _cuiValidationMessage = 'CUI valid ✓';
            _isValidatingCUI = false;
          });

          if (infoResult.success) {
            final companyData = infoResult.data!;
            final dateGenerale = companyData['date_generale'] as Map<String, dynamic>?;

            if (dateGenerale != null) {
              // Show dialog to confirm update
              final shouldUpdate = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Actualizare date ANAF'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Date găsite în ANAF:'),
                      const SizedBox(height: 12),
                      Text(
                        'Denumire: ${dateGenerale['denumire'] ?? 'N/A'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('Adresă: ${dateGenerale['adresa'] ?? 'N/A'}'),
                      const SizedBox(height: 16),
                      const Text('Doriți să actualizați aceste informații?'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Nu'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Da, actualizează'),
                    ),
                  ],
                ),
              );

              if (shouldUpdate == true && mounted) {
                setState(() {
                  final denumire = dateGenerale['denumire'] as String?;
                  if (denumire != null) {
                    _nameController.text = denumire;
                  }

                  final adresa = dateGenerale['adresa'] as String?;
                  if (adresa != null) {
                    _addressController.text = adresa;
                  }
                });

                SemanticsService.announce(
                  'Date actualizate din ANAF',
                  Assertiveness.polite,
                );
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
        name: 'PFAProfileScreen',
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
            dialogTheme: DialogThemeData(
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
        SemanticsService.announce(
          'Data înregistrării selectată: ${DateFormat('dd MMMM yyyy').format(picked)}',
          Assertiveness.polite,
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
          Assertiveness.polite,
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
        Assertiveness.polite,
      );
    }
  }

  void _removeCAENCode(int index) {
    if (_selectedCAENCodes.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Trebuie să aveți cel puțin un cod CAEN',
            semanticsLabel: 'Eroare: Minim un cod CAEN necesar',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() {
      _selectedCAENCodes.removeAt(index);
    });

    if (mounted) {
      SemanticsService.announce(
        'Cod CAEN eliminat. ${_selectedCAENCodes.length} coduri rămase',
        Assertiveness.polite,
      );
    }
  }

  Future<void> _savePFA() async {
    if (!_formKey.currentState!.validate()) {
      SemanticsService.announce(
        'Formularul conține erori. Verificați câmpurile marcate.',
        Assertiveness.assertive,
      );
      return;
    }

    if (_selectedCAENCodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Selectați cel puțin un cod CAEN',
            semanticsLabel: 'Eroare: Selectați cel puțin un cod CAEN',
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
      final updatedPFA = PFA(
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
        activityType: _selectedCAENCodes.first.description,
        caenCodes: _selectedCAENCodes,
      );

      await StorageService.savePFA(updatedPFA);

      if (mounted) {
        setState(() {
          _currentPFA = updatedPFA;
          _isSaving = false;
        });

        SemanticsService.announce(
          'Profil actualizat cu succes',
          Assertiveness.polite,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Profil actualizat cu succes!',
              semanticsLabel: 'Succes: Profil actualizat',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        'Failed to save PFA',
        name: 'PFAProfileScreen',
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
              semanticsLabel: 'Eroare: Nu s-a putut actualiza profilul',
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

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profil PFA'),
          centerTitle: true,
        ),
        body: Center(
          child: Semantics(
            label: 'Se încarcă datele profilului',
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Se încarcă...'),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil PFA'),
        centerTitle: true,
        actions: [
          Semantics(
            label: 'Reîmprospătează date din ANAF',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Reîmprospătează din ANAF',
              onPressed: _validateCUI,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with PFA info
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: colorScheme.primaryContainer,
                              child: Icon(
                                Icons.business,
                                size: 32,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Semantics(
                                    header: true,
                                    child: Text(
                                      _currentPFA?.name ?? '',
                                      style: textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'CUI: ${_currentPFA?.cui ?? ''}',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    'Înregistrat: ${DateFormat('dd.MM.yyyy').format(_registrationDate)}',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Section header
                Semantics(
                  header: true,
                  child: Text(
                    'Informații generale',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // CUI Field
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
                    onEditingComplete: () => _nameFocusNode.requestFocus(),
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
                const SizedBox(height: 16),

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
                const SizedBox(height: 16),

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
                const SizedBox(height: 24),

                // CAEN Codes Section
                Semantics(
                  header: true,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Coduri CAEN (${_selectedCAENCodes.length}/${PFA.maxCAENCodes})',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_selectedCAENCodes.length < PFA.maxCAENCodes)
                        Semantics(
                          label: 'Adaugă cod CAEN',
                          button: true,
                          child: TextButton.icon(
                            onPressed: _selectCAENCodes,
                            icon: const Icon(Icons.add),
                            label: const Text('Adaugă'),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                if (_selectedCAENCodes.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.work_off,
                              size: 48,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Niciun cod CAEN selectat',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ListView.builder(
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
                              ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                              : null,
                          child: ListTile(
                            leading: code.isPrimary
                                ? Icon(Icons.star, color: colorScheme.primary)
                                : Icon(Icons.star_border,
                                    color: colorScheme.onSurfaceVariant),
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
                const SizedBox(height: 24),

                // Contact Information Section
                Semantics(
                  header: true,
                  child: Text(
                    'Informații de contact',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Phone Field
                Semantics(
                  label: 'Telefon - câmp opțional',
                  textField: true,
                  child: TextFormField(
                    controller: _phoneController,
                    focusNode: _phoneFocusNode,
                    decoration: const InputDecoration(
                      labelText: 'Telefon',
                      hintText: 'Ex: 0712345678',
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
                const SizedBox(height: 16),

                // Email Field
                Semantics(
                  label: 'Email - câmp opțional',
                  textField: true,
                  child: TextFormField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'Ex: contact@pfa.ro',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final emailRegex =
                            RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(value)) {
                          return 'Email invalid';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Settings Section
                Semantics(
                  header: true,
                  child: Text(
                    'Setări',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

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
                const SizedBox(height: 12),

                // Tax System
                Card(
                  child: Column(
                    children: [
                      Semantics(
                        label: _isRealSystem
                            ? 'Sistem Real selectat'
                            : 'Norme de venit selectat',
                        child: RadioListTile<bool>(
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
                              Assertiveness.polite,
                            );
                          },
                        ),
                      ),
                      Semantics(
                        label: !_isRealSystem
                            ? 'Norme de venit selectat'
                            : 'Sistem Real selectat',
                        child: RadioListTile<bool>(
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
                              Assertiveness.polite,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Save Button
                Semantics(
                  label: _isSaving
                      ? 'Se salvează modificările...'
                      : 'Salvează modificările - buton',
                  button: true,
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _savePFA,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Se salvează...' : 'Salvează modificările'),
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
