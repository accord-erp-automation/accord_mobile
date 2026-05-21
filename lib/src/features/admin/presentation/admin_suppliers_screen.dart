import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shell/app_loading_indicator.dart';
import '../../../core/widgets/shell/app_shell.dart';
import '../../shared/models/app_models.dart';
import 'widgets/admin_dock.dart';
import 'widgets/admin_supplier_list_module.dart';

class AdminSuppliersScreen extends StatefulWidget {
  const AdminSuppliersScreen({super.key});

  @override
  State<AdminSuppliersScreen> createState() => _AdminSuppliersScreenState();
}

class _AdminSuppliersScreenState extends State<AdminSuppliersScreen> {
  static const int _pageSize = 50;
  static const double _prefetchExtentAfterFactor = 2.5;
  static _AdminSuppliersCache? _cache;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final List<AdminUserListEntry> _items = [];
  bool _initialLoading = true;
  bool _loadingMore = false;
  bool _loadingAll = false;
  bool _supplierHasMore = true;
  bool _customerHasMore = true;
  int _supplierOffset = 0;
  int _customerOffset = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _bootstrap();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    await _bootstrap(forceRefresh: true);
  }

  void _handleScroll() {
    if (!_scrollController.hasClients ||
        _initialLoading ||
        _loadingMore ||
        _loadingAll ||
        (!_supplierHasMore && !_customerHasMore)) {
      return;
    }
    final viewport = _scrollController.position.viewportDimension;
    final prefetchExtentAfter = viewport * _prefetchExtentAfterFactor;
    if (_scrollController.position.extentAfter < prefetchExtentAfter) {
      unawaited(_loadMore());
    }
  }

  Future<void> _bootstrap({bool forceRefresh = false}) async {
    if (!forceRefresh && _restoreCache()) {
      return;
    }

    if (mounted) {
      setState(() {
        _initialLoading = true;
        _loadingMore = false;
        _loadingAll = false;
        _supplierHasMore = true;
        _customerHasMore = true;
        _supplierOffset = 0;
        _customerOffset = 0;
        _items.clear();
      });
    }

    final results = await Future.wait([
      _safeLoadAdminSettings(),
      _safeLoadAdminSuppliers(limit: _pageSize, offset: 0),
      _safeLoadAdminCustomers(limit: _pageSize, offset: 0),
    ]);

    final settings = results[0] as AdminSettings;
    final suppliers = results[1] as List<AdminSupplier>;
    final customers = results[2] as List<CustomerDirectoryEntry>;

    final items = <AdminUserListEntry>[
      ..._werkaItem(settings),
      ..._mapSuppliers(suppliers),
      ..._mapCustomers(customers),
    ];
    final supplierHasMore = suppliers.length == _pageSize;
    final supplierOffset = suppliers.length;
    final customerHasMore = customers.length == _pageSize;
    final customerOffset = customers.length;

    if (!mounted) {
      return;
    }
    setState(() {
      _items
        ..clear()
        ..addAll(items);
      _supplierHasMore = supplierHasMore;
      _customerHasMore = customerHasMore;
      _supplierOffset = supplierOffset;
      _customerOffset = customerOffset;
      _initialLoading = false;
      _loadingMore = false;
    });
    _saveCache();
    unawaited(_loadAllRemaining());
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _loadingAll || _initialLoading) {
      return;
    }
    if (!_supplierHasMore && !_customerHasMore) {
      return;
    }

    if (mounted) {
      setState(() => _loadingMore = true);
    }

    try {
      await _loadNextPages();
    } finally {
      if (mounted) {
        setState(() => _loadingMore = false);
      }
    }
  }

  Future<void> _loadAllRemaining() async {
    if (_loadingAll || _loadingMore || _initialLoading) {
      return;
    }
    if (!_supplierHasMore && !_customerHasMore) {
      return;
    }
    if (mounted) {
      setState(() => _loadingAll = true);
    }
    try {
      while (mounted && (_supplierHasMore || _customerHasMore)) {
        await _loadNextPages();
      }
    } finally {
      if (mounted) {
        setState(() => _loadingAll = false);
      }
    }
  }

  Future<void> _loadNextPages() async {
    final shouldLoadSuppliers = _supplierHasMore;
    final shouldLoadCustomers = _customerHasMore;
    if (!shouldLoadSuppliers && !shouldLoadCustomers) {
      return;
    }

    final results = await Future.wait([
      if (shouldLoadSuppliers)
        _safeLoadAdminSuppliers(
          limit: _pageSize,
          offset: _supplierOffset,
        ),
      if (shouldLoadCustomers)
        _safeLoadAdminCustomers(
          limit: _pageSize,
          offset: _customerOffset,
        ),
    ]);
    if (!mounted) {
      return;
    }

    var resultIndex = 0;
    final suppliers = shouldLoadSuppliers
        ? results[resultIndex++] as List<AdminSupplier>
        : const <AdminSupplier>[];
    final customers = shouldLoadCustomers
        ? results[resultIndex] as List<CustomerDirectoryEntry>
        : const <CustomerDirectoryEntry>[];

    setState(() {
      if (shouldLoadSuppliers) {
        _items.addAll(_mapSuppliers(suppliers));
        _supplierOffset += suppliers.length;
        if (suppliers.length < _pageSize) {
          _supplierHasMore = false;
        }
      }
      if (shouldLoadCustomers) {
        _items.addAll(_mapCustomers(customers));
        _customerOffset += customers.length;
        if (customers.length < _pageSize) {
          _customerHasMore = false;
        }
      }
    });
    _saveCache();
  }

  Future<List<AdminSupplier>> _safeLoadAdminSuppliers({
    required int limit,
    required int offset,
  }) async {
    try {
      return await MobileApi.instance.adminSuppliers(
        limit: limit,
        offset: offset,
      );
    } catch (error) {
      debugPrint('admin suppliers page failed: $error');
      return const <AdminSupplier>[];
    }
  }

  Future<List<CustomerDirectoryEntry>> _safeLoadAdminCustomers({
    required int limit,
    required int offset,
  }) async {
    try {
      return await MobileApi.instance.adminCustomers(
        limit: limit,
        offset: offset,
      );
    } catch (error) {
      debugPrint('admin customers page failed: $error');
      return const <CustomerDirectoryEntry>[];
    }
  }

  Future<AdminSettings> _safeLoadAdminSettings() async {
    try {
      return await MobileApi.instance.adminSettings();
    } catch (error) {
      debugPrint('admin settings failed: $error');
      return const AdminSettings(
        erpUrl: '',
        erpApiKey: '',
        erpApiSecret: '',
        defaultTargetWarehouse: '',
        defaultUom: '',
        werkaPhone: '',
        werkaName: '',
        werkaCode: '',
        werkaCodeLocked: false,
        werkaCodeRetryAfterSec: 0,
        adminPhone: '',
        adminName: '',
      );
    }
  }

  List<AdminUserListEntry> _werkaItem(AdminSettings settings) {
    if (settings.werkaName.trim().isEmpty &&
        settings.werkaPhone.trim().isEmpty) {
      return const <AdminUserListEntry>[];
    }
    return [
      AdminUserListEntry(
        id: 'werka',
        name: settings.werkaName.trim().isEmpty
            ? 'Werka'
            : settings.werkaName.trim(),
        phone: settings.werkaPhone.trim(),
        kind: AdminUserKind.werka,
      ),
    ];
  }

  List<AdminUserListEntry> _mapSuppliers(List<AdminSupplier> suppliers) {
    return suppliers
        .map(
          (item) => AdminUserListEntry(
            id: item.ref,
            name: item.name,
            phone: item.phone,
            kind: AdminUserKind.supplier,
            blocked: item.blocked,
          ),
        )
        .toList();
  }

  List<AdminUserListEntry> _mapCustomers(
      List<CustomerDirectoryEntry> customers) {
    return customers
        .map(
          (item) => AdminUserListEntry(
            id: item.ref,
            name: item.name,
            phone: item.phone,
            kind: AdminUserKind.customer,
          ),
        )
        .toList();
  }

  Future<void> _openUser(AdminUserListEntry item) async {
    bool changed = false;
    if (item.kind == AdminUserKind.werka) {
      final result =
          await Navigator.of(context).pushNamed(AppRoutes.adminWerka);
      changed = result == true;
    } else if (item.kind == AdminUserKind.customer) {
      final result = await Navigator.of(context).pushNamed(
        AppRoutes.adminCustomerDetail,
        arguments: item.id,
      );
      changed = result == true;
    } else {
      final result = await Navigator.of(context).pushNamed(
        AppRoutes.adminSupplierDetail,
        arguments: item.id,
      );
      changed = result == true;
    }
    if (changed && mounted) {
      await _bootstrap(forceRefresh: true);
    }
  }

  bool _restoreCache() {
    final cache = _cache;
    if (cache == null) {
      return false;
    }
    if (mounted) {
      setState(() {
        _items
          ..clear()
          ..addAll(cache.items);
        _supplierHasMore = cache.supplierHasMore;
        _customerHasMore = cache.customerHasMore;
        _supplierOffset = cache.supplierOffset;
        _customerOffset = cache.customerOffset;
        _initialLoading = false;
        _loadingMore = false;
        _loadingAll = false;
      });
    }
    unawaited(_loadAllRemaining());
    return true;
  }

  void _saveCache() {
    _cache = _AdminSuppliersCache(
      items: List<AdminUserListEntry>.unmodifiable(_items),
      supplierHasMore: _supplierHasMore,
      customerHasMore: _customerHasMore,
      supplierOffset: _supplierOffset,
      customerOffset: _customerOffset,
    );
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    if (value.trim().isNotEmpty) {
      unawaited(_loadAllRemaining());
    }
  }

  List<AdminUserListEntry> _visibleItems() {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return _items;
    }
    return _items.where((item) {
      return item.name.toLowerCase().contains(query) ||
          item.phone.toLowerCase().contains(query) ||
          item.id.toLowerCase().contains(query) ||
          item.roleLabel.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    final visibleItems = _visibleItems();
    return AppShell(
      animateOnEnter: false,
      title: l10n?.adminUsersTitle ?? 'Users',
      subtitle: '',
      nativeTopBar: true,
      nativeTitleTextStyle: AppTheme.werkaNativeAppBarTitleStyle(context),
      contentPadding: EdgeInsets.zero,
      bottom: const AdminDock(activeTab: AdminDockTab.suppliers),
      child: _initialLoading
          ? const Center(child: AppLoadingIndicator())
          : AppRefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 116),
                children: [
                  _AdminUserSearchField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    onClear: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: AdminSupplierListModule(
                      items: visibleItems,
                      onTapUser: _openUser,
                    ),
                  ),
                  if (_loadingMore || _loadingAll)
                    const Padding(
                      padding: EdgeInsets.only(top: 14),
                      child: Center(child: AppLoadingIndicator()),
                    )
                  else if (_supplierHasMore || _customerHasMore)
                    const SizedBox(height: 14),
                ],
              ),
            ),
    );
  }
}

class _AdminUserSearchField extends StatelessWidget {
  const _AdminUserSearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final hasText = controller.text.trim().isNotEmpty;
          return TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Foydalanuvchi qidirish',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: hasText
                  ? IconButton(
                      tooltip: 'Tozalash',
                      onPressed: onClear,
                      icon: const Icon(Icons.close_rounded),
                    )
                  : null,
              filled: true,
              fillColor: scheme.surfaceContainer,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AdminSuppliersCache {
  const _AdminSuppliersCache({
    required this.items,
    required this.supplierHasMore,
    required this.customerHasMore,
    required this.supplierOffset,
    required this.customerOffset,
  });

  final List<AdminUserListEntry> items;
  final bool supplierHasMore;
  final bool customerHasMore;
  final int supplierOffset;
  final int customerOffset;
}
