import '../../../core/localization/app_localizations.dart';
import '../../../app/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/native_back_button.dart'
    show useNativeNavigationTitle;
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
    final detailRows = <({String label, String value})>[
      (label: l10n.itemLabel, value: record.itemName),
      (
        label: l10n.pendingStatus,
        value: '${_formatQty(record.sentQty)} ${record.uom}',
      ),
      if (record.acceptedQty > 0)
        (
          label: l10n.confirmedStatus,
          value: '${_formatQty(record.acceptedQty)} ${record.uom}',
        ),
      (label: l10n.statusLabel, value: _statusLabel(l10n)),
      (label: l10n.dateLabel, value: record.createdLabel),
    ];
    useNativeNavigationTitle(context, l10n.customerShipmentTitle);
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom + 136.0;
    return AppShell(
      title: l10n.customerShipmentTitle,
      subtitle: '',
      nativeTopBar: true,
      nativeTitleTextStyle: AppTheme.werkaNativeAppBarTitleStyle(context),
      bottom: const WerkaDock(activeTab: null),
      contentPadding: EdgeInsets.zero,
      child: ListView(
        padding: EdgeInsets.fromLTRB(10, 4, 12, bottomPadding),
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    record.supplierName,
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _statusLabel(l10n),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSecondaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                for (int index = 0; index < detailRows.length; index++) ...[
                  _WerkaDeliveryInfoRow(
                    label: detailRows[index].label,
                    value: detailRows[index].value,
                    isFirst: index == 0,
                    isLast: index == detailRows.length - 1,
                  ),
                  if (index != detailRows.length - 1)
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 12,
                      endIndent: 12,
                      color: scheme.outlineVariant.withValues(alpha: 0.55),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
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
          if (record.status == DispatchStatus.accepted ||
              record.status == DispatchStatus.rejected) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pushNamed(
                  AppRoutes.notificationDetail,
                  arguments: customerDeliveryResultEventId(record.id),
                ),
                child: Text(l10n.openDiscussionAction),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WerkaDeliveryInfoRow extends StatelessWidget {
  const _WerkaDeliveryInfoRow({
    required this.label,
    required this.value,
    required this.isFirst,
    required this.isLast,
  });

  final String label;
  final String value;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isFirst ? 24 : 0),
          topRight: Radius.circular(isFirst ? 24 : 0),
          bottomLeft: Radius.circular(isLast ? 24 : 0),
          bottomRight: Radius.circular(isLast ? 24 : 0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.topEnd,
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: theme.textTheme.titleMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
