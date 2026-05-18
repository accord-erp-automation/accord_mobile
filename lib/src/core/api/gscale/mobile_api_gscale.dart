part of '../mobile_api.dart';

extension MobileApiGScale on MobileApi {
  Future<GScaleMaterialReceiptPrintResponse> gscaleMaterialReceiptPrint(
    GScaleMaterialReceiptPrintRequest request,
  ) async {
    final response = await _sendAuthorized(
      () => http.post(
        Uri.parse(
            '${MobileApi.baseUrl}/v1/mobile/gscale/material-receipt/print'),
        headers: _headers(requireToken())
          ..['Content-Type'] = 'application/json',
        body: jsonEncode(request.toJson()),
      ),
    );
    final payload = _gscaleDecodeObject(response.body);
    if (response.statusCode != 200) {
      throw MobileApiException(
        code: _gscaleText(payload['error'], fallback: 'gscale_print_failed'),
        message: _gscaleText(
          payload['detail'],
          fallback: _gscaleText(
            payload['message'],
            fallback: 'GScale print failed',
          ),
        ),
        statusCode: response.statusCode,
      );
    }
    return GScaleMaterialReceiptPrintResponse.fromJson(payload);
  }
}

class GScaleMaterialReceiptPrintRequest {
  const GScaleMaterialReceiptPrintRequest({
    required this.driverUrl,
    required this.itemCode,
    required this.itemName,
    required this.warehouse,
    required this.printer,
    required this.printMode,
    required this.grossQty,
    this.unit = 'kg',
    this.tareEnabled = false,
    this.tareKg = 0,
  });

  final String driverUrl;
  final String itemCode;
  final String itemName;
  final String warehouse;
  final String printer;
  final String printMode;
  final double grossQty;
  final String unit;
  final bool tareEnabled;
  final double tareKg;

  Map<String, dynamic> toJson() {
    return {
      'driver_url': driverUrl.trim(),
      'item_code': itemCode.trim(),
      'item_name': itemName.trim(),
      'warehouse': warehouse.trim(),
      'printer': printer.trim(),
      'print_mode': printMode.trim(),
      'gross_qty': grossQty,
      'unit': unit.trim().isEmpty ? 'kg' : unit.trim(),
      'tare_enabled': tareEnabled,
      'tare_kg': tareKg,
    };
  }
}

class GScaleMaterialReceiptPrintResponse {
  const GScaleMaterialReceiptPrintResponse({
    required this.ok,
    required this.status,
    required this.draftName,
    required this.epc,
    required this.itemCode,
    required this.itemName,
    required this.warehouse,
    required this.qty,
    required this.netQty,
    required this.grossQty,
    required this.unit,
    required this.printer,
    required this.printMode,
    required this.printerStatus,
  });

  factory GScaleMaterialReceiptPrintResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return GScaleMaterialReceiptPrintResponse(
      ok: json['ok'] == true,
      status: _gscaleText(json['status']),
      draftName: _gscaleText(json['draft_name']),
      epc: _gscaleText(json['epc']),
      itemCode: _gscaleText(json['item_code']),
      itemName: _gscaleText(json['item_name']),
      warehouse: _gscaleText(json['warehouse']),
      qty: _gscaleNumber(json['qty']),
      netQty: _gscaleNumber(json['net_qty']),
      grossQty: _gscaleNumber(json['gross_qty']),
      unit: _gscaleText(json['unit'], fallback: 'kg'),
      printer: _gscaleText(json['printer']),
      printMode: _gscaleText(json['print_mode']),
      printerStatus: _gscaleText(json['printer_status']),
    );
  }

  final bool ok;
  final String status;
  final String draftName;
  final String epc;
  final String itemCode;
  final String itemName;
  final String warehouse;
  final double qty;
  final double netQty;
  final double grossQty;
  final String unit;
  final String printer;
  final String printMode;
  final String printerStatus;
}

Map<String, dynamic> _gscaleDecodeObject(String body) {
  try {
    return (jsonDecode(body) as Map?)?.cast<String, dynamic>() ?? const {};
  } catch (_) {
    return const {};
  }
}

double _gscaleNumber(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String _gscaleText(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}
