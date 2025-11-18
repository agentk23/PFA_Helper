import 'package:flutter_test/flutter_test.dart';
import 'package:pfa_helper/models/pfa.dart';
import 'package:pfa_helper/models/caen_code.dart';

void main() {
  group('PFA Model Tests', () {
    test('PFA should be created with required fields', () {
      final pfa = PFA(
        cui: 'RO12345678',
        name: 'Ion Popescu',
        address: 'Strada Test 123, București',
        registrationDate: DateTime(2024, 1, 1),
        isRealSystem: true,
        activityType: 'Software Development',
      );

      expect(pfa.cui, 'RO12345678');
      expect(pfa.name, 'Ion Popescu');
      expect(pfa.isRealSystem, true);
    });

    test('PFA should accept optional phone and email', () {
      final pfa = PFA(
        cui: 'RO12345678',
        name: 'Ion Popescu',
        address: 'Strada Test 123',
        phone: '+40712345678',
        email: 'ion@example.com',
        registrationDate: DateTime(2024, 1, 1),
        isRealSystem: true,
        activityType: 'Consulting',
      );

      expect(pfa.phone, '+40712345678');
      expect(pfa.email, 'ion@example.com');
    });

    test('PFA should enforce maximum 5 CAEN codes limit', () {
      final tooManyCAEN = List.generate(
        6,
        (i) => CAENCode(
          code: '620$i',
          description: 'Activity $i',
        ),
      );

      expect(
        () => PFA(
          cui: 'RO12345678',
          name: 'Test',
          address: 'Test Address',
          registrationDate: DateTime(2024, 1, 1),
          isRealSystem: true,
          activityType: 'IT',
          caenCodes: tooManyCAEN,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('PFA should accept up to 5 CAEN codes', () {
      final validCAEN = List.generate(
        5,
        (i) => CAENCode(
          code: '620$i',
          description: 'Activity $i',
        ),
      );

      final pfa = PFA(
        cui: 'RO12345678',
        name: 'Test',
        address: 'Test Address',
        registrationDate: DateTime(2024, 1, 1),
        isRealSystem: true,
        activityType: 'IT',
        caenCodes: validCAEN,
      );

      expect(pfa.caenCodes?.length, 5);
      expect(pfa.caenCodeCount, 5);
    });

    test('PFA should identify primary CAEN code', () {
      final caenCodes = [
        CAENCode(
          code: '6201',
          description: 'Software Development',
          isPrimary: false,
        ),
        CAENCode(
          code: '6202',
          description: 'IT Consulting',
          isPrimary: true,
        ),
      ];

      final pfa = PFA(
        cui: 'RO12345678',
        name: 'Test',
        address: 'Test Address',
        registrationDate: DateTime(2024, 1, 1),
        isRealSystem: true,
        activityType: 'IT',
        caenCodes: caenCodes,
      );

      expect(pfa.primaryCAENCode?.code, '6202');
      expect(pfa.primaryCAENCode?.isPrimary, true);
    });

    test('PFA should detect special tax rates in CAEN codes', () {
      final caenCodes = [
        CAENCode(
          code: '6201',
          description: 'Software Development',
          hasSpecialTaxRate: true,
          specialTaxRate: 0.03,
        ),
      ];

      final pfa = PFA(
        cui: 'RO12345678',
        name: 'Test',
        address: 'Test Address',
        registrationDate: DateTime(2024, 1, 1),
        isRealSystem: true,
        activityType: 'IT',
        caenCodes: caenCodes,
      );

      expect(pfa.hasSpecialTaxRate, true);
    });

    test('PFA.canAddMoreCAENCodes should return correct value', () {
      final pfa1 = PFA(
        cui: 'RO12345678',
        name: 'Test',
        address: 'Test Address',
        registrationDate: DateTime(2024, 1, 1),
        isRealSystem: true,
        activityType: 'IT',
      );

      expect(pfa1.canAddMoreCAENCodes, true);

      final pfa2 = PFA(
        cui: 'RO12345678',
        name: 'Test',
        address: 'Test Address',
        registrationDate: DateTime(2024, 1, 1),
        isRealSystem: true,
        activityType: 'IT',
        caenCodes: List.generate(
          5,
          (i) => CAENCode(code: '620$i', description: 'Activity $i'),
        ),
      );

      expect(pfa2.canAddMoreCAENCodes, false);
    });

    test('PFA.copyWith should create new instance with updated fields', () {
      final original = PFA(
        cui: 'RO12345678',
        name: 'Original Name',
        address: 'Original Address',
        registrationDate: DateTime(2024, 1, 1),
        isRealSystem: true,
        activityType: 'IT',
      );

      final updated = original.copyWith(
        name: 'Updated Name',
        phone: '+40712345678',
      );

      expect(updated.name, 'Updated Name');
      expect(updated.phone, '+40712345678');
      expect(updated.cui, 'RO12345678'); // Unchanged
      expect(updated.address, 'Original Address'); // Unchanged
    });
  });
}
