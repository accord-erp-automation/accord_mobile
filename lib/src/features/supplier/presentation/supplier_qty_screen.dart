import '../../../app/app_router.dart';
import '../../../core/widgets/app_shell.dart';
import '../../shared/models/app_models.dart';
import 'supplier_confirm_screen.dart';
import 'widgets/supplier_dock.dart';
import 'package:flutter/material.dart';

class SupplierQtyScreen extends StatefulWidget {
  const SupplierQtyScreen({
    super.key,
    required this.item,
  });

  final SupplierItem item;

  @override
  State<SupplierQtyScreen> createState() => _SupplierQtyScreenState();
}

class _SupplierQtyScreenState extends State<SupplierQtyScreen> {
  final TextEditingController controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppShell(
      title: 'Miqdor',
      subtitle: '',
      bottom: const SupplierDock(activeTab: null, centerActive: true),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Text(
            widget.item.code,
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            widget.item.name,
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: 18),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: textTheme.displaySmall,
            decoration: InputDecoration(
              hintText: '0',
              suffixText: widget.item.uom,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final double qty = double.tryParse(controller.text.trim()) ?? 0;
                if (qty <= 0) {
                  return;
                }
                Navigator.of(context).pushNamed(
                  AppRoutes.supplierConfirm,
                  arguments: SupplierConfirmArgs(item: widget.item, qty: qty),
                );
              },
              child: const Text('Davom etish'),
            ),
          ),
        ],
      ),
    );
  }
}
