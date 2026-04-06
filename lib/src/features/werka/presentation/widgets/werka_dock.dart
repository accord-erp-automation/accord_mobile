import '../../../../app/app_router.dart';
import '../../../../core/native_back_button_bridge.dart';
import '../../../../core/notifications/notification_unread_store.dart';
import '../../../../core/session/app_session.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/logout_prompt.dart';
import 'package:flutter/material.dart';

enum WerkaDockTab {
  home,
  notifications,
  archive,
  profile,
}

class WerkaDock extends StatelessWidget {
  const WerkaDock({
    super.key,
    required this.activeTab,
    this.compact = true,
    this.tightToEdges = true,
  });

  final WerkaDockTab? activeTab;
  final bool compact;
  final bool tightToEdges;

  @override
  Widget build(BuildContext context) {
    final navigator = NativeBackButtonBridge.instance.navigatorKey.currentState;
    final navigatorContext =
        NativeBackButtonBridge.instance.navigatorKey.currentContext;
    return AnimatedBuilder(
      animation: NotificationUnreadStore.instance,
      builder: (context, _) {
        final showBadge = NotificationUnreadStore.instance.hasUnreadForProfile(
              AppSession.instance.profile,
            ) &&
            activeTab != WerkaDockTab.notifications;
        return ActionDock(
          compact: compact,
          tightToEdges: tightToEdges,
          leading: [
              DockButton(
                nativeId: 'werka_home',
                nativeSymbol: 'house',
                nativeSelectedSymbol: 'house.fill',
                nativeRouteName: AppRoutes.werkaHome,
                nativeReplaceStack: true,
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                active: activeTab == WerkaDockTab.home,
                compact: compact,
                onTap: () {
                  if (activeTab == WerkaDockTab.home) {
                    return;
                  }
                  navigator?.pushNamedAndRemoveUntil(
                    AppRoutes.werkaHome,
                    (route) => false,
                  );
                },
              ),
              DockButton(
                nativeId: 'werka_notifications',
                nativeSymbol: 'bell',
                nativeSelectedSymbol: 'bell.fill',
                nativeRouteName: AppRoutes.werkaNotifications,
                nativeReplaceStack: true,
                icon: Icons.notifications_outlined,
                selectedIcon: Icons.notifications_rounded,
                active: activeTab == WerkaDockTab.notifications,
                compact: compact,
                showBadge: showBadge,
                onTap: () {
                  if (activeTab == WerkaDockTab.notifications) {
                    return;
                  }
                  navigator?.pushNamedAndRemoveUntil(
                    AppRoutes.werkaNotifications,
                    (route) => false,
                  );
                },
              ),
          ],
          center: DockButton(
              nativeId: 'werka_create',
              nativeSymbol: 'plus',
              nativeSelectedSymbol: 'plus',
              nativeRouteName: AppRoutes.werkaCreateHub,
              icon: Icons.add_rounded,
              selectedIcon: Icons.add_rounded,
              primary: true,
              compact: compact,
              onTap: () {
                navigator?.pushNamed(AppRoutes.werkaCreateHub);
              },
            ),
          trailing: [
              DockButton(
                nativeId: 'werka_archive',
                nativeSymbol: 'archivebox',
                nativeSelectedSymbol: 'archivebox.fill',
                nativeRouteName: AppRoutes.werkaArchive,
                nativeReplaceStack: true,
                icon: Icons.archive_outlined,
                selectedIcon: Icons.archive_rounded,
                active: activeTab == WerkaDockTab.archive,
                compact: compact,
                onTap: () {
                  if (activeTab == WerkaDockTab.archive) {
                    return;
                  }
                  navigator?.pushNamedAndRemoveUntil(
                    AppRoutes.werkaArchive,
                    (route) => false,
                  );
                },
              ),
              DockButton(
                nativeId: 'werka_profile',
                nativeSymbol: 'person.crop.circle',
                nativeSelectedSymbol: 'person.crop.circle.fill',
                nativeRouteName: AppRoutes.profile,
                nativeReplaceStack: true,
                icon: Icons.account_circle_outlined,
                selectedIcon: Icons.account_circle_rounded,
                active: activeTab == WerkaDockTab.profile,
                compact: compact,
                onHoldComplete: activeTab == WerkaDockTab.profile
                    ? navigatorContext == null
                        ? null
                        : () => showLogoutPrompt(navigatorContext)
                    : null,
                onTap: () {
                  if (activeTab == WerkaDockTab.profile) {
                    return;
                  }
                  navigator?.pushNamedAndRemoveUntil(
                    AppRoutes.profile,
                    (route) => false,
                  );
                },
              ),
          ],
        );
      },
    );
  }
}
