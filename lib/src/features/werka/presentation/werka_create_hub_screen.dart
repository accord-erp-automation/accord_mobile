import '../../../app/app_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/app_shell.dart';
import 'widgets/werka_dock.dart';
import 'package:flutter/material.dart';

class WerkaCreateHubScreen extends StatelessWidget {
  const WerkaCreateHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppShell(
      title: l10n.createHubTitle,
      subtitle: '',
      bottom: const WerkaDock(activeTab: null),
      contentPadding: const EdgeInsets.fromLTRB(10, 0, 12, 0),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Card.filled(
              margin: EdgeInsets.zero,
              color: scheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.7),
                ),
              ),
              child: Column(
                children: [
                  InkWell(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                    onTap: () => Navigator.of(context).pushNamed(
                      AppRoutes.werkaUnannouncedSupplier,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 20,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.unannouncedTitle,
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.unannouncedDescription,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1, thickness: 1),
                  InkWell(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                    onTap: () => Navigator.of(context).pushNamed(
                      AppRoutes.werkaCustomerIssueCustomer,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 20,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.customerIssueTitle,
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.customerIssueDescription,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
