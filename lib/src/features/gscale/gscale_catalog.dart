import '../../core/api/mobile_api.dart';
import '../../core/session/session.dart';
import '../shared/models/app_models.dart';

class GScaleCatalogWarehouse {
  const GScaleCatalogWarehouse({
    required this.warehouse,
    this.actualQty,
    this.company,
  });

  final String warehouse;
  final double? actualQty;
  final String? company;
}

Future<List<GScaleCatalogWarehouse>> fetchGScaleItemWarehouses({
  required String itemCode,
  String query = '',
  int limit = 12,
  MobileApi? api,
  UserRole? role,
}) async {
  final client = api ?? MobileApi.instance;
  final activeRole = role ?? AppSession.instance.profile?.role;
  if (activeRole == UserRole.admin) {
    final items = await client.adminItemsPage(query: itemCode, limit: 50);
    final exactItems = items.where((item) {
      return item.code.trim().toLowerCase() == itemCode.trim().toLowerCase();
    }).toList(growable: false);
    if (exactItems.isEmpty) {
      return const [];
    }
    final warehouses = gscaleWarehousesFromSupplierItems(
      exactItems,
      itemCode: itemCode,
      query: query,
    );
    if (warehouses.isNotEmpty) {
      return warehouses.take(limit).toList();
    }
    return fetchGScaleDefaultWarehouses(
      query: query,
      limit: limit,
      api: client,
      role: activeRole,
    );
  }
  if (activeRole == UserRole.werka) {
    final items = await client.gscaleItemsPage(
      query: itemCode,
      limit: 50,
    );
    final warehouses = gscaleWarehousesFromSupplierItems(
      items,
      itemCode: itemCode,
      query: query,
    );
    if (warehouses.isNotEmpty) {
      return warehouses.take(limit).toList();
    }
    return fetchGScaleDefaultWarehouses(
      query: query,
      limit: limit,
      api: client,
      role: activeRole,
    );
  }
  throw Exception('GScale omborlari faqat admin yoki werka uchun mavjud');
}

Future<List<GScaleCatalogWarehouse>> fetchGScaleDefaultWarehouses({
  String query = '',
  int limit = 30,
  MobileApi? api,
  UserRole? role,
}) async {
  final client = api ?? MobileApi.instance;
  final activeRole = role ?? AppSession.instance.profile?.role;
  if (activeRole == UserRole.admin) {
    final settings = await client.adminSettings();
    return gscaleWarehousesFromDefault(
      settings.defaultTargetWarehouse,
      query: query,
    ).take(limit).toList();
  }
  if (activeRole == UserRole.werka) {
    final items = await client.gscaleItemsPage(limit: 200);
    return gscaleWarehousesFromSupplierItems(items, query: query)
        .take(limit)
        .toList();
  }
  throw Exception('GScale omborlari faqat admin yoki werka uchun mavjud');
}

List<GScaleCatalogWarehouse> gscaleWarehousesFromSupplierItems(
  Iterable<SupplierItem> items, {
  String itemCode = '',
  String query = '',
}) {
  return _uniqueWarehouses(
    items.where((item) {
      if (itemCode.trim().isEmpty) {
        return true;
      }
      return item.code.trim().toLowerCase() == itemCode.trim().toLowerCase();
    }).map((item) => item.warehouse),
    query: query,
  );
}

List<GScaleCatalogWarehouse> gscaleWarehousesFromCustomerOptions(
  Iterable<CustomerItemOption> options, {
  String itemCode = '',
  String query = '',
}) {
  return _uniqueWarehouses(
    options.where((option) {
      if (itemCode.trim().isEmpty) {
        return true;
      }
      return option.itemCode.trim().toLowerCase() ==
          itemCode.trim().toLowerCase();
    }).map((option) => option.warehouse),
    query: query,
  );
}

List<GScaleCatalogWarehouse> gscaleWarehousesFromDefault(
  String warehouse, {
  String query = '',
}) {
  return _uniqueWarehouses([warehouse], query: query);
}

List<GScaleCatalogWarehouse> _uniqueWarehouses(
  Iterable<String> warehouses, {
  required String query,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  final seen = <String>{};
  final out = <GScaleCatalogWarehouse>[];
  for (final raw in warehouses) {
    final warehouse = raw.trim();
    if (warehouse.isEmpty ||
        !warehouse.toLowerCase().contains(normalizedQuery) ||
        !seen.add(warehouse.toLowerCase())) {
      continue;
    }
    out.add(GScaleCatalogWarehouse(warehouse: warehouse));
  }
  return out;
}
