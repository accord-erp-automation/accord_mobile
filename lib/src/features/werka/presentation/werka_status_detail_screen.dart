import '../../../app/app_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_shell.dart';
import '../../shared/models/app_models.dart';
import '../state/werka_store.dart';
import 'werka_status_breakdown_screen.dart';
import 'widgets/werka_dock.dart';
import 'package:flutter/material.dart';

class WerkaStatusDetailScreen extends StatefulWidget {
  const WerkaStatusDetailScreen({
    super.key,
    required this.args,
  });

  final WerkaStatusDetailArgs args;

  @override
  State<WerkaStatusDetailScreen> createState() =>
      _WerkaStatusDetailScreenState();
}

class _WerkaStatusDetailScreenState extends State<WerkaStatusDetailScreen> {
  @override
  void initState() {
    super.initState();
    WerkaStore.instance
        .bootstrapDetail(widget.args.kind, widget.args.supplierRef);
  }

  Future<void> _reload() async {
    await WerkaStore.instance
        .refreshDetail(widget.args.kind, widget.args.supplierRef);
  }

  String get _title {
    final l10n = context.l10n;
    switch (widget.args.kind) {
      case WerkaStatusKind.pending:
        return l10n.statusWithName(
            widget.args.supplierName, l10n.pendingStatus);
      case WerkaStatusKind.confirmed:
        return l10n.statusWithName(
            widget.args.supplierName, l10n.confirmedStatus);
      case WerkaStatusKind.returned:
        return l10n.statusWithName(
            widget.args.supplierName, l10n.returnedStatus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      extendBody: true,
      backgroundColor: AppTheme.shellStart(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Row(
                children: [
                  SizedBox(
                    height: 52,
                    width: 52,
                    child: IconButton.filledTonal(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded, size: 28),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _title,
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 16, 0),
                child: AnimatedBuilder(
                  animation: WerkaStore.instance,
                  builder: (context, _) {
                    final store = WerkaStore.instance;
                    if (store.loadingDetail(
                            widget.args.kind, widget.args.supplierRef) &&
                        store
                            .detailItems(
                                widget.args.kind, widget.args.supplierRef)
                            .isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final error = store.detailError(
                        widget.args.kind, widget.args.supplierRef);
                    if (error != null &&
                        store
                            .detailItems(
                                widget.args.kind, widget.args.supplierRef)
                            .isEmpty) {
                      return Center(
                        child: Card.filled(
                          margin: EdgeInsets.zero,
                          color: scheme.surfaceContainerLow,
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(context.l10n
                                    .recordsLoadFailedWith(error)),
                                const SizedBox(height: 12),
                                FilledButton(
                                  onPressed: _reload,
                                  child: Text(context.l10n.retry),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    final items = store.detailItems(
                        widget.args.kind, widget.args.supplierRef);
                    if (items.isEmpty) {
                      return Center(
                        child: Card.filled(
                          margin: EdgeInsets.zero,
                          color: scheme.surfaceContainerLow,
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Text(
                              context.l10n.noRecordsYet,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                        ),
                      );
                    }

                    return AppRefreshIndicator(
                      onRefresh: _reload,
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 110),
                        children: [
                          for (int index = 0; index < items.length; index++) ...[
                            _WerkaStatusRecordCard(
                              record: items[index],
                              onTap: () => _openRecord(items[index]),
                            ),
                            if (index != items.length - 1)
                              const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: WerkaDock(activeTab: null),
        ),
      ),
    );
  }

  void _openRecord(DispatchRecord record) {
    if (record.isDeliveryNote) {
      Navigator.of(context).pushNamed(
        AppRoutes.werkaCustomerDeliveryDetail,
        arguments: record,
      );
      return;
    }
    if (widget.args.kind == WerkaStatusKind.pending) {
      Navigator.of(context)
          .pushNamed(
        AppRoutes.werkaDetail,
        arguments: record,
      )
          .then((_) {
        if (!mounted) {
          return;
        }
        _reload();
      });
      return;
    }
    Navigator.of(context).pushNamed(
      AppRoutes.notificationDetail,
      arguments: record.id,
    );
  }
}

class _WerkaStatusRecordCard extends StatelessWidget {
  const _WerkaStatusRecordCard({
    required this.record,
    required this.onTap,
  });

  final DispatchRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(28),
    );
    return Card.filled(
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      record.itemName.trim().isEmpty
                          ? record.itemCode
                          : record.itemName,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    record.createdLabel,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${record.sentQty.toStringAsFixed(0)} ${record.uom}',
                style: theme.textTheme.headlineMedium,
              ),
              if (record.acceptedQty > 0) ...[
                const SizedBox(height: 6),
                Text(
                  context.l10n.acceptedQtyLabel(
                    record.acceptedQty,
                    record.uom,
                  ),
                  style: theme.textTheme.bodySmall,
                ),
              ],
              if (record.note.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  record.note,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
