import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/anaf_invoice.dart';

/// ANAF eFactura API Service
/// Implements integration with Romanian tax administration electronic invoicing
///
/// API Documentation: https://mfinante.gov.ro/ro/web/efactura
/// Rate Limits: Per endpoint limits apply (see _RateLimiter)
class ANAFApiService {
  // Production API base URL
  static const String _baseUrl = 'https://api.anaf.ro/prod/FCTEL/rest';

  // Test/Sandbox API base URL
  static const String _testUrl = 'https://api.anaf.ro/test/FCTEL/rest';

  final bool _useProduction;
  final http.Client _client;
  final _RateLimiter _rateLimiter;

  String? _accessToken;
  DateTime? _tokenExpiry;

  ANAFApiService({
    bool useProduction = false,
    http.Client? client,
  })  : _useProduction = useProduction,
        _client = client ?? http.Client(),
        _rateLimiter = _RateLimiter();

  String get _apiBaseUrl => _useProduction ? _baseUrl : _testUrl;

  /// Initialize service and load saved credentials
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString('anaf_access_token');
      final expiryString = prefs.getString('anaf_token_expiry');
      if (expiryString != null) {
        _tokenExpiry = DateTime.parse(expiryString);
      }

      developer.log('ANAF API Service initialized', name: 'ANAFApiService');
    } catch (e, stackTrace) {
      developer.log(
        'Failed to initialize ANAF API Service',
        name: 'ANAFApiService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Authenticate with ANAF using OAuth2
  ///
  /// Parameters:
  /// - [clientId]: OAuth2 client ID from ANAF
  /// - [clientSecret]: OAuth2 client secret
  /// - [redirectUri]: Registered redirect URI
  Future<ANAFResponse<String>> authenticate({
    required String clientId,
    required String clientSecret,
    required String redirectUri,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$_apiBaseUrl/oauth/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'client_credentials',
          'client_id': clientId,
          'client_secret': clientSecret,
          'redirect_uri': redirectUri,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        _accessToken = data['access_token'] as String;

        final expiresIn = data['expires_in'] as int? ?? 3600;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));

        // Save credentials
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('anaf_access_token', _accessToken!);
        await prefs.setString('anaf_token_expiry', _tokenExpiry!.toIso8601String());

        developer.log('Successfully authenticated with ANAF', name: 'ANAFApiService');
        return ANAFResponse.success(_accessToken!, message: 'Authenticated successfully');
      } else {
        final error = 'Authentication failed: ${response.statusCode}';
        developer.log(error, name: 'ANAFApiService');
        return ANAFResponse.error(error, statusCode: response.statusCode);
      }
    } catch (e, stackTrace) {
      developer.log(
        'Authentication error',
        name: 'ANAFApiService',
        error: e,
        stackTrace: stackTrace,
      );
      return ANAFResponse.error('Authentication error: $e');
    }
  }

  /// Check if authenticated and token is valid
  bool get isAuthenticated {
    if (_accessToken == null || _tokenExpiry == null) {
      return false;
    }
    return DateTime.now().isBefore(_tokenExpiry!);
  }

  /// Submit invoice to ANAF
  ///
  /// Rate limit: 100 requests per minute
  Future<ANAFResponse<ANAFInvoice>> submitInvoice(ANAFInvoice invoice) async {
    if (!isAuthenticated) {
      return ANAFResponse.error('Not authenticated. Please authenticate first.');
    }

    // Check rate limit
    final canProceed = await _rateLimiter.checkLimit('submit_invoice');
    if (!canProceed) {
      return ANAFResponse.error(
        'Rate limit exceeded. Please wait before making more requests.',
        statusCode: 429,
      );
    }

    try {
      final response = await _client.post(
        Uri.parse('$_apiBaseUrl/upload'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(invoice.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final submittedInvoice = ANAFInvoice.fromJson(data);

        developer.log(
          'Invoice ${invoice.invoiceNumber} submitted successfully',
          name: 'ANAFApiService',
        );
        return ANAFResponse.success(submittedInvoice, message: 'Invoice submitted');
      } else {
        final error = 'Failed to submit invoice: ${response.statusCode}';
        developer.log(error, name: 'ANAFApiService');
        return ANAFResponse.error(error, statusCode: response.statusCode);
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error submitting invoice',
        name: 'ANAFApiService',
        error: e,
        stackTrace: stackTrace,
      );
      return ANAFResponse.error('Error submitting invoice: $e');
    }
  }

  /// Get invoice by ID
  ///
  /// Rate limit: 200 requests per minute
  Future<ANAFResponse<ANAFInvoice>> getInvoice(String invoiceId) async {
    if (!isAuthenticated) {
      return ANAFResponse.error('Not authenticated. Please authenticate first.');
    }

    final canProceed = await _rateLimiter.checkLimit('get_invoice');
    if (!canProceed) {
      return ANAFResponse.error('Rate limit exceeded', statusCode: 429);
    }

    try {
      final response = await _client.get(
        Uri.parse('$_apiBaseUrl/invoice/$invoiceId'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final invoice = ANAFInvoice.fromJson(data);
        return ANAFResponse.success(invoice);
      } else if (response.statusCode == 404) {
        return ANAFResponse.error('Invoice not found', statusCode: 404);
      } else {
        return ANAFResponse.error(
          'Failed to get invoice: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error getting invoice',
        name: 'ANAFApiService',
        error: e,
        stackTrace: stackTrace,
      );
      return ANAFResponse.error('Error getting invoice: $e');
    }
  }

  /// List invoices with optional filters
  ///
  /// Rate limit: 100 requests per minute
  Future<ANAFResponse<List<ANAFInvoice>>> listInvoices({
    DateTime? startDate,
    DateTime? endDate,
    ANAFInvoiceStatus? status,
    int? limit,
  }) async {
    if (!isAuthenticated) {
      return ANAFResponse.error('Not authenticated. Please authenticate first.');
    }

    final canProceed = await _rateLimiter.checkLimit('list_invoices');
    if (!canProceed) {
      return ANAFResponse.error('Rate limit exceeded', statusCode: 429);
    }

    try {
      final queryParams = <String, String>{};
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }
      if (status != null) {
        queryParams['status'] = status.toString();
      }
      if (limit != null) {
        queryParams['limit'] = limit.toString();
      }

      final uri = Uri.parse('$_apiBaseUrl/invoices').replace(queryParameters: queryParams);

      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final invoicesList = (data['invoices'] as List<dynamic>)
            .map((e) => ANAFInvoice.fromJson(e as Map<String, dynamic>))
            .toList();

        return ANAFResponse.success(invoicesList);
      } else {
        return ANAFResponse.error(
          'Failed to list invoices: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error listing invoices',
        name: 'ANAFApiService',
        error: e,
        stackTrace: stackTrace,
      );
      return ANAFResponse.error('Error listing invoices: $e');
    }
  }

  /// Validate CUI/CIF with ANAF
  ///
  /// Rate limit: 500 requests per minute
  Future<ANAFResponse<bool>> validateCUI(String cui) async {
    final canProceed = await _rateLimiter.checkLimit('validate_cui');
    if (!canProceed) {
      return ANAFResponse.error('Rate limit exceeded', statusCode: 429);
    }

    try {
      final response = await _client.post(
        Uri.parse('$_apiBaseUrl/info'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode([
          {'cui': cui.replaceAll('RO', ''), 'data': DateTime.now().toIso8601String().split('T')[0]}
        ]),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final found = data['found'] as List<dynamic>;

        if (found.isNotEmpty) {
          final cuiData = found[0] as Map<String, dynamic>;
          final isValid = cuiData['date_generale']?['cui'] != null;
          return ANAFResponse.success(isValid);
        }
        return ANAFResponse.success(false);
      } else {
        return ANAFResponse.error(
          'CUI validation failed: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error validating CUI',
        name: 'ANAFApiService',
        error: e,
        stackTrace: stackTrace,
      );
      return ANAFResponse.error('Error validating CUI: $e');
    }
  }

  /// Get company information by CUI
  ///
  /// Rate limit: 500 requests per minute
  Future<ANAFResponse<Map<String, dynamic>>> getCompanyInfo(String cui) async {
    final canProceed = await _rateLimiter.checkLimit('company_info');
    if (!canProceed) {
      return ANAFResponse.error('Rate limit exceeded', statusCode: 429);
    }

    try {
      final response = await _client.post(
        Uri.parse('$_apiBaseUrl/info'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode([
          {'cui': cui.replaceAll('RO', ''), 'data': DateTime.now().toIso8601String().split('T')[0]}
        ]),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final found = data['found'] as List<dynamic>;

        if (found.isNotEmpty) {
          return ANAFResponse.success(found[0] as Map<String, dynamic>);
        }
        return ANAFResponse.error('Company not found', statusCode: 404);
      } else {
        return ANAFResponse.error(
          'Failed to get company info: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error getting company info',
        name: 'ANAFApiService',
        error: e,
        stackTrace: stackTrace,
      );
      return ANAFResponse.error('Error getting company info: $e');
    }
  }

  /// Logout and clear credentials
  Future<void> logout() async {
    _accessToken = null;
    _tokenExpiry = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('anaf_access_token');
    await prefs.remove('anaf_token_expiry');

    developer.log('Logged out from ANAF', name: 'ANAFApiService');
  }

  /// Dispose resources
  void dispose() {
    _client.close();
  }
}

/// Rate limiter for ANAF API endpoints
///
/// Based on ANAF rate limits:
/// - Submit invoice: 100 req/min
/// - Get invoice: 200 req/min
/// - List invoices: 100 req/min
/// - Validate CUI: 500 req/min
/// - Company info: 500 req/min
class _RateLimiter {
  final Map<String, List<DateTime>> _requestHistory = {};

  final Map<String, int> _limits = {
    'submit_invoice': 100, // 100 per minute
    'get_invoice': 200, // 200 per minute
    'list_invoices': 100, // 100 per minute
    'validate_cui': 500, // 500 per minute
    'company_info': 500, // 500 per minute
  };

  /// Check if request can proceed without exceeding rate limit
  Future<bool> checkLimit(String endpoint) async {
    final limit = _limits[endpoint] ?? 100;
    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(const Duration(minutes: 1));

    // Initialize if not exists
    _requestHistory[endpoint] ??= [];

    // Clean old requests
    _requestHistory[endpoint]!.removeWhere((time) => time.isBefore(oneMinuteAgo));

    // Check limit
    if (_requestHistory[endpoint]!.length >= limit) {
      developer.log(
        'Rate limit exceeded for $endpoint ($limit req/min)',
        name: 'ANAFApiService.RateLimiter',
      );
      return false;
    }

    // Record this request
    _requestHistory[endpoint]!.add(now);
    return true;
  }

  /// Get remaining requests for endpoint
  int getRemainingRequests(String endpoint) {
    final limit = _limits[endpoint] ?? 100;
    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(const Duration(minutes: 1));

    _requestHistory[endpoint] ??= [];
    _requestHistory[endpoint]!.removeWhere((time) => time.isBefore(oneMinuteAgo));

    return limit - _requestHistory[endpoint]!.length;
  }
}
