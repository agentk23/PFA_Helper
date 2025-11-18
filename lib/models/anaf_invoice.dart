/// ANAF eFactura Invoice Model
/// Represents an electronic invoice for Romanian tax administration
class ANAFInvoice {
  final String id;
  final String cif; // CUI/CIF of the issuer
  final String invoiceNumber;
  final DateTime issueDate;
  final double totalAmount;
  final double vatAmount;
  final String currency;
  final String buyerCIF;
  final String buyerName;
  final List<ANAFInvoiceLine> lines;
  final ANAFInvoiceStatus status;

  ANAFInvoice({
    required this.id,
    required this.cif,
    required this.invoiceNumber,
    required this.issueDate,
    required this.totalAmount,
    required this.vatAmount,
    required this.currency,
    required this.buyerCIF,
    required this.buyerName,
    required this.lines,
    this.status = ANAFInvoiceStatus.draft,
  });

  /// Create invoice from JSON response
  factory ANAFInvoice.fromJson(Map<String, dynamic> json) {
    return ANAFInvoice(
      id: json['id'] as String,
      cif: json['cif'] as String,
      invoiceNumber: json['invoiceNumber'] as String,
      issueDate: DateTime.parse(json['issueDate'] as String),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      vatAmount: (json['vatAmount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'RON',
      buyerCIF: json['buyerCIF'] as String,
      buyerName: json['buyerName'] as String,
      lines: (json['lines'] as List<dynamic>?)
              ?.map((e) => ANAFInvoiceLine.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      status: ANAFInvoiceStatus.fromString(
        json['status'] as String? ?? 'draft',
      ),
    );
  }

  /// Convert invoice to JSON for API submission
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cif': cif,
      'invoiceNumber': invoiceNumber,
      'issueDate': issueDate.toIso8601String(),
      'totalAmount': totalAmount,
      'vatAmount': vatAmount,
      'currency': currency,
      'buyerCIF': buyerCIF,
      'buyerName': buyerName,
      'lines': lines.map((line) => line.toJson()).toList(),
      'status': status.toString(),
    };
  }
}

/// Invoice line item
class ANAFInvoiceLine {
  final String description;
  final double quantity;
  final double unitPrice;
  final double vatRate;
  final double totalAmount;

  ANAFInvoiceLine({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.vatRate,
    required this.totalAmount,
  });

  factory ANAFInvoiceLine.fromJson(Map<String, dynamic> json) {
    return ANAFInvoiceLine(
      description: json['description'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
      vatRate: (json['vatRate'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'vatRate': vatRate,
      'totalAmount': totalAmount,
    };
  }
}

/// Invoice status in ANAF system
enum ANAFInvoiceStatus {
  draft,
  sent,
  validated,
  rejected,
  cancelled;

  static ANAFInvoiceStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'sent':
        return ANAFInvoiceStatus.sent;
      case 'validated':
        return ANAFInvoiceStatus.validated;
      case 'rejected':
        return ANAFInvoiceStatus.rejected;
      case 'cancelled':
        return ANAFInvoiceStatus.cancelled;
      default:
        return ANAFInvoiceStatus.draft;
    }
  }

  @override
  String toString() {
    return name;
  }
}

/// ANAF API Response
class ANAFResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final String? message;
  final int? statusCode;

  ANAFResponse({
    required this.success,
    this.data,
    this.error,
    this.message,
    this.statusCode,
  });

  factory ANAFResponse.success(T data, {String? message}) {
    return ANAFResponse(
      success: true,
      data: data,
      message: message,
      statusCode: 200,
    );
  }

  factory ANAFResponse.error(String error, {int? statusCode}) {
    return ANAFResponse(
      success: false,
      error: error,
      statusCode: statusCode,
    );
  }
}

/// Rate limit information
class RateLimitInfo {
  final int limit;
  final int remaining;
  final DateTime resetTime;

  RateLimitInfo({
    required this.limit,
    required this.remaining,
    required this.resetTime,
  });

  bool get hasExceeded => remaining <= 0;

  Duration get timeUntilReset => resetTime.difference(DateTime.now());
}
