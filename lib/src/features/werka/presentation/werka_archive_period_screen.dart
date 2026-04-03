import '../../../app/app_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/native_back_button.dart';
import '../../shared/models/app_models.dart';
import 'werka_archive_list_screen.dart';
import 'widgets/werka_dock.dart';
import 'package:flutter/material.dart';

class WerkaArchivePeriodScreen extends StatelessWidget {
  const WerkaArchivePeriodScreen({
    super.key,
    required this.kind,
  });

  final WerkaArchiveKind kind;

  String _kindTitle(AppLocalizations l10n) {
    switch (kind) {
      case WerkaArchiveKind.received:
        return l10n.archiveReceivedTitle;
      case WerkaArchiveKind.sent:
        return l10n.archiveSentTitle;
      case WerkaArchiveKind.returned:
        return l10n.archiveReturnedTitle;
    }
  }

  @override
  Widget build(BuildContext context) {
    useNativeNavigationTitle(context, _kindTitle(context.l10n));
    return AppShell(
      title: _kindTitle(context.l10n),
      subtitle: context.l10n.archiveChoosePeriod,
      leading: NativeBackButtonSlot(
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      bottom: const WerkaDock(activeTab: null),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 110),
        children: [
          _PeriodCard(
            title: context.l10n.archiveDailyTitle,
            onTap: () => _openList(context, WerkaArchivePeriod.daily),
          ),
          const SizedBox(height: 14),
          _PeriodCard(
            title: context.l10n.archiveMonthlyTitle,
            onTap: () => _openList(context, WerkaArchivePeriod.monthly),
          ),
          const SizedBox(height: 14),
          _PeriodCard(
            title: context.l10n.archiveYearlyTitle,
            onTap: () => _openList(context, WerkaArchivePeriod.yearly),
          ),
        ],
      ),
    );
  }

  void _openList(BuildContext context, WerkaArchivePeriod period) {
    Navigator.of(context).pushNamed(
      AppRoutes.werkaArchiveList,
      arguments: WerkaArchiveListArgs(
        kind: kind,
        period: period,
      ),
    );
  }
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({
    required this.title,
    required this.onTap,
  });

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card.filled(
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
