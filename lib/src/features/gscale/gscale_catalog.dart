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

enum GScaleCatalogItemSource {
  adminItems,
  gscaleItems,
}

GScaleCatalogItemSource gscaleCatalogItemSourceForProfile(
  SessionProfile? profile,
) {
  if (profile?.hasCapability('catalog.item.read') == true) {
    return GScaleCatalogItemSource.adminItems;
  }
  return GScaleCatalogItemSource.gscaleItems;
}

Future<List<GScaleCatalogWarehouse>> fetchGScaleItemWarehouses({
  required String itemCode,
  String query = '',
  int limit = 12,
  MobileApi? api,
  UserRole? role,
}) async {
  final client = api ?? MobileApi.instance;
  final profile = AppSession.instance.profile;
  final canReadAdminCatalog = role == UserRole.admin ||
      (role == null && profile?.hasCapability('catalog.item.read') == true);
  final canReadGScaleCatalog = role == UserRole.werka ||
      (role == null && profile?.hasCapability('gscale.catalog.read') == true);
  if (canReadAdminCatalog) {
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
      role: role,
    );
  }
  if (canReadGScaleCatalog) {
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
      role: role,
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
  final profile = AppSession.instance.profile;
  final canReadAdminWarehouses = role == UserRole.admin ||
      (role == null &&
          (profile?.hasCapability('admin.access') == true ||
              profile?.hasCapability('production.map.manage') == true ||
              profile?.hasCapability('catalog.item.read') == true));
  final canReadGScaleCatalog = role == UserRole.werka ||
      (role == null && profile?.hasCapability('gscale.catalog.read') == true);
  if (canReadAdminWarehouses) {
    final warehouses = await client.adminWarehouses(query: query, limit: limit);
    return warehouses
        .map(
          (warehouse) => GScaleCatalogWarehouse(
            warehouse: warehouse.warehouse,
            company:
                warehouse.company.trim().isEmpty ? null : warehouse.company,
          ),
        )
        .where((warehouse) => warehouse.warehouse.trim().isNotEmpty)
        .take(limit)
        .toList(growable: false);
  }
  if (canReadGScaleCatalog) {
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
