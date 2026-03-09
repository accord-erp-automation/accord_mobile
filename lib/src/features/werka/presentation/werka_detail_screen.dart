import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../shared/models/app_models.dart';
import 'package:flutter/material.dart';

class WerkaDetailScreen extends StatefulWidget {
  const WerkaDetailScreen({
    super.key,
    required this.record,
  });

  final DispatchRecord record;

  @override
  State<WerkaDetailScreen> createState() => _WerkaDetailScreenState();
}

class _WerkaDetailScreenState extends State<WerkaDetailScreen> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller =
        TextEditingController(text: widget.record.sentQty.toStringAsFixed(0));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Qabul qilish',
      subtitle: 'Real qabul qilingan miqdorni kiriting.',
      child: Column(
        children: [
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(label: 'Supplier', value: widget.record.supplierName),
                _InfoRow(
                    label: 'Mahsulot',
                    value:
                        '${widget.record.itemCode} • ${widget.record.itemName}'),
                _InfoRow(
                    label: 'Jo‘natilgan',
                    value:
                        '${widget.record.sentQty.toStringAsFixed(2)} ${widget.record.uom}'),
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
              suffixText: widget.record.uom,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final double qty = double.tryParse(controller.text.trim()) ?? 0;
                final DispatchRecord accepted =
                    await MobileApi.instance.confirmReceipt(
                  receiptID: widget.record.id,
                  acceptedQty: qty,
                );
                if (!context.mounted) {
                  return;
                }
                Navigator.of(context)
                    .pushNamed(AppRoutes.werkaSuccess, arguments: accepted);
              },
              child: const Text('Qabul qilishni yakunlash'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
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
