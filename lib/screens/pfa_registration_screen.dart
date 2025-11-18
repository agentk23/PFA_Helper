import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/pfa.dart';
import '../models/caen_code.dart';
import '../services/storage_service.dart';

/// Screen for PFA registration/profile editing
class PFARegistrationScreen extends StatefulWidget {
  const PFARegistrationScreen({super.key});

  @override
  State<PFARegistrationScreen> createState() => _PFARegistrationScreenState();
}

class _PFARegistrationScreenState extends State<PFARegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _cuiController = TextEditingController();

  CaenCode? _selectedCaenCode;
  TaxationSystem _taxationSystem = TaxationSystem.realIncome;
  bool _isVATRegistered = false;
  DateTime? _vatRegistrationDate;

  @override
  void initState() {
    super.initState();
    _loadExistingPFA();
  }

  void _loadExistingPFA() {
    final pfa = StorageService.getPFA();
    if (pfa != null) {
      _firstNameController.text = pfa.firstName;
      _lastNameController.text = pfa.lastName;
      _cuiController.text = pfa.cui;
      _taxationSystem = pfa.taxationSystem;
      _isVATRegistered = pfa.isVATRegistered;
      _vatRegistrationDate = pfa.vatRegistrationDate;

      // Find matching CAEN code
      _selectedCaenCode = CommonCaenCodes.codes.firstWhere(
        (code) => code.code == pfa.caenCode,
        orElse: () => CommonCaenCodes.codes.first,
      );
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _cuiController.dispose();
    super.dispose();
  }

  Future<void> _savePFA() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCaenCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selectați codul CAEN')),
      );
      return;
    }

    final pfa = PFA(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      cui: _cuiController.text.trim(),
      caenCode: _selectedCaenCode!.code,
      caenDescription: _selectedCaenCode!.description,
      registrationDate: DateTime.now(),
      taxationSystem: _taxationSystem,
      isVATRegistered: _isVATRegistered,
      vatRegistrationDate: _vatRegistrationDate,
    );

    await StorageService.savePFA(pfa);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profilul PFA a fost salvat')),
      );
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final existingPFA = StorageService.getPFA();

    return Scaffold(
      appBar: AppBar(
        title: Text(existingPFA == null ? 'Înregistrare PFA' : 'Editare profil PFA'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Informații personale',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              // First Name
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Prenume',
                  prefixIcon: Icon(Icons.person),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Introduceți prenumele';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Last Name
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Nume',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Introduceți numele';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // CUI
              TextFormField(
                controller: _cuiController,
                decoration: const InputDecoration(
                  labelText: 'CUI (Cod Unic de Identificare)',
                  prefixIcon: Icon(Icons.numbers),
                  hintText: 'RO12345678',
                ),
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Introduceți CUI-ul';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // CAEN Code Selection
              Text(
                'Cod CAEN',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<CaenCode>(
                value: _selectedCaenCode,
                decoration: const InputDecoration(
                  labelText: 'Selectați codul CAEN',
                  prefixIcon: Icon(Icons.business),
                ),
                items: CommonCaenCodes.codes.map((code) {
                  return DropdownMenuItem(
                    value: code,
                    child: Text(
                      '${code.code} - ${code.description}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCaenCode = value;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Taxation System
              Text(
                'Sistem de taxare',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              RadioListTile<TaxationSystem>(
                title: const Text('Venit real'),
                subtitle: const Text('Taxare pe baza veniturilor și cheltuielilor reale'),
                value: TaxationSystem.realIncome,
                groupValue: _taxationSystem,
                onChanged: (value) {
                  setState(() {
                    _taxationSystem = value!;
                  });
                },
              ),
              RadioListTile<TaxationSystem>(
                title: const Text('Norme de venit'),
                subtitle: const Text('Taxare pe baza normelor stabilite'),
                value: TaxationSystem.norms,
                groupValue: _taxationSystem,
                onChanged: (value) {
                  setState(() {
                    _taxationSystem = value!;
                  });
                },
              ),
              const SizedBox(height: 24),

              // VAT Registration
              SwitchListTile(
                title: const Text('Înregistrat în scopuri de TVA'),
                subtitle: const Text('Bifați dacă PFA-ul este plătitor de TVA'),
                value: _isVATRegistered,
                onChanged: (value) {
                  setState(() {
                    _isVATRegistered = value;
                    if (!value) {
                      _vatRegistrationDate = null;
                    }
                  });
                },
              ),
              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _savePFA,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  existingPFA == null ? 'Salvează și continuă' : 'Actualizează profil',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
