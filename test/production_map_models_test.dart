import 'package:erpnext_stock_mobile/src/features/admin/models/production_map_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production map node serializes movement and qty formula fields', () {
    const node = ProductionMapNode(
      id: 'rezka',
      kind: 'task',
      title: 'Rezka',
      roleCode: 'rezkachi',
      itemCode: 'CPP',
      qtyFormula: 'cpp_kg / 6',
      fromLocation: 'CPP ombor',
      toLocation: 'Rezka apparat',
    );

    expect(node.toJson(), containsPair('qty_formula', 'cpp_kg / 6'));
    expect(node.toJson(), containsPair('from_location', 'CPP ombor'));
    expect(node.toJson(), containsPair('to_location', 'Rezka apparat'));

    final parsed = ProductionMapNode.fromJson(node.toJson());
    expect(parsed.qtyFormula, 'cpp_kg / 6');
    expect(parsed.fromLocation, 'CPP ombor');
    expect(parsed.toLocation, 'Rezka apparat');
  });

  test('production map run request carries runtime condition variables', () {
    const request = ProductionMapRunRequest(
      mapId: 'map-1',
      productCode: 'HOT',
      orderQty: 100,
      variables: {'pechat_ok': 1.0},
    );

    expect(request.toJson()['variables'], {'pechat_ok': 1.0});
  });
}
