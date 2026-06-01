part of '../mobile_api.dart';

extension MobileApiAdminItems on MobileApi {
  Future<AdminCustomerDetail> adminAssignCustomerItem({
    required String ref,
    required String itemCode,
  }) async {
    final response = await _sendAuthorized(
      () => http.post(
        Uri.parse('${MobileApi.baseUrl}/v1/mobile/admin/customers/items/add')
            .replace(queryParameters: {'ref': ref}),
        headers: _headers(requireToken())
          ..['Content-Type'] = 'application/json',
        body: jsonEncode({'item_code': itemCode}),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Admin customer item add failed');
    }
    return AdminCustomerDetail.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<AdminCustomerDetail> adminRemoveCustomerItem({
    required String ref,
    required String itemCode,
  }) async {
    final response = await _sendAuthorized(
      () => http.delete(
        Uri.parse('${MobileApi.baseUrl}/v1/mobile/admin/customers/items/remove')
            .replace(
          queryParameters: {
            'ref': ref,
            'item_code': itemCode,
          },
        ),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Admin customer item remove failed');
    }
    return AdminCustomerDetail.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<SupplierItem>> adminItems({
    String query = '',
    String group = '',
  }) async {
    if (await TestModeController.instance.isEnabled()) {
      return TestModeDemoData.itemPage(
        query: query,
        group: group,
        limit: 0,
      );
    }
    const pageSize = 200;
    final items = <SupplierItem>[];
    for (var offset = 0;; offset += pageSize) {
      final page = await adminItemsPage(
        query: query,
        group: group,
        limit: pageSize,
        offset: offset,
      );
      items.addAll(page);
      if (page.length < pageSize) {
        break;
      }
    }
    return items;
  }

  Future<List<SupplierItem>> adminItemsPage({
    String query = '',
    String group = '',
    int limit = 50,
    int offset = 0,
  }) async {
    if (await TestModeController.instance.isEnabled()) {
      return TestModeDemoData.itemPage(
        query: query,
        group: group,
        limit: limit,
        offset: offset,
      );
    }
    final response = await _sendAuthorized(
      () => http.get(
        Uri.parse('${MobileApi.baseUrl}/v1/mobile/admin/items').replace(
          queryParameters: {
            if (query.trim().isNotEmpty) 'q': query.trim(),
            if (group.trim().isNotEmpty) 'group': group.trim(),
            if (limit > 0) 'limit': '$limit',
            if (offset > 0) 'offset': '$offset',
          },
        ),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Admin items failed');
    }
    final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
    return json
        .map((item) => SupplierItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<AdminWarehouse>> adminWarehouses({
    String query = '',
    int limit = 50,
  }) async {
    if (await TestModeController.instance.isEnabled()) {
      final normalized = query.trim().toLowerCase();
      return TestModeDemoData.warehouses
          .where(
            (warehouse) =>
                normalized.isEmpty ||
                warehouse.warehouse.toLowerCase().contains(normalized),
          )
          .take(limit)
          .toList(growable: false);
    }
    final response = await _sendAuthorized(
      () => http.get(
        Uri.parse('${MobileApi.baseUrl}/v1/mobile/admin/warehouses').replace(
          queryParameters: {
            if (query.trim().isNotEmpty) 'q': query.trim(),
            if (limit > 0) 'limit': '$limit',
          },
        ),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Admin warehouses failed');
    }
    final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
    return json
        .map((item) => AdminWarehouse.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AdminItemGroupBulkMoveResult> adminMoveItemsToGroup({
    required List<String> itemCodes,
    required String itemGroup,
  }) async {
    final response = await _sendAuthorized(
      () => http.post(
        Uri.parse('${MobileApi.baseUrl}/v1/mobile/admin/items/bulk-move-group'),
        headers: _headers(requireToken())
          ..['Content-Type'] = 'application/json',
        body: jsonEncode({
          'item_codes': itemCodes,
          'item_group': itemGroup,
        }),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Admin item group bulk move failed');
    }
    return AdminItemGroupBulkMoveResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<SupplierItem> adminCreateItem({
    required String code,
    required String name,
    required String uom,
    required String itemGroup,
  }) async {
    final response = await _sendAuthorized(
      () => http.post(
        Uri.parse('${MobileApi.baseUrl}/v1/mobile/admin/items'),
        headers: _headers(requireToken())
          ..['Content-Type'] = 'application/json',
        body: jsonEncode({
          'code': code,
          'name': name,
          'uom': uom,
          'item_group': itemGroup,
        }),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Admin item create failed');
    }
    return SupplierItem.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
