import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/widgets/app_shell.dart';
import '../../shared/models/app_models.dart';
import 'widgets/werka_dock.dart';
import 'package:flutter/material.dart';

class WerkaUnannouncedConfirmArgs {
  const WerkaUnannouncedConfirmArgs({
    required this.supplier,
    required this.item,
    required this.qty,
  });

  final SupplierDirectoryEntry supplier;
  final SupplierItem item;
  final double qty;
}

class WerkaUnannouncedConfirmScreen extends StatefulWidget {
  const WerkaUnannouncedConfirmScreen({
    super.key,
    required this.args,
  });

  final WerkaUnannouncedConfirmArgs args;

  @override
  State<WerkaUnannouncedConfirmScreen> createState() => _WerkaUnannouncedConfirmScreenState();
}

class _WerkaUnannouncedConfirmScreenState extends State<WerkaUnannouncedConfirmScreen> {
  bool _saving = false;

  Future<void> _submit() async {
    final first = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tasdiqlash'),
        content: const Text('Haqiqatan ham davom etasizmi?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Yo‘q')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Ha')),
        ],
      ),
    );
    if (first != true) return;
    if (!mounted) return;
    final second = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Yakuniy tasdiq'),
        content: const Text('Draft ochilsinmi?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Yo‘q')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Ha')),
        ],
      ),
    );
    if (second != true) return;
    setState(() => _saving = true);
    try {
      final record = await MobileApi.instance.createWerkaUnannouncedDraft(
        supplierRef: widget.args.supplier.ref,
        itemCode: widget.args.item.code,
        qty: widget.args.qty,
      );
      if (!mounted) return;
      final navigator = Navigator.of(context);
      navigator.pushNamedAndRemoveUntil(
        AppRoutes.werkaSuccess,
        (route) => route.isFirst,
        arguments: record,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Tasdiqlash',
      subtitle: '',
      leading: AppShellIconAction(
        icon: Icons.arrow_back_rounded,
        onTap: () => Navigator.of(context).maybePop(),
      ),
      bottom: const WerkaDock(activeTab: null),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Text('Supplier: ${widget.args.supplier.name}'),
          const SizedBox(height: 8),
          Text('Mahsulot: ${widget.args.item.name}'),
          const SizedBox(height: 8),
          Text('Miqdor: ${widget.args.qty.toStringAsFixed(2)} ${widget.args.item.uom}'),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: Text(_saving ? 'Saqlanmoqda...' : 'Tasdiqlash'),
          ),
        ],
      ),
    );
  }
}
