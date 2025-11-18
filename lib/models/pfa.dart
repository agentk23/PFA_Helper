import 'package:hive/hive.dart';

part 'pfa.g.dart';

/// Taxation system for PFA
enum TaxationSystem {
  /// Real income - tax based on actual income minus deductible expenses
  realIncome,

  /// Norms-based income - tax based on predetermined norms
  norms,
}

/// PFA profile containing registration and taxation information
@HiveType(typeId: 0)
class PFA {
  @HiveField(0)
  final String firstName;

  @HiveField(1)
  final String lastName;

  @HiveField(2)
  final String cui; // Cod Unic de Identificare (Tax ID)

  @HiveField(3)
  final String caenCode; // Activity code

  @HiveField(4)
  final String caenDescription;

  @HiveField(5)
  final DateTime registrationDate;

  @HiveField(6)
  final TaxationSystem taxationSystem;

  @HiveField(7)
  final bool isVATRegistered; // TVA registration

  @HiveField(8)
  final DateTime? vatRegistrationDate;

  PFA({
    required this.firstName,
    required this.lastName,
    required this.cui,
    required this.caenCode,
    required this.caenDescription,
    required this.registrationDate,
    required this.taxationSystem,
    this.isVATRegistered = false,
    this.vatRegistrationDate,
  });

  String get fullName => '$firstName $lastName';

  PFA copyWith({
    String? firstName,
    String? lastName,
    String? cui,
    String? caenCode,
    String? caenDescription,
    DateTime? registrationDate,
    TaxationSystem? taxationSystem,
    bool? isVATRegistered,
    DateTime? vatRegistrationDate,
  }) {
    return PFA(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      cui: cui ?? this.cui,
      caenCode: caenCode ?? this.caenCode,
      caenDescription: caenDescription ?? this.caenDescription,
      registrationDate: registrationDate ?? this.registrationDate,
      taxationSystem: taxationSystem ?? this.taxationSystem,
      isVATRegistered: isVATRegistered ?? this.isVATRegistered,
      vatRegistrationDate: vatRegistrationDate ?? this.vatRegistrationDate,
    );
  }
}
