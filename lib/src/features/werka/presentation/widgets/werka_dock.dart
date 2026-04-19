import '../../../../app/app_router.dart';
import '../../../../core/notifications/notification_unread_store.dart';
import '../../../../core/session/app_session.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/logout_prompt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
              label: 'Uy',
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
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.werkaHome,
                  (route) => false,
                );
              },
            ),
            DockButton(
              label: 'Bildirish',
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
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.werkaNotifications,
                  (route) => false,
                );
              },
            ),
          ],
          center: DockButton(
            label: 'Yangi',
            nativeId: 'werka_create',
            nativeSymbol: 'plus',
            nativeSelectedSymbol: 'plus',
            nativeRouteName: AppRoutes.werkaCreateHub,
            icon: Icons.add_rounded,
            selectedIcon: Icons.add_rounded,
            primary: true,
            compact: compact,
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.werkaCreateHub);
            },
          ),
          trailing: [
            DockButton(
              label: 'Arxiv',
              nativeId: 'werka_archive',
              nativeSymbol: 'checklist',
              nativeSelectedSymbol: 'checklist.checked',
              nativeRouteName: AppRoutes.werkaArchive,
              nativeReplaceStack: true,
              iconWidget: const _WerkaDockSvgIcon(),
              selectedIconWidget: const _WerkaDockSvgIcon(),
              active: activeTab == WerkaDockTab.archive,
              compact: compact,
              onTap: () {
                if (activeTab == WerkaDockTab.archive) {
                  return;
                }
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.werkaArchive,
                  (route) => false,
                );
              },
            ),
            DockButton(
              label: 'Profil',
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
                  ? () => showLogoutPrompt(context)
                  : null,
              onTap: () {
                if (activeTab == WerkaDockTab.profile) {
                  return;
                }
                Navigator.of(context).pushNamedAndRemoveUntil(
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

class _WerkaDockSvgIcon extends StatelessWidget {
  const _WerkaDockSvgIcon();

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final color = iconTheme.color ?? Theme.of(context).colorScheme.onSurface;
    final size = (iconTheme.size ?? 24) + 5;
    return SvgPicture.asset(
      'assets/icons/data-check.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(
        color,
        BlendMode.srcIn,
      ),
    );
  }
}
