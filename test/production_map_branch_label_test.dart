import 'package:erpnext_stock_mobile/src/features/admin/presentation/admin_production_map_test_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('condition branch labels use if else wording', () {
    expect(productionMapBranchDisplayLabel('true'), 'Shunda');
    expect(productionMapBranchDisplayLabel('false'), 'Aks holda');
    expect(productionMapBranchDisplayLabel('custom'), 'custom');
  });
}
