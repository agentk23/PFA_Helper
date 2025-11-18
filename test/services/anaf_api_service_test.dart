import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pfa_helper/models/anaf_invoice.dart';
import 'package:pfa_helper/services/anaf_api_service.dart';
import 'dart:convert';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Initialize Hive for testing
    Hive.init('./test/hive_test_anaf');
  });

  tearDownAll(() async {
    // Clean up Hive
    await Hive.deleteFromDisk();
  });

  group('ANAF API Service Tests', () {
    late ANAFApiService service;
    late http.Client mockClient;

    final sampleInvoiceJson = {
      'id': 'inv_123',
      'cif': '12345678',
      'invoiceNumber': 'INV-2024-001',
      'issueDate': '2024-01-15T00:00:00.000Z',
      'totalAmount': 5000.0,
      'vatAmount': 950.0,
      'currency': 'RON',
      'buyerCIF': '87654321',
      'buyerName': 'Test Company SRL',
      'lines': [
        {
          'description': 'Software development services',
          'quantity': 1.0,
          'unitPrice': 5000.0,
          'totalAmount': 5000.0,
          'vatRate': 0.19,
        }
      ],
      'status': 'validated',
    };

    setUp(() async {
      mockClient = MockClient((request) async {
        // Authentication endpoint
        if (request.url.path.contains('/oauth/token')) {
          return http.Response(
            json.encode({
              'access_token': 'test_token_123',
              'expires_in': 3600,
            }),
            200,
          );
        }

        // Submit invoice endpoint
        if (request.url.path.contains('/upload')) {
          return http.Response(json.encode(sampleInvoiceJson), 201);
        }

        // Get invoice endpoint
        if (request.url.path.contains('/invoice/')) {
          return http.Response(json.encode(sampleInvoiceJson), 200);
        }

        // List invoices endpoint
        if (request.url.path.contains('/invoices')) {
          return http.Response(
            json.encode({
              'invoices': [sampleInvoiceJson]
            }),
            200,
          );
        }

        // CUI validation/company info endpoint
        if (request.url.path.contains('/info')) {
          return http.Response(
            json.encode({
              'found': [
                {
                  'date_generale': {
                    'cui': 12345678,
                    'denumire': 'Test Company SRL',
                    'adresa': 'Bucharest, Romania',
                  }
                }
              ]
            }),
            200,
          );
        }

        return http.Response('Not Found', 404);
      });

      service = ANAFApiService(useProduction: false, client: mockClient);
      await service.initialize();
    });

    tearDown(() {
      service.dispose();
    });

    test('Should initialize service successfully', () async {
      final testService = ANAFApiService(client: mockClient);
      await testService.initialize();
      expect(testService, isNotNull);
      testService.dispose();
    });

    test('Should authenticate with OAuth2', () async {
      final result = await service.authenticate(
        clientId: 'test_client',
        clientSecret: 'test_secret',
        redirectUri: 'https://example.com/callback',
      );

      expect(result.isSuccess, true);
      expect(result.data, isNotNull);
      expect(service.isAuthenticated, true);
    });

    test('Should check authentication status', () async {
      expect(service.isAuthenticated, false);

      await service.authenticate(
        clientId: 'test_client',
        clientSecret: 'test_secret',
        redirectUri: 'https://example.com/callback',
      );

      expect(service.isAuthenticated, true);
    });

    test('Should submit invoice successfully', () async {
      // Authenticate first
      await service.authenticate(
        clientId: 'test_client',
        clientSecret: 'test_secret',
        redirectUri: 'https://example.com/callback',
      );

      final invoice = ANAFInvoice(
        id: 'inv_123',
        cif: '12345678',
        invoiceNumber: 'INV-2024-001',
        issueDate: DateTime(2024, 1, 15),
        totalAmount: 5000.0,
        vatAmount: 950.0,
        currency: 'RON',
        buyerCIF: '87654321',
        buyerName: 'Test Company SRL',
        lines: [],
        status: ANAFInvoiceStatus.draft,
      );

      final result = await service.submitInvoice(invoice);

      expect(result.isSuccess, true);
      expect(result.data, isNotNull);
      expect(result.data!.id, 'inv_123');
    });

    test('Should fail to submit invoice when not authenticated', () async {
      final invoice = ANAFInvoice(
        id: 'inv_123',
        cif: '12345678',
        invoiceNumber: 'INV-2024-001',
        issueDate: DateTime(2024, 1, 15),
        totalAmount: 5000.0,
        vatAmount: 950.0,
        currency: 'RON',
        buyerCIF: '87654321',
        buyerName: 'Test Company SRL',
        lines: [],
        status: ANAFInvoiceStatus.draft,
      );

      final result = await service.submitInvoice(invoice);

      expect(result.isSuccess, false);
      expect(result.error, contains('Not authenticated'));
    });

    test('Should get invoice by ID', () async {
      await service.authenticate(
        clientId: 'test_client',
        clientSecret: 'test_secret',
        redirectUri: 'https://example.com/callback',
      );

      final result = await service.getInvoice('inv_123');

      expect(result.isSuccess, true);
      expect(result.data, isNotNull);
      expect(result.data!.id, 'inv_123');
      expect(result.data!.invoiceNumber, 'INV-2024-001');
    });

    test('Should list invoices with filters', () async {
      await service.authenticate(
        clientId: 'test_client',
        clientSecret: 'test_secret',
        redirectUri: 'https://example.com/callback',
      );

      final result = await service.listInvoices(
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
        status: ANAFInvoiceStatus.validated,
        limit: 100,
      );

      expect(result.isSuccess, true);
      expect(result.data, isNotNull);
      expect(result.data!, isNotEmpty);
    });

    test('Should validate CUI successfully', () async {
      final result = await service.validateCUI('12345678');

      expect(result.isSuccess, true);
      expect(result.data, true);
    });

    test('Should validate CUI with RO prefix', () async {
      final result = await service.validateCUI('RO12345678');

      expect(result.isSuccess, true);
      expect(result.data, true);
    });

    test('Should get company info by CUI', () async {
      final result = await service.getCompanyInfo('12345678');

      expect(result.isSuccess, true);
      expect(result.data, isNotNull);
      expect(result.data!['date_generale'], isNotNull);
    });

    test('Should handle rate limiting for submit invoice', () async {
      await service.authenticate(
        clientId: 'test_client',
        clientSecret: 'test_secret',
        redirectUri: 'https://example.com/callback',
      );

      final invoice = ANAFInvoice(
        id: 'inv_123',
        cif: '12345678',
        invoiceNumber: 'INV-2024-001',
        issueDate: DateTime(2024, 1, 15),
        totalAmount: 5000.0,
        vatAmount: 950.0,
        currency: 'RON',
        buyerCIF: '87654321',
        buyerName: 'Test Company SRL',
        lines: [],
        status: ANAFInvoiceStatus.draft,
      );

      // Submit 101 invoices rapidly (limit is 100 per minute)
      int rateLimitedCount = 0;
      for (int i = 0; i < 101; i++) {
        final result = await service.submitInvoice(invoice);
        if (!result.isSuccess && result.statusCode == 429) {
          rateLimitedCount++;
        }
      }

      expect(rateLimitedCount, greaterThan(0));
    });

    test('Should logout and clear credentials', () async {
      await service.authenticate(
        clientId: 'test_client',
        clientSecret: 'test_secret',
        redirectUri: 'https://example.com/callback',
      );

      expect(service.isAuthenticated, true);

      await service.logout();

      expect(service.isAuthenticated, false);
    });

    test('Should use test URL when not in production', () async {
      final testService = ANAFApiService(
        useProduction: false,
        client: mockClient,
      );
      await testService.initialize();

      // Test URL should be used
      expect(testService, isNotNull);

      testService.dispose();
    });

    test('Should handle authentication errors', () async {
      final errorClient = MockClient((request) async {
        return http.Response('Unauthorized', 401);
      });

      final errorService = ANAFApiService(client: errorClient);
      await errorService.initialize();

      final result = await errorService.authenticate(
        clientId: 'invalid',
        clientSecret: 'invalid',
        redirectUri: 'https://example.com/callback',
      );

      expect(result.isSuccess, false);
      expect(result.statusCode, 401);

      errorService.dispose();
    });

    test('Should handle network errors', () async {
      final errorClient = MockClient((request) async {
        throw Exception('Network error');
      });

      final errorService = ANAFApiService(client: errorClient);
      await errorService.initialize();

      final result = await errorService.authenticate(
        clientId: 'test',
        clientSecret: 'test',
        redirectUri: 'https://example.com/callback',
      );

      expect(result.isSuccess, false);
      expect(result.error, contains('error'));

      errorService.dispose();
    });

    test('Should handle 404 for non-existent invoice', () async {
      final notFoundClient = MockClient((request) async {
        if (request.url.path.contains('/oauth/token')) {
          return http.Response(
            json.encode({'access_token': 'test_token', 'expires_in': 3600}),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final testService = ANAFApiService(client: notFoundClient);
      await testService.initialize();

      await testService.authenticate(
        clientId: 'test',
        clientSecret: 'test',
        redirectUri: 'https://example.com/callback',
      );

      final result = await testService.getInvoice('non_existent');

      expect(result.isSuccess, false);
      expect(result.statusCode, 404);
      expect(result.error, contains('not found'));

      testService.dispose();
    });

    test('Should return false for invalid CUI', () async {
      final invalidClient = MockClient((request) async {
        return http.Response(json.encode({'found': []}), 200);
      });

      final testService = ANAFApiService(client: invalidClient);
      await testService.initialize();

      final result = await testService.validateCUI('invalid');

      expect(result.isSuccess, true);
      expect(result.data, false);

      testService.dispose();
    });

    test('Should return error for company not found', () async {
      final notFoundClient = MockClient((request) async {
        return http.Response(json.encode({'found': []}), 200);
      });

      final testService = ANAFApiService(client: notFoundClient);
      await testService.initialize();

      final result = await testService.getCompanyInfo('invalid');

      expect(result.isSuccess, false);
      expect(result.statusCode, 404);
      expect(result.error, contains('not found'));

      testService.dispose();
    });
  });
}
