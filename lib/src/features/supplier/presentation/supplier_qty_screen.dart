import '../../../app/app_router.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../shared/models/app_models.dart';
import 'supplier_confirm_screen.dart';
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
    return AppShell(
      title: 'Miqdor',
      subtitle: '${widget.item.code} uchun jo‘natilayotgan miqdorni kiriting.',
      child: Column(
        children: [
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.item.code,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(widget.item.name),
              ],
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: Theme.of(context).textTheme.displaySmall,
            decoration: InputDecoration(
              hintText: '0',
              suffixText: widget.item.uom,
            ),
          ),
          const SizedBox(height: 16),
          const SoftCard(
            child: Text(
                'MVP preview: keyingi bosqichda son keyboard va validation state yanada silliqlanadi.'),
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
