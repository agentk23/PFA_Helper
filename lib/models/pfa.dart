import 'package:hive/hive.dart';
import 'caen_code.dart';

part 'pfa.g.dart';

/// PFA (Persoană Fizică Autorizată) model
/// According to Emergency Ordinance no. 44/2008, a PFA can have maximum 5 CAEN codes
@HiveType(typeId: 1)
class PFA extends HiveObject {
  @HiveField(0)
  String cui; // CUI - Cod Unic de Identificare (unique tax ID)

  @HiveField(1)
  String name; // Full name of the PFA

  @HiveField(2)
  String address; // Business address

  @HiveField(3)
  String? phone; // Optional phone number

  @HiveField(4)
  String? email; // Optional email

  @HiveField(5)
  DateTime registrationDate; // Date when PFA was registered

  @HiveField(6)
  bool isRealSystem; // true = Sistem Real, false = Norme de venit

  @HiveField(7)
  String activityType; // Type of activity/profession (legacy field for backward compatibility)

  @HiveField(8)
  List<CAENCode>? caenCodes; // Maximum 5 CAEN codes as per legislation

  /// Maximum number of CAEN codes allowed per PFA (Romanian legislation)
  static const int maxCAENCodes = 5;

  PFA({
    required this.cui,
    required this.name,
    required this.address,
    this.phone,
    this.email,
    required this.registrationDate,
    required this.isRealSystem,
    required this.activityType,
    this.caenCodes,
  }) {
    // Ensure we don't exceed the maximum number of CAEN codes
    if (caenCodes != null && caenCodes!.length > maxCAENCodes) {
      throw ArgumentError(
        'A PFA can have maximum $maxCAENCodes CAEN codes (Emergency Ordinance no. 44/2008)',
      );
    }
  }

  /// Get primary CAEN code (the main business activity)
  CAENCode? get primaryCAENCode {
    if (caenCodes == null || caenCodes!.isEmpty) return null;
    return caenCodes!.firstWhere(
      (code) => code.isPrimary,
      orElse: () => caenCodes!.first,
    );
  }

  /// Check if PFA can add more CAEN codes
  bool get canAddMoreCAENCodes {
    return caenCodes == null || caenCodes!.length < maxCAENCodes;
  }

  /// Get number of registered CAEN codes
  int get caenCodeCount {
    return caenCodes?.length ?? 0;
  }

  /// Check if any CAEN code has special tax rate
  bool get hasSpecialTaxRate {
    return caenCodes?.any((code) => code.hasSpecialTaxRate) ?? false;
  }

  PFA copyWith({
    String? cui,
    String? name,
    String? address,
    String? phone,
    String? email,
    DateTime? registrationDate,
    bool? isRealSystem,
    String? activityType,
    List<CAENCode>? caenCodes,
  }) {
    return PFA(
      cui: cui ?? this.cui,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      registrationDate: registrationDate ?? this.registrationDate,
      isRealSystem: isRealSystem ?? this.isRealSystem,
      activityType: activityType ?? this.activityType,
      caenCodes: caenCodes ?? this.caenCodes,
    );
  }
}
