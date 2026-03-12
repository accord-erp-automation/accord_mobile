import '../../../app/app_router.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/common_widgets.dart';
import 'widgets/werka_dock.dart';
import 'package:flutter/material.dart';

class WerkaCreateHubScreen extends StatelessWidget {
  const WerkaCreateHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Qayd',
      subtitle: '',
      leading: AppShellIconAction(
        icon: Icons.arrow_back_rounded,
        onTap: () => Navigator.of(context).maybePop(),
      ),
      bottom: const WerkaDock(activeTab: null),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => Navigator.of(context).pushNamed(
              AppRoutes.werkaUnannouncedSupplier,
            ),
            child: const SoftCard(
              child: Text('Aytilmagan mol'),
            ),
          ),
        ],
      ),
    );
  }
}
