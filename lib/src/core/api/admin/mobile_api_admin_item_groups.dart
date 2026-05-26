part of '../mobile_api.dart';

extension MobileApiAdminItemGroups on MobileApi {
  Future<List<String>> adminItemGroups() async {
    if (await TestModeController.instance.isEnabled()) {
      return TestModeDemoData.itemGroups;
    }
    final response = await _sendAuthorized(
      () => http.get(
        Uri.parse('${MobileApi.baseUrl}/v1/mobile/admin/item-groups'),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Admin item groups failed');
    }
    final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
    return json.map((item) => item.toString()).toList();
  }

  Future<List<AdminItemGroupTreeEntry>> adminItemGroupTree() async {
    if (await TestModeController.instance.isEnabled()) {
      return TestModeDemoData.itemGroupTree;
    }
    final response = await _sendAuthorized(
      () => http.get(
        Uri.parse('${MobileApi.baseUrl}/v1/mobile/admin/item-groups/tree'),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Admin item group tree failed');
    }
    final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
    return json
        .map(
          (item) =>
              AdminItemGroupTreeEntry.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<AdminItemGroup> adminCreateItemGroup({
    required String name,
    required String parent,
    required bool isGroup,
  }) async {
    final response = await _sendAuthorized(
      () => http.post(
        Uri.parse('${MobileApi.baseUrl}/v1/mobile/admin/item-groups'),
        headers: _headers(requireToken())
          ..['Content-Type'] = 'application/json',
        body: jsonEncode({
          'name': name,
          'parent': parent,
          'is_group': isGroup,
        }),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Admin item group create failed');
    }
    return AdminItemGroup.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<AdminItemGroup> adminMoveItemGroupParent({
    required String name,
    required String parent,
  }) async {
    final response = await _sendAuthorized(
      () => http.put(
        Uri.parse('${MobileApi.baseUrl}/v1/mobile/admin/item-groups'),
        headers: _headers(requireToken())
          ..['Content-Type'] = 'application/json',
        body: jsonEncode({
          'name': name,
          'parent': parent,
        }),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Admin item group parent move failed');
    }
    return AdminItemGroup.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
