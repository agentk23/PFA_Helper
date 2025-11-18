import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import '../models/caen_code.dart';

/// Repository for managing CAEN (Clasificarea Activităților Economice Naționale) codes
///
/// Provides functionality to:
/// - Load CAEN codes from remote source or local cache
/// - Search and filter CAEN codes
/// - Organize codes hierarchically (Section -> Division -> Group -> Class)
/// - Cache codes locally for offline access
///
/// CAEN Code Structure:
/// - 2 digits: Division (e.g., "62" - Computer programming)
/// - 3 digits: Group (e.g., "620" - Computer programming activities)
/// - 4 digits: Class (e.g., "6201" - Custom software development)
class CAENRepository {
  static const String _cacheBoxName = 'caen_codes';
  static const String _cacheKey = 'all_caen_codes';
  static const String _lastUpdateKey = 'last_update';

  // GitHub repository with CAEN Rev.2 data
  static const String _remoteDataUrl =
      'https://raw.githubusercontent.com/danburzo/corpora/master/data/caen.json';

  final http.Client _client;
  Box<dynamic>? _cacheBox;
  List<CAENCode>? _cachedCodes;

  CAENRepository({http.Client? client}) : _client = client ?? http.Client();

  /// Initialize the repository and load cached data
  Future<void> initialize() async {
    try {
      _cacheBox = await Hive.openBox(_cacheBoxName);
      developer.log('CAEN Repository initialized', name: 'CAENRepository');
    } catch (e, stackTrace) {
      developer.log(
        'Failed to initialize CAEN Repository',
        name: 'CAENRepository',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get all CAEN codes (from cache or remote)
  ///
  /// Parameters:
  /// - [forceRefresh]: Force fetch from remote even if cache exists
  Future<List<CAENCode>> getAllCodes({bool forceRefresh = false}) async {
    // Return cached codes if available and not forcing refresh
    if (_cachedCodes != null && !forceRefresh) {
      return _cachedCodes!;
    }

    // Try to load from local cache first
    if (!forceRefresh) {
      final cachedCodes = await _loadFromCache();
      if (cachedCodes != null && cachedCodes.isNotEmpty) {
        _cachedCodes = cachedCodes;
        developer.log(
          'Loaded ${cachedCodes.length} CAEN codes from cache',
          name: 'CAENRepository',
        );
        return cachedCodes;
      }
    }

    // Fetch from remote if cache is empty or refresh is forced
    try {
      final codes = await _fetchFromRemote();
      await _saveToCache(codes);
      _cachedCodes = codes;
      developer.log(
        'Fetched ${codes.length} CAEN codes from remote',
        name: 'CAENRepository',
      );
      return codes;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to fetch CAEN codes from remote',
        name: 'CAENRepository',
        error: e,
        stackTrace: stackTrace,
      );

      // Fall back to embedded common codes if all else fails
      return CAENCode.getCommonCAENCodes();
    }
  }

  /// Fetch CAEN codes from remote source
  Future<List<CAENCode>> _fetchFromRemote() async {
    final response = await _client.get(Uri.parse(_remoteDataUrl));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch CAEN codes: ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final coduri = data['coduri'] as List<dynamic>;

    return coduri.map((item) {
      final codeData = item as Map<String, dynamic>;
      final code = codeData['cod'].toString();
      final description = codeData['descriere'] as String;

      return CAENCode(
        code: code,
        description: description,
        hasSpecialTaxRate: CAENCode.hasSpecialRate(code),
        specialTaxRate: CAENCode.hasSpecialRate(code) ? 0.03 : null,
      );
    }).toList();
  }

  /// Load CAEN codes from local cache
  Future<List<CAENCode>?> _loadFromCache() async {
    if (_cacheBox == null) {
      await initialize();
    }

    final cachedData = _cacheBox?.get(_cacheKey) as List<dynamic>?;
    if (cachedData == null) {
      return null;
    }

    return cachedData.map((item) {
      final data = item as Map<dynamic, dynamic>;
      return CAENCode(
        code: data['code'] as String,
        description: data['description'] as String,
        hasSpecialTaxRate: data['hasSpecialTaxRate'] as bool? ?? false,
        specialTaxRate: (data['specialTaxRate'] as num?)?.toDouble(),
      );
    }).toList();
  }

  /// Save CAEN codes to local cache
  Future<void> _saveToCache(List<CAENCode> codes) async {
    if (_cacheBox == null) {
      await initialize();
    }

    final cacheData = codes.map((code) => {
      'code': code.code,
      'description': code.description,
      'hasSpecialTaxRate': code.hasSpecialTaxRate,
      'specialTaxRate': code.specialTaxRate,
    }).toList();

    await _cacheBox?.put(_cacheKey, cacheData);
    await _cacheBox?.put(_lastUpdateKey, DateTime.now().toIso8601String());
  }

  /// Search CAEN codes by keyword
  ///
  /// Searches in both code and description fields.
  /// Case-insensitive search.
  Future<List<CAENCode>> search(String query) async {
    final allCodes = await getAllCodes();
    if (query.isEmpty) {
      return allCodes;
    }

    final lowerQuery = query.toLowerCase();
    return allCodes.where((code) {
      return code.code.toLowerCase().contains(lowerQuery) ||
          code.description.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Get CAEN codes by division (2-digit code)
  ///
  /// Example: getDivision("62") returns all codes starting with "62"
  Future<List<CAENCode>> getDivision(String divisionCode) async {
    final allCodes = await getAllCodes();
    final normalizedDivision = divisionCode.padLeft(2, '0').substring(0, 2);

    return allCodes.where((code) {
      final normalizedCode = code.code.padLeft(2, '0');
      return normalizedCode.startsWith(normalizedDivision);
    }).toList();
  }

  /// Get CAEN codes by group (3-digit code)
  ///
  /// Example: getGroup("620") returns all codes starting with "620"
  Future<List<CAENCode>> getGroup(String groupCode) async {
    final allCodes = await getAllCodes();
    final normalizedGroup = groupCode.padLeft(3, '0').substring(0, 3);

    return allCodes.where((code) {
      final normalizedCode = code.code.padLeft(3, '0');
      return normalizedCode.startsWith(normalizedGroup);
    }).toList();
  }

  /// Get CAEN codes with special tax rates (3% for IT)
  Future<List<CAENCode>> getSpecialRateCodes() async {
    final allCodes = await getAllCodes();
    return allCodes.where((code) => code.hasSpecialTaxRate).toList();
  }

  /// Get CAEN code by exact code match
  Future<CAENCode?> getByCode(String code) async {
    final allCodes = await getAllCodes();
    try {
      return allCodes.firstWhere((c) => c.code == code);
    } catch (e) {
      return null;
    }
  }

  /// Get divisions (unique 2-digit prefixes)
  ///
  /// Returns a map of division code -> description
  Future<Map<String, String>> getDivisions() async {
    final allCodes = await getAllCodes();
    final divisions = <String, String>{};

    for (final code in allCodes) {
      final normalizedCode = code.code.padLeft(2, '0');
      if (normalizedCode.length >= 2) {
        final divisionCode = normalizedCode.substring(0, 2);
        // Keep the shortest description (usually division-level description)
        if (!divisions.containsKey(divisionCode) ||
            divisions[divisionCode]!.length > code.description.length) {
          divisions[divisionCode] = code.description;
        }
      }
    }

    return divisions;
  }

  /// Get groups (unique 3-digit prefixes)
  ///
  /// Returns a map of group code -> description
  Future<Map<String, String>> getGroups() async {
    final allCodes = await getAllCodes();
    final groups = <String, String>{};

    for (final code in allCodes) {
      final normalizedCode = code.code.padLeft(3, '0');
      if (normalizedCode.length >= 3) {
        final groupCode = normalizedCode.substring(0, 3);
        // Keep the shortest description (usually group-level description)
        if (!groups.containsKey(groupCode) ||
            groups[groupCode]!.length > code.description.length) {
          groups[groupCode] = code.description;
        }
      }
    }

    return groups;
  }

  /// Get last update timestamp
  DateTime? getLastUpdate() {
    final lastUpdate = _cacheBox?.get(_lastUpdateKey) as String?;
    if (lastUpdate == null) {
      return null;
    }
    return DateTime.tryParse(lastUpdate);
  }

  /// Check if cache needs refresh (older than 30 days)
  bool shouldRefreshCache() {
    final lastUpdate = getLastUpdate();
    if (lastUpdate == null) {
      return true;
    }
    return DateTime.now().difference(lastUpdate).inDays > 30;
  }

  /// Clear local cache
  Future<void> clearCache() async {
    await _cacheBox?.delete(_cacheKey);
    await _cacheBox?.delete(_lastUpdateKey);
    _cachedCodes = null;
    developer.log('CAEN cache cleared', name: 'CAENRepository');
  }

  /// Dispose resources
  void dispose() {
    _client.close();
  }
}
