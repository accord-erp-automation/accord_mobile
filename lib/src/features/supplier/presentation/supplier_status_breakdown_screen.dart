import '../../../app/app_router.dart';
import '../../../core/widgets/app_shell.dart';
import '../../shared/models/app_models.dart';
import '../state/supplier_store.dart';
import 'supplier_status_detail_screen.dart';
import 'widgets/supplier_dock.dart';
import 'package:flutter/material.dart';

class SupplierStatusBreakdownScreen extends StatefulWidget {
  const SupplierStatusBreakdownScreen({
    super.key,
    required this.kind,
  });

  final SupplierStatusKind kind;

  @override
  State<SupplierStatusBreakdownScreen> createState() =>
      _SupplierStatusBreakdownScreenState();
}

class _SupplierStatusBreakdownScreenState
    extends State<SupplierStatusBreakdownScreen> {
  @override
  void initState() {
    super.initState();
    SupplierStore.instance.bootstrapBreakdown(widget.kind);
  }

  Future<void> _reload() async {
    await SupplierStore.instance.refreshBreakdown(widget.kind);
  }

  String get _title {
    switch (widget.kind) {
      case SupplierStatusKind.pending:
        return 'Jarayonda';
      case SupplierStatusKind.submitted:
        return 'Submit';
      case SupplierStatusKind.returned:
        return 'Qaytarilgan';
    }
  }

  String _metricLabel(SupplierStatusBreakdownEntry entry) {
    switch (widget.kind) {
      case SupplierStatusKind.pending:
        return '${entry.totalSentQty.toStringAsFixed(0)} ${entry.uom} jarayonda';
      case SupplierStatusKind.submitted:
        return '${entry.totalAcceptedQty.toStringAsFixed(0)} ${entry.uom} submit';
      case SupplierStatusKind.returned:
        return '${entry.totalReturnedQty.toStringAsFixed(0)} ${entry.uom} qaytarilgan';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: _title,
      subtitle: '',
      leading: AppShellIconAction(
        icon: Icons.arrow_back_rounded,
        onTap: () => Navigator.of(context).maybePop(),
      ),
      bottom: const SupplierDock(activeTab: null),
      child: AnimatedBuilder(
        animation: SupplierStore.instance,
        builder: (context, _) {
          final store = SupplierStore.instance;
          if (store.loadingBreakdown(widget.kind) &&
              store.breakdownItems(widget.kind).isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final error = store.breakdownError(widget.kind);
          if (error != null && store.breakdownItems(widget.kind).isEmpty) {
            return Center(
              child: Card.filled(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text('$error'),
                ),
              ),
            );
          }
          final items = store.breakdownItems(widget.kind);
          if (items.isEmpty) {
            return const Center(child: Text('Hozircha yozuv yo‘q.'));
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Card.filled(
                  margin: EdgeInsets.zero,
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    children: [
                      for (int index = 0; index < items.length; index++) ...[
                        Builder(builder: (context) {
                          final item = items[index];
                          return InkWell(
                            onTap: () => Navigator.of(context).pushNamed(
                              AppRoutes.supplierStatusDetail,
                              arguments: SupplierStatusDetailArgs(
                                kind: widget.kind,
                                itemCode: item.itemCode,
                                itemName: item.itemName,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.itemName,
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _metricLabel(item),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${item.receiptCount} ta receipt',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        if (index != items.length - 1)
                          Divider(
                            height: 1,
                            thickness: 1,
                            indent: 18,
                            endIndent: 18,
                            color: Theme.of(context)
                                .dividerColor
                                .withValues(alpha: 0.55),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
