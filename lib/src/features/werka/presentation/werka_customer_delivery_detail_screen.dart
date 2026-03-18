import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../shared/models/app_models.dart';
import 'widgets/werka_dock.dart';
import 'package:flutter/material.dart';

class WerkaCustomerDeliveryDetailScreen extends StatelessWidget {
  const WerkaCustomerDeliveryDetailScreen({
    super.key,
    required this.record,
  });

  final DispatchRecord record;

  String _statusLabel(AppLocalizations l10n) {
    switch (record.status) {
      case DispatchStatus.accepted:
        return l10n.customerApproved;
      case DispatchStatus.rejected:
        return l10n.customerRejected;
      case DispatchStatus.partial:
        return l10n.partiallyCompleted;
      case DispatchStatus.cancelled:
        return l10n.cancelled;
      case DispatchStatus.pending:
        return l10n.waitingCustomerResponse;
      case DispatchStatus.draft:
        return l10n.draft;
    }
  }

  String _noteText(AppLocalizations l10n) {
    final note = record.note.trim();
    if (note.isNotEmpty) {
      return note;
    }
    if (record.status == DispatchStatus.pending) {
      return l10n.customerShipmentPendingNote();
    }
    return l10n.noExtraNote;
  }

  String _formatQty(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
                      l10n.customerShipmentTitle,
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 0, 12, 110),
                children: [
                  Card.filled(
                    margin: EdgeInsets.zero,
                    color: scheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _WerkaDeliveryField(
                            label: l10n.customerLabel,
                            value: record.supplierName,
                          ),
                          const SizedBox(height: 14),
                          _WerkaDeliveryField(
                            label: l10n.itemLabel,
                            value: '${record.itemCode} • ${record.itemName}',
                          ),
                          const SizedBox(height: 14),
                          _WerkaDeliveryField(
                            label: l10n.pendingStatus,
                            value:
                                '${_formatQty(record.sentQty)} ${record.uom}',
                          ),
                          if (record.acceptedQty > 0) ...[
                            const SizedBox(height: 14),
                            _WerkaDeliveryField(
                              label: l10n.confirmedStatus,
                              value:
                                  '${_formatQty(record.acceptedQty)} ${record.uom}',
                            ),
                          ],
                          const SizedBox(height: 14),
                          _WerkaDeliveryField(
                            label: l10n.statusLabel,
                            value: _statusLabel(l10n),
                          ),
                          const SizedBox(height: 14),
                          _WerkaDeliveryField(
                            label: l10n.dateLabel,
                            value: record.createdLabel,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Card.filled(
                    margin: EdgeInsets.zero,
                    color: scheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.detailsStateTitle,
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _noteText(l10n),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
}

class _WerkaDeliveryField extends StatelessWidget {
  const _WerkaDeliveryField({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.7),
            ),
          ),
          child: Text(
            value,
            style: theme.textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}
