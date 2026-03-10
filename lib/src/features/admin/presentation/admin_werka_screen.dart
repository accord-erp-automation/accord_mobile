import '../../../core/api/mobile_api.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../shared/models/app_models.dart';
import 'widgets/admin_dock.dart';
import 'package:flutter/material.dart';

class AdminWerkaScreen extends StatefulWidget {
  const AdminWerkaScreen({super.key});

  @override
  State<AdminWerkaScreen> createState() => _AdminWerkaScreenState();
}

class _AdminWerkaScreenState extends State<AdminWerkaScreen> {
  late Future<AdminSettings> _future;
  final phone = TextEditingController();
  final name = TextEditingController();
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _future = MobileApi.instance.adminSettings();
  }

  @override
  void dispose() {
    phone.dispose();
    name.dispose();
    super.dispose();
  }

  void _fill(AdminSettings settings) {
    phone.text = settings.werkaPhone;
    name.text = settings.werkaName;
  }

  Future<void> _save(AdminSettings current) async {
    setState(() => saving = true);
    try {
      final updated = await MobileApi.instance.updateAdminSettings(
        AdminSettings(
          erpUrl: current.erpUrl,
          erpApiKey: current.erpApiKey,
          erpApiSecret: current.erpApiSecret,
          defaultTargetWarehouse: current.defaultTargetWarehouse,
          defaultUom: current.defaultUom,
          werkaPhone: phone.text.trim(),
          werkaName: name.text.trim(),
          adminPhone: current.adminPhone,
          adminName: current.adminName,
        ),
      );
      _fill(updated);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Werka',
      subtitle: 'Omborchi sozlamalari.',
      bottom: const AdminDock(activeTab: AdminDockTab.settings),
      child: FutureBuilder<AdminSettings>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: SoftCard(
                child: Text('Werka yuklanmadi: ${snapshot.error}'),
              ),
            );
          }
          final current = snapshot.data!;
          _fill(current);
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              TextField(
                controller: phone,
                decoration: const InputDecoration(labelText: 'Werka phone'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Werka name'),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: saving ? null : () => _save(current),
                  child: Text(saving ? 'Saqlanmoqda...' : 'Saqlash'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
