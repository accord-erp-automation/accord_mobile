import '../../../app/app_router.dart';
import '../../../core/widgets/app_shell.dart';
import '../../shared/models/app_models.dart';
import 'widgets/werka_dock.dart';
import 'package:flutter/material.dart';

class WerkaSuccessScreen extends StatelessWidget {
  const WerkaSuccessScreen({
    super.key,
    required this.record,
  });

  final DispatchRecord record;

  String get _title {
    if (record.eventType == 'customer_issue_pending') {
      return 'Jo‘natildi';
    }
    if (record.eventType == 'werka_unannounced_pending') {
      return 'Qayd qilindi';
    }
    return 'Qabul qilindi';
  }

  String get _subtitleLine {
    if (record.eventType == 'customer_issue_pending') {
      return '${record.sentQty.toStringAsFixed(2)} ${record.uom} customerga jo‘natildi';
    }
    if (record.eventType == 'werka_unannounced_pending') {
      return '${record.sentQty.toStringAsFixed(2)} ${record.uom} qayd qilindi';
    }
    return '${record.acceptedQty.toStringAsFixed(2)} ${record.uom} qabul qilindi';
  }

  bool get _returnsToCreateHub {
    return record.eventType == 'customer_issue_pending' ||
        record.eventType == 'werka_unannounced_pending';
  }

  String get _ctaLabel {
    return _returnsToCreateHub ? 'Qaydga qaytish' : 'Pending listga qaytish';
  }

  String get _targetRoute {
    return _returnsToCreateHub ? AppRoutes.werkaCreateHub : AppRoutes.werkaHome;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppShell(
      title: _title,
      subtitle: '',
      contentPadding: const EdgeInsets.fromLTRB(12, 0, 14, 0),
      bottom: const WerkaDock(activeTab: null),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 140),
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
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 88,
                    width: 88,
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.verified_rounded,
                      size: 44,
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    record.id,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _subtitleLine,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                _targetRoute,
                (route) => route.isFirst,
              ),
              child: Text(_ctaLabel),
            ),
          ),
        ],
      ),
    );
  }
}
