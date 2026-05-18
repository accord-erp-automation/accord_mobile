import 'package:erpnext_stock_mobile/src/core/api/mobile_api.dart';
import 'package:erpnext_stock_mobile/src/features/gscale/gscale_mobile_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('material receipt print request matches RS contract', () {
    const request = GScaleMaterialReceiptPrintRequest(
      driverUrl: ' http://127.0.0.1:39117 ',
      itemCode: ' ITEM-1 ',
      itemName: ' Green Tea ',
      warehouse: ' Stores - A ',
      printer: 'zebra',
      printMode: 'rfid',
      grossQty: 2.5,
      tareEnabled: true,
      tareKg: 0.78,
    );

    expect(request.toJson(), {
      'driver_url': 'http://127.0.0.1:39117',
      'item_code': 'ITEM-1',
      'item_name': 'Green Tea',
      'warehouse': 'Stores - A',
      'printer': 'zebra',
      'print_mode': 'rfid',
      'gross_qty': 2.5,
      'unit': 'kg',
      'tare_enabled': true,
      'tare_kg': 0.78,
    });
  });

  test('material receipt print response reads RS result', () {
    final response = GScaleMaterialReceiptPrintResponse.fromJson({
      'ok': true,
      'status': 'submitted',
      'draft_name': 'MAT-STE-001',
      'epc': '000000000000000000000001',
      'item_code': 'ITEM-1',
      'item_name': 'Green Tea',
      'warehouse': 'Stores - A',
      'qty': 1.72,
      'net_qty': 1.72,
      'gross_qty': 2.5,
      'unit': 'kg',
      'printer': 'zebra',
      'print_mode': 'rfid',
      'printer_status': 'OK',
    });

    expect(response.ok, isTrue);
    expect(response.status, 'submitted');
    expect(response.draftName, 'MAT-STE-001');
    expect(response.netQty, 1.72);
    expect(response.grossQty, 2.5);
    expect(response.printer, 'zebra');
  });

  test('scale display kg parser accepts monitor label', () {
    expect(parseScaleDisplayKg('2.500 kg'), 2.5);
    expect(parseScaleDisplayKg('2,500 kg'), 2.5);
    expect(parseScaleDisplayKg('--'), isNull);
  });
}
