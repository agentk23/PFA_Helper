import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../models/pfa.dart';
import '../services/storage_service.dart';

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

  DateTime _registrationDate = DateTime.now();
  bool _isRealSystem = true;

  @override
  void dispose() {
    _cuiController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _activityTypeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _registrationDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _registrationDate) {
      setState(() {
        _registrationDate = picked;
      });
    }
  }

  Future<void> _savePFA() async {
    if (_formKey.currentState!.validate()) {
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
        activityType: _activityTypeController.text.trim(),
      );

      await StorageService.savePFA(pfa);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PFA înregistrat cu succes!'),
            backgroundColor: Colors.green,
          ),
        );

        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Înregistrare PFA'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Completează informațiile PFA',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // CUI
              TextFormField(
                controller: _cuiController,
                decoration: const InputDecoration(
                  labelText: 'CUI *',
                  hintText: 'Ex: 12345678',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'CUI este obligatoriu';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nume complet *',
                  hintText: 'Ex: Popescu Ion PFA',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Numele este obligatoriu';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Address
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Adresă *',
                  hintText: 'Ex: Str. Principală nr. 1, București',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Adresa este obligatorie';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Activity Type
              TextFormField(
                controller: _activityTypeController,
                decoration: const InputDecoration(
                  labelText: 'Tip activitate *',
                  hintText: 'Ex: Consultanță IT, Freelancing',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Tipul activității este obligatoriu';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefon',
                  hintText: 'Ex: 0712345678',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Ex: contact@pfa.ro',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Registration Date
              ListTile(
                title: const Text('Data înregistrării'),
                subtitle: Text(
                  DateFormat('dd.MM.yyyy').format(_registrationDate),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                leading: const Icon(Icons.calendar_today),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),

              // Tax System
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sistem de taxare',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RadioListTile<bool>(
                        title: const Text('Sistem Real'),
                        subtitle: const Text(
                            'Impozit pe profit real (venituri - cheltuieli)'),
                        value: true,
                        groupValue: _isRealSystem,
                        onChanged: (value) {
                          setState(() {
                            _isRealSystem = value!;
                          });
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
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _savePFA,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Salvează PFA',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
