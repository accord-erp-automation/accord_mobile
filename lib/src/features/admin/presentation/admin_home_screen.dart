import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/cache/json_cache_store.dart';
import '../../../core/notifications/refresh_hub.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../shared/models/app_models.dart';
import 'widgets/admin_dock.dart';
import 'package:flutter/material.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  static const String _cacheKey = 'cache_admin_summary';
  late Future<AdminSupplierSummary> _summaryFuture;
  AdminSupplierSummary? _cachedSummary;
  int _refreshVersion = 0;

  @override
  void initState() {
    super.initState();
    _summaryFuture = MobileApi.instance.adminSupplierSummary();
    _loadCache();
    RefreshHub.instance.addListener(_handlePushRefresh);
  }

  Future<void> _loadCache() async {
    final raw = await JsonCacheStore.instance.readMap(_cacheKey);
    if (raw == null || !mounted) {
      return;
    }
    setState(() {
      _cachedSummary = AdminSupplierSummary.fromJson(raw);
    });
  }

  @override
  void dispose() {
    RefreshHub.instance.removeListener(_handlePushRefresh);
    super.dispose();
  }

  void _handlePushRefresh() {
    if (!mounted || RefreshHub.instance.topic != 'admin') {
      return;
    }
    if (_refreshVersion == RefreshHub.instance.version) {
      return;
    }
    _refreshVersion = RefreshHub.instance.version;
    _reload();
  }

  Future<void> _reload() async {
    final future = MobileApi.instance.adminSupplierSummary();
    setState(() {
      _summaryFuture = future;
    });
    final summary = await future;
    await JsonCacheStore.instance.writeMap(_cacheKey, summary.toJson());
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Admin',
      subtitle: '',
      contentPadding: const EdgeInsets.fromLTRB(12, 0, 14, 0),
      bottom: const AdminDock(activeTab: AdminDockTab.home),
      child: FutureBuilder<AdminSupplierSummary>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          final summary = snapshot.data ?? _cachedSummary;
          if (snapshot.connectionState != ConnectionState.done &&
              summary == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError && summary == null) {
            return Center(
              child: Card.filled(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Admin summary yuklanmadi: ${snapshot.error}'),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _reload,
                        child: const Text('Qayta urinish'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final summaryValue = summary!;
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                SmoothAppear(
                  delay: const Duration(milliseconds: 20),
                  child: _AdminModulesSection(
                    onTapSettings: () => Navigator.of(context)
                        .pushNamed(AppRoutes.adminSettings),
                    onTapSuppliers: () => Navigator.of(context)
                        .pushNamed(AppRoutes.adminSuppliers),
                    onTapWerka: () =>
                        Navigator.of(context).pushNamed(AppRoutes.adminWerka),
                  ),
                ),
                if (summaryValue.blockedSuppliers > 0) ...[
                  const SizedBox(height: 12),
                  SmoothAppear(
                    delay: const Duration(milliseconds: 60),
                    child: _AdminBlockedSuppliersCard(
                      count: summaryValue.blockedSuppliers,
                      onTap: () => Navigator.of(context)
                          .pushNamed(AppRoutes.adminInactiveSuppliers),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AdminModulesSection extends StatelessWidget {
  const _AdminModulesSection({
    required this.onTapSettings,
    required this.onTapSuppliers,
    required this.onTapWerka,
  });

  final VoidCallback onTapSettings;
  final VoidCallback onTapSuppliers;
  final VoidCallback onTapWerka;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card.filled(
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          _AdminModuleRow(
            title: 'Settings',
            subtitle: 'ERP va default sozlamalar',
            onTap: onTapSettings,
          ),
          const _AdminSectionDivider(),
          _AdminModuleRow(
            title: 'Suppliers',
            subtitle: 'List, mahsulot biriktirish va block nazorati',
            onTap: onTapSuppliers,
          ),
          const _AdminSectionDivider(),
          _AdminModuleRow(
            title: 'Werka',
            subtitle: 'Omborchi phone va name',
            onTap: onTapWerka,
          ),
        ],
      ),
    );
  }
}

class _AdminModuleRow extends StatelessWidget {
  const _AdminModuleRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.arrow_forward_rounded,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminSectionDivider extends StatelessWidget {
  const _AdminSectionDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 18,
      endIndent: 18,
      color: Theme.of(context).dividerColor.withValues(alpha: 0.55),
    );
  }
}

class _AdminBlockedSuppliersCard extends StatelessWidget {
  const _AdminBlockedSuppliersCard({
    required this.count,
    required this.onTap,
  });

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card.filled(
      margin: EdgeInsets.zero,
      color: scheme.secondaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Icon(
                Icons.block_rounded,
                color: scheme.onSecondaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Bloklangan supplierlar: $count ta',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.onSecondaryContainer,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: scheme.onSecondaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
