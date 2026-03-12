import '../../../app/app_router.dart';
import '../../../core/widgets/app_shell.dart';
import '../../shared/models/app_models.dart';
import 'werka_unannounced_confirm_screen.dart';
import 'widgets/werka_dock.dart';
import 'package:flutter/material.dart';

class WerkaUnannouncedQtyArgs {
  const WerkaUnannouncedQtyArgs({
    required this.supplier,
    required this.item,
  });

  final SupplierDirectoryEntry supplier;
  final SupplierItem item;
}

class WerkaUnannouncedQtyScreen extends StatefulWidget {
  const WerkaUnannouncedQtyScreen({
    super.key,
    required this.args,
  });

  final WerkaUnannouncedQtyArgs args;

  @override
  State<WerkaUnannouncedQtyScreen> createState() => _WerkaUnannouncedQtyScreenState();
}

class _WerkaUnannouncedQtyScreenState extends State<WerkaUnannouncedQtyScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Miqdor kiriting',
      subtitle: widget.args.item.name,
      leading: AppShellIconAction(
        icon: Icons.arrow_back_rounded,
        onTap: () => Navigator.of(context).maybePop(),
      ),
      bottom: const WerkaDock(activeTab: null),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: '0',
              suffixText: widget.args.item.uom,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              final qty = double.tryParse(_controller.text.trim()) ?? 0;
              if (qty <= 0) {
                return;
              }
              Navigator.of(context).pushNamed(
                AppRoutes.werkaUnannouncedConfirm,
                arguments: WerkaUnannouncedConfirmArgs(
                  supplier: widget.args.supplier,
                  item: widget.args.item,
                  qty: qty,
                ),
              );
            },
            child: const Text('Keyingi'),
          ),
        ],
      ),
    );
  }
}
