import 'package:flutter_test/flutter_test.dart';
import 'package:pfa_helper/models/caen_code.dart';

void main() {
  group('CAENCode Model Tests', () {
    test('CAENCode should be created with required fields', () {
      final caen = CAENCode(
        code: '6201',
        description: 'Activități de realizare a soft-ului la comandă',
      );

      expect(caen.code, '6201');
      expect(caen.description,
          'Activități de realizare a soft-ului la comandă');
      expect(caen.hasSpecialTaxRate, false); // Default
      expect(caen.isPrimary, false); // Default
    });

    test('CAENCode should support special tax rate', () {
      final caen = CAENCode(
        code: '6201',
        description: 'Software Development',
        hasSpecialTaxRate: true,
        specialTaxRate: 0.03,
      );

      expect(caen.hasSpecialTaxRate, true);
      expect(caen.specialTaxRate, 0.03);
      expect(caen.effectiveIncomeTaxRate, 0.03);
    });

    test('CAENCode should return 10% standard rate when no special rate', () {
      final caen = CAENCode(
        code: '7022',
        description: 'Business Consulting',
      );

      expect(caen.effectiveIncomeTaxRate, 0.10);
    });

    test('CAENCode should identify IT special rate codes', () {
      const itCodes = ['6201', '6202', '6209', '6210', '5821', '5829', '6311', '6312'];

      for (final code in itCodes) {
        expect(
          CAENCode.hasSpecialRate(code),
          true,
          reason: 'Code $code should have special rate',
        );
      }
    });

    test('CAENCode should not give special rate to non-IT codes', () {
      const nonItCodes = ['7022', '7311', '7410', '8559'];

      for (final code in nonItCodes) {
        expect(
          CAENCode.hasSpecialRate(code),
          false,
          reason: 'Code $code should not have special rate',
        );
      }
    });

    test('CAENCode.getCommonCAENCodes should return predefined list', () {
      final commonCodes = CAENCode.getCommonCAENCodes();

      expect(commonCodes, isNotEmpty);
      expect(commonCodes.length, greaterThan(5));

      // Check some IT codes have special rates
      final itCode = commonCodes.firstWhere((c) => c.code == '6201');
      expect(itCode.hasSpecialTaxRate, true);
      expect(itCode.specialTaxRate, 0.03);

      // Check some non-IT codes don't have special rates
      final nonItCode = commonCodes.firstWhere((c) => c.code == '7022');
      expect(nonItCode.hasSpecialTaxRate, false);
    });

    test('CAENCode should mark primary activity', () {
      final primary = CAENCode(
        code: '6201',
        description: 'Software Development',
        isPrimary: true,
      );

      final secondary = CAENCode(
        code: '6202',
        description: 'IT Consulting',
        isPrimary: false,
      );

      expect(primary.isPrimary, true);
      expect(secondary.isPrimary, false);
    });

    test('CAENCode.copyWith should update specified fields', () {
      final original = CAENCode(
        code: '6201',
        description: 'Original Description',
      );

      final updated = original.copyWith(
        description: 'Updated Description',
        isPrimary: true,
      );

      expect(updated.description, 'Updated Description');
      expect(updated.isPrimary, true);
      expect(updated.code, '6201'); // Unchanged
    });

    test('CAENCode.toString should return formatted string', () {
      final caen = CAENCode(
        code: '6201',
        description: 'Software Development',
      );

      expect(caen.toString(), '6201 - Software Development');
    });

    test('CAENCode.specialRateCodes should contain all IT codes', () {
      final specialCodes = CAENCode.specialRateCodes;

      expect(specialCodes, contains('6201')); // Computer programming
      expect(specialCodes, contains('6202')); // IT consultancy
      expect(specialCodes, contains('6209')); // Other IT services
      expect(specialCodes, contains('6210')); // Custom software
      expect(specialCodes, contains('5821')); // Publishing games
      expect(specialCodes, contains('5829')); // Other software publishing
      expect(specialCodes, contains('6311')); // Data processing
      expect(specialCodes, contains('6312')); // Web portals
    });

    test('CAENCode effective rate should prioritize special rate', () {
      final withSpecial = CAENCode(
        code: '6201',
        description: 'Software',
        hasSpecialTaxRate: true,
        specialTaxRate: 0.03,
      );

      final withoutSpecial = CAENCode(
        code: '6201',
        description: 'Software',
        hasSpecialTaxRate: false,
      );

      expect(withSpecial.effectiveIncomeTaxRate, 0.03);
      expect(withoutSpecial.effectiveIncomeTaxRate, 0.10);
    });
  });
}
