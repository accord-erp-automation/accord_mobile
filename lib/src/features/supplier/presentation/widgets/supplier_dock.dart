import '../../../../app/app_router.dart';
import '../../../../core/native_back_button_bridge.dart';
import '../../../../core/notifications/notification_unread_store.dart';
import '../../../../core/session/app_session.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/logout_prompt.dart';
import 'package:flutter/material.dart';

enum SupplierDockTab {
  home,
  notifications,
  recent,
  profile,
}

class SupplierDock extends StatelessWidget {
  const SupplierDock({
    super.key,
    required this.activeTab,
    this.centerActive = false,
    this.compact = true,
    this.tightToEdges = true,
  });

  final SupplierDockTab? activeTab;
  final bool centerActive;
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
            activeTab != SupplierDockTab.notifications;
        return ActionDock(
          compact: compact,
          tightToEdges: tightToEdges,
          leading: [
            DockButton(
              nativeId: 'supplier_home',
              nativeSymbol: 'house',
              nativeSelectedSymbol: 'house.fill',
              nativeRouteName: AppRoutes.supplierHome,
              nativeReplaceStack: true,
              icon: Icons.home_outlined,
              selectedIcon: Icons.home_rounded,
              active: activeTab == SupplierDockTab.home,
              compact: compact,
              onTap: () {
                if (activeTab == SupplierDockTab.home && !centerActive) {
                  return;
                }
                navigator?.pushNamedAndRemoveUntil(
                  AppRoutes.supplierHome,
                  (route) => false,
                );
              },
            ),
            DockButton(
              nativeId: 'supplier_notifications',
              nativeSymbol: 'bell',
              nativeSelectedSymbol: 'bell.fill',
              nativeRouteName: AppRoutes.supplierNotifications,
              nativeReplaceStack: true,
              icon: Icons.notifications_outlined,
              selectedIcon: Icons.notifications_rounded,
              active: activeTab == SupplierDockTab.notifications,
              compact: compact,
              showBadge: showBadge,
              onTap: () {
                if (activeTab == SupplierDockTab.notifications) {
                  return;
                }
                navigator?.pushNamedAndRemoveUntil(
                  AppRoutes.supplierNotifications,
                  (route) => false,
                );
              },
            ),
          ],
          center: DockButton(
            nativeId: 'supplier_create',
            nativeSymbol: 'plus',
            nativeSelectedSymbol: 'plus',
            nativeRouteName: AppRoutes.supplierItemPicker,
            icon: Icons.add_rounded,
            selectedIcon: Icons.add_rounded,
            primary: true,
            compact: compact,
              onTap: () {
                if (centerActive) {
                  return;
                }
                navigator?.pushNamed(AppRoutes.supplierItemPicker);
              },
            ),
          trailing: [
            DockButton(
              nativeId: 'supplier_recent',
              nativeSymbol: 'clock',
              nativeSelectedSymbol: 'clock.fill',
              nativeRouteName: AppRoutes.supplierRecent,
              nativeReplaceStack: true,
              icon: Icons.history_outlined,
              selectedIcon: Icons.history_rounded,
              active: activeTab == SupplierDockTab.recent,
              compact: compact,
              onTap: () {
                if (activeTab == SupplierDockTab.recent) {
                  return;
                }
                navigator?.pushNamedAndRemoveUntil(
                  AppRoutes.supplierRecent,
                  (route) => false,
                );
              },
            ),
            DockButton(
              nativeId: 'supplier_profile',
              nativeSymbol: 'person.crop.circle',
              nativeSelectedSymbol: 'person.crop.circle.fill',
              nativeRouteName: AppRoutes.profile,
              nativeReplaceStack: true,
              icon: Icons.account_circle_outlined,
              selectedIcon: Icons.account_circle_rounded,
                active: activeTab == SupplierDockTab.profile,
                compact: compact,
                onHoldComplete: activeTab == SupplierDockTab.profile
                    ? navigatorContext == null
                        ? null
                        : () => showLogoutPrompt(navigatorContext)
                    : null,
                onTap: () {
                  if (activeTab == SupplierDockTab.profile) {
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
