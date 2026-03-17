import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/notifications/supplier_runtime_store.dart';
import '../../../core/widgets/app_shell.dart';
import '../../shared/models/app_models.dart';
import 'widgets/supplier_dock.dart';
import 'package:flutter/material.dart';

class SupplierConfirmArgs {
  const SupplierConfirmArgs({
    required this.item,
    required this.qty,
  });

  final SupplierItem item;
  final double qty;
}

class SupplierConfirmScreen extends StatelessWidget {
  const SupplierConfirmScreen({
    super.key,
    required this.args,
  });

  final SupplierConfirmArgs args;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppShell(
      title: 'Tasdiqlash',
      subtitle: '',
      bottom: const SupplierDock(activeTab: null, centerActive: true),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Text.rich(
            TextSpan(
              style: textTheme.titleMedium,
              children: [
                const TextSpan(text: 'Mahsulot: '),
                TextSpan(
                  text: args.item.code,
                  style: textTheme.titleLarge,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: textTheme.titleMedium,
              children: [
                const TextSpan(text: 'Nomi: '),
                TextSpan(
                  text: args.item.name,
                  style: textTheme.titleLarge,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: textTheme.titleMedium,
              children: [
                const TextSpan(text: 'Miqdor: '),
                TextSpan(
                  text: '${args.qty.toStringAsFixed(2)} ${args.item.uom}',
                  style: textTheme.titleLarge,
                ),
              ],
            ),
          ),
          if (args.item.warehouse.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                style: textTheme.titleMedium,
                children: [
                  const TextSpan(text: 'Ombor: '),
                  TextSpan(
                    text: args.item.warehouse,
                    style: textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final DispatchRecord record =
                    await MobileApi.instance.createDispatch(
                  itemCode: args.item.code,
                  qty: args.qty,
                );
                SupplierRuntimeStore.instance.recordCreatedPending();
                if (!context.mounted) {
                  return;
                }
                Navigator.of(context)
                    .pushNamed(AppRoutes.supplierSuccess, arguments: record);
              },
              child: const Text('Ha, jo‘natishni saqlash'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Orqaga qaytish'),
            ),
          ),
        ],
      ),
    );
  }
}
