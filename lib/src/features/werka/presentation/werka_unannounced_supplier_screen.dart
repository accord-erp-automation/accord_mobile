import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/notifications/werka_runtime_store.dart';
import '../../../core/search/search_normalizer.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/models/app_models.dart';
import 'widgets/m3_picker_sheet.dart';
import 'widgets/werka_dock.dart';
import 'dart:async';

import 'package:flutter/material.dart';

class WerkaUnannouncedSupplierScreen extends StatefulWidget {
  const WerkaUnannouncedSupplierScreen({
    super.key,
    this.prefill,
  });

  final WerkaUnannouncedPrefillArgs? prefill;

  @override
  State<WerkaUnannouncedSupplierScreen> createState() =>
      _WerkaUnannouncedSupplierScreenState();
}

class _WerkaUnannouncedSupplierScreenState
    extends State<WerkaUnannouncedSupplierScreen> {
  late Future<List<SupplierDirectoryEntry>> _suppliersFuture;
  final TextEditingController _qtyController = TextEditingController(text: '1');

  SupplierDirectoryEntry? _selectedSupplier;
  SupplierItem? _selectedItem;
  List<SupplierItem> _supplierItems = const <SupplierItem>[];
  bool _loadingItems = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _suppliersFuture = MobileApi.instance.werkaSuppliers();
    if (widget.prefill != null) {
      _applyPrefill(widget.prefill!);
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  Future<void> _reloadSuppliers() async {
    final future = MobileApi.instance.werkaSuppliers();
    setState(() => _suppliersFuture = future);
    await future;
  }

  Future<void> _applyPrefill(WerkaUnannouncedPrefillArgs prefill) async {
    setState(() {
      _selectedSupplier = SupplierDirectoryEntry(
        ref: prefill.supplierRef,
        name: prefill.supplierName,
        phone: '',
      );
      _selectedItem = null;
      _supplierItems = const <SupplierItem>[];
      _loadingItems = true;
      _qtyController.text = _formatQty(prefill.qty);
    });
    try {
      final items = await MobileApi.instance.werkaSupplierItems(
        supplierRef: prefill.supplierRef,
      );
      if (!mounted) {
        return;
      }
      final selected = items.cast<SupplierItem?>().firstWhere(
                (item) => item?.code == prefill.itemCode,
                orElse: () => null,
              ) ??
          SupplierItem(
            code: prefill.itemCode,
            name: prefill.itemName,
            uom: prefill.uom,
            warehouse: '',
          );
      setState(() {
        _supplierItems = items;
        _selectedItem = selected;
      });
    } finally {
      if (mounted) {
        setState(() => _loadingItems = false);
      }
    }
  }

  String _formatQty(double qty) {
    if (qty == qty.roundToDouble()) {
      return qty.toStringAsFixed(0);
    }
    return qty
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  Future<void> _pickSupplier() async {
    final suppliers = await _suppliersFuture;
    if (!mounted) {
      return;
    }
    final picked = await showModalBottomSheet<SupplierDirectoryEntry>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: kM3PickerSheetAnimation,
      builder: (context) {
        return M3PickerSheet<SupplierDirectoryEntry>(
          title: context.l10n.selectSupplier,
          hintText: context.l10n.searchSupplier,
          items: suppliers,
          itemTitle: (item) => item.name,
          itemSubtitle: (_) => '',
          matchesQuery: (item, query) {
            return searchMatches(query, [
              item.name,
              item.phone,
              item.ref,
            ]);
          },
          onSelected: (item) => Navigator.of(context).pop(item),
        );
      },
    );
    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _selectedSupplier = picked;
      _selectedItem = null;
      _supplierItems = const <SupplierItem>[];
      _loadingItems = true;
    });
    try {
      final items = await MobileApi.instance.werkaSupplierItems(
        supplierRef: picked.ref,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _supplierItems = items;
      });
    } finally {
      if (mounted) {
        setState(() => _loadingItems = false);
      }
    }
  }

  Future<void> _pickItem() async {
    if (_selectedSupplier == null || _loadingItems) {
      return;
    }
    if (_supplierItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.noRecordsYet)),
      );
      return;
    }

    final picked = await showModalBottomSheet<SupplierItem>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: kM3PickerSheetAnimation,
      builder: (context) {
        return M3PickerSheet<SupplierItem>(
          title: context.l10n.selectItem,
          supportingText: _selectedSupplier!.name,
          hintText: context.l10n.searchItem,
          items: _supplierItems,
          itemTitle: (item) => item.name,
          itemSubtitle: (_) => '',
          matchesQuery: (item, query) {
            return searchMatches(query, [
              item.name,
              item.code,
            ]);
          },
          onSelected: (item) => Navigator.of(context).pop(item),
        );
      },
    );
    if (!mounted || picked == null) {
      return;
    }
    setState(() => _selectedItem = picked);
  }

  Future<void> _submit() async {
    if (_selectedSupplier == null || _selectedItem == null) {
      return;
    }
    final qty = double.tryParse(_qtyController.text.trim()) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.qtyRequired)),
      );
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.confirmTitle,
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 18),
                Text(
                  _selectedSupplier!.name,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  _selectedItem!.name,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  '${qty.toStringAsFixed(0)} ${_selectedItem!.uom}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(context.l10n.no),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(context.l10n.yes),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (confirmed != true) {
      return;
    }

    setState(() => _submitting = true);
    try {
      final record = await MobileApi.instance.createWerkaUnannouncedDraft(
        supplierRef: _selectedSupplier!.ref,
        itemCode: _selectedItem!.code,
        qty: qty,
      );
      WerkaRuntimeStore.instance.recordCreatedPending(record);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.werkaSuccess,
        (route) => route.isFirst,
        arguments: record,
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final canPickItem = _selectedSupplier != null && !_loadingItems;
    final canSubmit = _selectedSupplier != null &&
        _selectedItem != null &&
        !_submitting &&
        !_loadingItems;

    return Scaffold(
      backgroundColor: AppTheme.shellStart(context),
      body: SafeArea(
        child: FutureBuilder<List<SupplierDirectoryEntry>>(
          future: _suppliersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                children: [
                  _WerkaUnannouncedHeader(theme: theme),
                  const SizedBox(height: 20),
                  Card.filled(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(context.l10n
                              .unannouncedSuppliersFailed(snapshot.error!)),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _reloadSuppliers,
                            child: Text(context.l10n.retry),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              children: [
                _WerkaUnannouncedHeader(theme: theme),
                const SizedBox(height: 20),
                Card.filled(
                  margin: EdgeInsets.zero,
                  color: scheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                    side: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.7),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.unannouncedTitle,
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 18),
                        Text(context.l10n.supplierLabel,
                            style: theme.textTheme.bodySmall),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _pickSupplier,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _selectedSupplier?.name ??
                                    context.l10n.selectSupplier,
                              ),
                            ),
                          ),
                        ),
                        if (_selectedSupplier != null) ...[
                          const SizedBox(height: 14),
                          Text(context.l10n.itemLabel,
                              style: theme.textTheme.bodySmall),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: canPickItem ? _pickItem : null,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _loadingItems
                                      ? context.l10n.loading
                                      : _selectedItem?.name ??
                                          context.l10n.selectItem,
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (_selectedItem != null) ...[
                          const SizedBox(height: 14),
                          Text(context.l10n.amountLabel,
                              style: theme.textTheme.bodySmall),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _qtyController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              hintText: '0',
                              suffixText: _selectedItem!.uom,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: canSubmit ? _submit : null,
                            child: Text(
                              _submitting
                                  ? context.l10n.pinSaving
                                  : context.l10n.confirmTitle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
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
}

class WerkaUnannouncedPrefillArgs {
  const WerkaUnannouncedPrefillArgs({
    required this.supplierRef,
    required this.supplierName,
    required this.itemCode,
    required this.itemName,
    required this.qty,
    required this.uom,
  });

  final String supplierRef;
  final String supplierName;
  final String itemCode;
  final String itemName;
  final double qty;
  final String uom;
}

class _WerkaUnannouncedHeader extends StatelessWidget {
  const _WerkaUnannouncedHeader({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
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
            context.l10n.unannouncedTitle,
            style: theme.textTheme.headlineMedium,
          ),
        ),
      ],
    );
  }
}
