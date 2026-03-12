import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../shared/models/app_models.dart';
import 'widgets/werka_dock.dart';
import 'package:flutter/material.dart';

class WerkaUnannouncedSupplierScreen extends StatefulWidget {
  const WerkaUnannouncedSupplierScreen({super.key});

  @override
  State<WerkaUnannouncedSupplierScreen> createState() =>
      _WerkaUnannouncedSupplierScreenState();
}

class _WerkaUnannouncedSupplierScreenState
    extends State<WerkaUnannouncedSupplierScreen> {
  late Future<List<SupplierDirectoryEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = MobileApi.instance.werkaSuppliers();
  }

  Future<void> _reload() async {
    final future = MobileApi.instance.werkaSuppliers();
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Supplier tanlang',
      subtitle: '',
      leading: AppShellIconAction(
        icon: Icons.arrow_back_rounded,
        onTap: () => Navigator.of(context).maybePop(),
      ),
      bottom: const WerkaDock(activeTab: null),
      child: FutureBuilder<List<SupplierDirectoryEntry>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: SoftCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Supplierlar yuklanmadi: ${snapshot.error}'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _reload,
                      child: const Text('Qayta urinish'),
                    ),
                  ],
                ),
              ),
            );
          }
          final items = snapshot.data ?? const <SupplierDirectoryEntry>[];
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => Navigator.of(context).pushNamed(
                    AppRoutes.werkaUnannouncedItem,
                    arguments: item,
                  ),
                  child: SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 6),
                        Text(item.phone, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
