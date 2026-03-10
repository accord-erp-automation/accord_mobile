import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../shared/models/app_models.dart';
import 'widgets/admin_dock.dart';
import 'widgets/admin_supplier_list_module.dart';
import 'package:flutter/material.dart';

class AdminSuppliersScreen extends StatefulWidget {
  const AdminSuppliersScreen({super.key});

  @override
  State<AdminSuppliersScreen> createState() => _AdminSuppliersScreenState();
}

class _AdminSuppliersScreenState extends State<AdminSuppliersScreen> {
  late Future<List<AdminSupplier>> _future;
  final name = TextEditingController();
  final phone = TextEditingController();
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _future = MobileApi.instance.adminSuppliers();
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final future = MobileApi.instance.adminSuppliers();
    setState(() {
      _future = future;
    });
    await future;
  }

  Future<void> _create() async {
    setState(() => saving = true);
    try {
      await MobileApi.instance.adminCreateSupplier(
        name: name.text.trim(),
        phone: phone.text.trim(),
      );
      name.clear();
      phone.clear();
      await _reload();
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      leading: AppShellIconAction(
        icon: Icons.arrow_back_rounded,
        onTap: () => Navigator.of(context).maybePop(),
      ),
      title: 'Suppliers',
      subtitle: 'Qo‘shish va ixcham list moduli.',
      bottom: const AdminDock(activeTab: AdminDockTab.suppliers),
      child: FutureBuilder<List<AdminSupplier>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: SoftCard(
                child: Text('Suppliers yuklanmadi: ${snapshot.error}'),
              ),
            );
          }
          final items = snapshot.data ?? const <AdminSupplier>[];
          return ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: 2,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return SoftCard(
                  child: Column(
                    children: [
                      TextField(
                        controller: name,
                        decoration:
                            const InputDecoration(labelText: 'Supplier name'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phone,
                        decoration:
                            const InputDecoration(labelText: 'Supplier phone'),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: saving ? null : _create,
                          child: Text(
                            saving ? 'Qo‘shilmoqda...' : 'Supplier qo‘shish',
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return AdminSupplierListModule(
                items: items,
                onTapSupplier: (item) async {
                  await Navigator.of(context).pushNamed(
                    AppRoutes.adminSupplierDetail,
                    arguments: item.ref,
                  );
                  await _reload();
                },
              );
            },
          );
        },
      ),
    );
  }
}
