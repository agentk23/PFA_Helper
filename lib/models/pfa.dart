import 'package:hive/hive.dart';

part 'pfa.g.dart';

/// PFA (Persoană Fizică Autorizată) model
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
  String activityType; // Type of activity/profession

  PFA({
    required this.cui,
    required this.name,
    required this.address,
    this.phone,
    this.email,
    required this.registrationDate,
    required this.isRealSystem,
    required this.activityType,
  });

  PFA copyWith({
    String? cui,
    String? name,
    String? address,
    String? phone,
    String? email,
    DateTime? registrationDate,
    bool? isRealSystem,
    String? activityType,
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
    );
  }
}
