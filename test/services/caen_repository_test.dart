import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pfa_helper/models/caen_code.dart';
import 'package:pfa_helper/services/caen_repository.dart';
import 'dart:convert';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Initialize Hive for testing
    Hive.init('./test/hive_test');
  });

  tearDownAll(() async {
    // Clean up Hive
    await Hive.deleteFromDisk();
  });

  group('CAEN Repository Tests', () {
    late CAENRepository repository;
    late http.Client mockClient;

    // Sample CAEN data for testing
    final sampleCAENData = {
      'descriere': 'Coduri CAEN rev. 2',
      'sursa': 'http://data.gov.ro/dataset/caen-clase-rev2',
      'coduri': [
        {'cod': 6201, 'descriere': 'Activități de realizare a soft-ului la comandă'},
        {'cod': 6202, 'descriere': 'Activități de consultanță în tehnologia informației'},
        {'cod': 6209, 'descriere': 'Alte activități de servicii privind tehnologia informației'},
        {'cod': 7022, 'descriere': 'Activități de consultanță pentru afaceri și management'},
        {'cod': 111, 'descriere': 'Cultivarea cerealelor'},
        {'cod': 112, 'descriere': 'Cultivarea orezului'},
        {'cod': 620, 'descriere': 'Activități de programare software'},
      ]
    };

    setUp(() async {
      // Create mock HTTP client
      mockClient = MockClient((request) async {
        if (request.url.toString().contains('caen.json')) {
          return http.Response(json.encode(sampleCAENData), 200);
        }
        return http.Response('Not Found', 404);
      });

      repository = CAENRepository(client: mockClient);
      await repository.initialize();
    });

    tearDown(() async {
      await repository.clearCache();
      repository.dispose();
    });

    test('Should initialize repository successfully', () async {
      final repo = CAENRepository(client: mockClient);
      await repo.initialize();
      expect(repo, isNotNull);
      repo.dispose();
    });

    test('Should fetch CAEN codes from remote', () async {
      final codes = await repository.getAllCodes();

      expect(codes, isNotEmpty);
      expect(codes.length, 7);
      expect(codes.any((c) => c.code == '6201'), true);
      expect(codes.any((c) => c.code == '7022'), true);
    });

    test('Should identify IT codes with special tax rate', () async {
      final codes = await repository.getAllCodes();

      final itCode = codes.firstWhere((c) => c.code == '6201');
      expect(itCode.hasSpecialTaxRate, true);
      expect(itCode.specialTaxRate, 0.03);

      final nonItCode = codes.firstWhere((c) => c.code == '7022');
      expect(nonItCode.hasSpecialTaxRate, false);
      expect(nonItCode.specialTaxRate, null);
    });

    test('Should cache CAEN codes locally', () async {
      // First fetch - should hit remote
      final codes1 = await repository.getAllCodes();
      expect(codes1, isNotEmpty);

      // Second fetch - should use cache
      final codes2 = await repository.getAllCodes();
      expect(codes2.length, codes1.length);
    });

    test('Should force refresh when requested', () async {
      // First fetch
      await repository.getAllCodes();

      // Second fetch with force refresh
      final codes = await repository.getAllCodes(forceRefresh: true);
      expect(codes, isNotEmpty);
    });

    test('Should search CAEN codes by keyword', () async {
      await repository.getAllCodes();

      final results = await repository.search('software');
      expect(results, isNotEmpty);
      expect(results.every((c) =>
        c.description.toLowerCase().contains('soft') ||
        c.code.contains('software')), true);
    });

    test('Should search CAEN codes by code number', () async {
      await repository.getAllCodes();

      final results = await repository.search('6201');
      expect(results, isNotEmpty);
      expect(results.any((c) => c.code == '6201'), true);
    });

    test('Should return all codes when search query is empty', () async {
      await repository.getAllCodes();

      final results = await repository.search('');
      expect(results.length, 7);
    });

    test('Should get codes by division (2-digit)', () async {
      await repository.getAllCodes();

      final division62 = await repository.getDivision('62');
      expect(division62, isNotEmpty);
      expect(division62.every((c) => c.code.padLeft(2, '0').startsWith('62')), true);
    });

    test('Should get codes by group (3-digit)', () async {
      await repository.getAllCodes();

      final group620 = await repository.getGroup('620');
      expect(group620, isNotEmpty);
      expect(group620.every((c) => c.code.padLeft(3, '0').startsWith('620')), true);
    });

    test('Should get only special rate codes', () async {
      await repository.getAllCodes();

      final specialCodes = await repository.getSpecialRateCodes();
      expect(specialCodes, isNotEmpty);
      expect(specialCodes.every((c) => c.hasSpecialTaxRate), true);
      expect(specialCodes.any((c) => c.code == '6201'), true);
      expect(specialCodes.any((c) => c.code == '7022'), false);
    });

    test('Should get code by exact match', () async {
      await repository.getAllCodes();

      final code = await repository.getByCode('6201');
      expect(code, isNotNull);
      expect(code!.code, '6201');
      expect(code.description, 'Activități de realizare a soft-ului la comandă');
    });

    test('Should return null for non-existent code', () async {
      await repository.getAllCodes();

      final code = await repository.getByCode('9999');
      expect(code, isNull);
    });

    test('Should get unique divisions', () async {
      await repository.getAllCodes();

      final divisions = await repository.getDivisions();
      expect(divisions, isNotEmpty);
      expect(divisions.containsKey('62'), true);
      expect(divisions.containsKey('70'), true);
      expect(divisions.containsKey('11'), true);
    });

    test('Should get unique groups', () async {
      await repository.getAllCodes();

      final groups = await repository.getGroups();
      expect(groups, isNotEmpty);
      expect(groups.containsKey('620'), true);
      expect(groups.containsKey('702'), true);
      expect(groups.containsKey('111'), true);
    });

    test('Should track last update time', () async {
      await repository.getAllCodes();

      final lastUpdate = repository.getLastUpdate();
      expect(lastUpdate, isNotNull);
      expect(lastUpdate!.isBefore(DateTime.now()), true);
    });

    test('Should detect when cache needs refresh', () async {
      // New repository with no cache should need refresh
      final newRepo = CAENRepository(client: mockClient);
      await newRepo.initialize();
      expect(newRepo.shouldRefreshCache(), true);
      newRepo.dispose();

      // Repository with fresh cache should not need refresh
      await repository.getAllCodes();
      expect(repository.shouldRefreshCache(), false);
    });

    test('Should clear cache successfully', () async {
      await repository.getAllCodes();
      expect(repository.getLastUpdate(), isNotNull);

      await repository.clearCache();
      expect(repository.getLastUpdate(), isNull);
    });

    test('Should handle network errors gracefully', () async {
      // Create client that always fails
      final failingClient = MockClient((request) async {
        throw Exception('Network error');
      });

      final failingRepo = CAENRepository(client: failingClient);
      await failingRepo.initialize();

      // Should fall back to common codes
      final codes = await failingRepo.getAllCodes();
      expect(codes, isNotEmpty);
      expect(codes, CAENCode.getCommonCAENCodes());

      failingRepo.dispose();
    });

    test('Should handle HTTP errors gracefully', () async {
      final errorClient = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      final errorRepo = CAENRepository(client: errorClient);
      await errorRepo.initialize();

      // Should fall back to common codes
      final codes = await errorRepo.getAllCodes();
      expect(codes, isNotEmpty);
      expect(codes, CAENCode.getCommonCAENCodes());

      errorRepo.dispose();
    });

    test('Should normalize division codes correctly', () async {
      await repository.getAllCodes();

      // Test with single digit
      final division1 = await repository.getDivision('1');
      expect(division1, isNotEmpty);

      // Test with two digits
      final division62 = await repository.getDivision('62');
      expect(division62, isNotEmpty);
    });

    test('Should normalize group codes correctly', () async {
      await repository.getAllCodes();

      // Test with 2 digits
      final group11 = await repository.getGroup('11');
      expect(group11, isNotEmpty);

      // Test with 3 digits
      final group620 = await repository.getGroup('620');
      expect(group620, isNotEmpty);
    });

    test('Should perform case-insensitive search', () async {
      await repository.getAllCodes();

      final upperResults = await repository.search('SOFTWARE');
      final lowerResults = await repository.search('software');
      final mixedResults = await repository.search('SoftWare');

      expect(upperResults.length, lowerResults.length);
      expect(lowerResults.length, mixedResults.length);
    });

    test('Should handle Romanian diacritics in search', () async {
      await repository.getAllCodes();

      // Search for Romanian text with diacritics
      final results = await repository.search('consultanță');
      expect(results, isNotEmpty);
    });
  });
}
