import 'package:hive/hive.dart';

part 'caen_code.g.dart';

/// CAEN code model representing economic activity classification
/// Romania uses CAEN Rev.3 as of January 1, 2025
@HiveType(typeId: 3)
class CAENCode extends HiveObject {
  @HiveField(0)
  String code; // CAEN code (e.g., "6201", "6202")

  @HiveField(1)
  String description; // Activity description

  @HiveField(2)
  bool hasSpecialTaxRate; // Whether this CAEN has special tax rate

  @HiveField(3)
  double? specialTaxRate; // Special tax rate if applicable (e.g., 0.03 for 3%)

  @HiveField(4)
  bool isPrimary; // Whether this is the primary activity

  CAENCode({
    required this.code,
    required this.description,
    this.hasSpecialTaxRate = false,
    this.specialTaxRate,
    this.isPrimary = false,
  });

  /// Get effective income tax rate for this CAEN code
  /// Some CAEN codes have special 3% rate (e.g., 6210 - Custom software development)
  double get effectiveIncomeTaxRate {
    if (hasSpecialTaxRate && specialTaxRate != null) {
      return specialTaxRate!;
    }
    return 0.10; // Standard 10% income tax
  }

  CAENCode copyWith({
    String? code,
    String? description,
    bool? hasSpecialTaxRate,
    double? specialTaxRate,
    bool? isPrimary,
  }) {
    return CAENCode(
      code: code ?? this.code,
      description: description ?? this.description,
      hasSpecialTaxRate: hasSpecialTaxRate ?? this.hasSpecialTaxRate,
      specialTaxRate: specialTaxRate ?? this.specialTaxRate,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }

  @override
  String toString() => '$code - $description';

  /// Common CAEN codes with special tax rates (3% rate)
  /// As of 2025, these include software development and IT services
  static List<String> get specialRateCodes => [
        '6201', // Computer programming activities
        '6202', // Computer consultancy activities
        '6209', // Other information technology service activities
        '6210', // Custom software development
        '5821', // Publishing of computer games
        '5829', // Other software publishing
        '6311', // Data processing, hosting and related activities
        '6312', // Web portals
      ];

  /// Check if a CAEN code qualifies for special tax rate
  static bool hasSpecialRate(String code) {
    return specialRateCodes.contains(code);
  }

  /// Get predefined common CAEN codes for IT/Consulting activities
  static List<CAENCode> getCommonCAENCodes() {
    return [
      CAENCode(
        code: '6201',
        description: 'Activități de realizare a soft-ului la comandă',
        hasSpecialTaxRate: true,
        specialTaxRate: 0.03,
      ),
      CAENCode(
        code: '6202',
        description: 'Activități de consultanță în tehnologia informației',
        hasSpecialTaxRate: true,
        specialTaxRate: 0.03,
      ),
      CAENCode(
        code: '6209',
        description: 'Alte activități de servicii privind tehnologia informației',
        hasSpecialTaxRate: true,
        specialTaxRate: 0.03,
      ),
      CAENCode(
        code: '7022',
        description: 'Activități de consultanță pentru afaceri și management',
        hasSpecialTaxRate: false,
      ),
      CAENCode(
        code: '7311',
        description: 'Activități ale agențiilor de publicitate',
        hasSpecialTaxRate: false,
      ),
      CAENCode(
        code: '7320',
        description: 'Activități de studiere a pieței și de sondare a opiniei publice',
        hasSpecialTaxRate: false,
      ),
      CAENCode(
        code: '7410',
        description: 'Activități de design specializat',
        hasSpecialTaxRate: false,
      ),
      CAENCode(
        code: '7420',
        description: 'Activități fotografice',
        hasSpecialTaxRate: false,
      ),
      CAENCode(
        code: '7430',
        description: 'Activități de traducere scrisă și orală',
        hasSpecialTaxRate: false,
      ),
      CAENCode(
        code: '8559',
        description: 'Alte forme de învățământ',
        hasSpecialTaxRate: false,
      ),
      CAENCode(
        code: '9001',
        description: 'Activități de interpretare artistică (spectacole)',
        hasSpecialTaxRate: false,
      ),
      CAENCode(
        code: '9002',
        description: 'Activități suport pentru interpretare artistică',
        hasSpecialTaxRate: false,
      ),
    ];
  }
}
