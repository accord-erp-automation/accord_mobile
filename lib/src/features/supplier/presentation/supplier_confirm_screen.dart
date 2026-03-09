import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../shared/models/app_models.dart';
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
    return AppShell(
      title: 'Tasdiqlash',
      subtitle: 'Yuborishdan oldin ma’lumotlarni yana bir ko‘rib chiqing.',
      child: Column(
        children: [
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Row(label: 'Mahsulot', value: args.item.code),
                _Row(label: 'Nomi', value: args.item.name),
                _Row(
                    label: 'Miqdor',
                    value: '${args.qty.toStringAsFixed(2)} ${args.item.uom}'),
                _Row(label: 'Ombor', value: args.item.warehouse),
              ],
            ),
          ),
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

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
