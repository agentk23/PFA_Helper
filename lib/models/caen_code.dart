import 'package:hive/hive.dart';

part 'caen_code.g.dart';

/// CAEN code (Classification of Activities in National Economy)
@HiveType(typeId: 3)
class CaenCode {
  @HiveField(0)
  final String code;

  @HiveField(1)
  final String description;

  @HiveField(2)
  final String category;

  CaenCode({
    required this.code,
    required this.description,
    required this.category,
  });
}

/// Common CAEN codes for PFA activities
class CommonCaenCodes {
  static final List<CaenCode> codes = [
    CaenCode(
      code: '6201',
      description: 'Activități de realizare a soft-ului la comandă',
      category: 'IT',
    ),
    CaenCode(
      code: '6202',
      description: 'Activități de consultanță în tehnologia informației',
      category: 'IT',
    ),
    CaenCode(
      code: '6209',
      description: 'Alte activități de servicii privind tehnologia informației',
      category: 'IT',
    ),
    CaenCode(
      code: '7022',
      description: 'Activități de consultanță în management',
      category: 'Consultanță',
    ),
    CaenCode(
      code: '7311',
      description: 'Activități ale agențiilor de publicitate',
      category: 'Marketing',
    ),
    CaenCode(
      code: '7410',
      description: 'Activități de design specializat',
      category: 'Design',
    ),
    CaenCode(
      code: '7420',
      description: 'Activități fotografice',
      category: 'Fotografie',
    ),
    CaenCode(
      code: '7430',
      description: 'Activități de traducere scrisă și orală',
      category: 'Traduceri',
    ),
    CaenCode(
      code: '8559',
      description: 'Alte forme de învățământ',
      category: 'Educație',
    ),
    CaenCode(
      code: '9003',
      description: 'Creație artistică și literară',
      category: 'Arte',
    ),
  ];
}
