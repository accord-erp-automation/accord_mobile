import 'package:erpnext_stock_mobile/src/core/api/mobile_api.dart';
import 'package:erpnext_stock_mobile/src/core/test_mode/test_mode_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
  });

  test('test mode returns demo admin users without server', () async {
    await TestModeController.instance.setEnabled(true);

    final suppliers = await MobileApi.instance.adminSuppliers();
    final customers = await MobileApi.instance.adminCustomers();
    final settings = await MobileApi.instance.adminSettings();

    expect(settings.werkaName, 'Demo omborchi');
    expect(suppliers.map((item) => item.ref), contains('demo-supplier-1'));
    expect(customers.map((item) => item.ref), contains('demo-customer-1'));
  });

  test('test mode can be switched off', () async {
    await TestModeController.instance.setEnabled(true);
    expect(await TestModeController.instance.isEnabled(), isTrue);

    await TestModeController.instance.setEnabled(false);
    expect(await TestModeController.instance.isEnabled(), isFalse);
  });

  test('test mode returns searchable demo products without server', () async {
    await TestModeController.instance.setEnabled(true);

    final allItems = await MobileApi.instance.adminItemsPage();
    final filtered = await MobileApi.instance.adminItemsPage(query: 'cpp');

    expect(allItems.map((item) => item.code), contains('DEMO-HOTLUNCH'));
    expect(filtered, hasLength(1));
    expect(filtered.single.code, 'DEMO-CPP');
  });
}
