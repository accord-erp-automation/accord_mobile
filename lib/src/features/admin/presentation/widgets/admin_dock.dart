import '../../../../app/app_router.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/navigation/profile_route_overlay_notifier.dart';
import '../../../../core/native_dock_bridge.dart';
import '../../../../core/widgets/navigation/app_navigation_bar.dart';
import 'admin_create_hub_sheet.dart';
import 'package:flutter/material.dart';

enum AdminDockTab {
  home,
  suppliers,
  settings,
  activity,
}

class AdminDock extends StatelessWidget {
  const AdminDock({
    super.key,
    required this.activeTab,
    this.compact = true,
    this.tightToEdges = true,
    this.showPrimaryFab = true,
  });

  final AdminDockTab? activeTab;
  final bool compact;
  final bool tightToEdges;
  final bool showPrimaryFab;

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    final homeLabel = l10n?.adminHomeNavTitle ?? 'Uy';
    final usersLabel = l10n?.adminUsersTitle ?? 'Foydalanuvchilar';
    final createLabel = l10n?.adminCreateTitle ?? 'Yangi';
    final activityLabel = l10n?.adminActivityNavTitle ?? 'Faoliyat';
    return AnimatedBuilder(
      animation: Listenable.merge([
        NativeDockBridge.instance,
        ProfileRouteOverlayNotifier.instance,
      ]),
      builder: (context, _) {
        final destinations = _visibleDestinations(
          homeLabel: homeLabel,
          usersLabel: usersLabel,
          createLabel: createLabel,
          activityLabel: activityLabel,
        );
        final effectiveShowPrimaryFab = showPrimaryFab &&
            !ProfileRouteOverlayNotifier.instance.obscuresDockPrimaryFab &&
            destinations.any((destination) => destination.primary);
        final selectedIndex = destinations.indexWhere(
          (destination) => destination.tab == activeTab,
        );
        final bool selectionVisible = selectedIndex >= 0;
        final effectiveSelectedIndex = selectedIndex >= 0 ? selectedIndex : 0;

        return ValueListenableBuilder<bool>(
          valueListenable: adminCreateHubMenuOpen,
          builder: (context, menuOpen, _) {
            void handleSelection(int index) {
              if (index < 0 || index >= destinations.length) {
                return;
              }
              final destination = destinations[index];
              if (destination.primary) {
                showAdminCreateHubSheet(context);
                return;
              }
              final currentRoute = ModalRoute.of(context)?.settings.name;
              if (activeTab == destination.tab &&
                  !(destination.tab == AdminDockTab.home &&
                      currentRoute != AppRoutes.adminHome)) {
                return;
              }
              Navigator.of(context).pushNamedAndRemoveUntil(
                destination.routeName,
                (route) => false,
              );
            }

            final useNativeDock = NativeDockBridge.isSupportedPlatform &&
                NativeDockBridge.instance.supportsSystemDock;
            if (useNativeDock) {
              NativeDockBridge.instance.register(
                NativeDockState(
                  visible: true,
                  compact: compact,
                  tightToEdges: tightToEdges,
                  items: [
                    for (var i = 0; i < destinations.length; i++)
                      if (!destinations[i].primary ||
                          (!menuOpen && effectiveShowPrimaryFab))
                        NativeDockItem(
                          id: destinations[i].id,
                          label: destinations[i].label,
                          iconCodePoint: destinations[i].icon.codePoint,
                          selectedIconCodePoint:
                              destinations[i].selectedIcon.codePoint,
                          active: activeTab == destinations[i].tab,
                          primary: destinations[i].primary,
                          showBadge: false,
                          routeName: destinations[i].primary
                              ? null
                              : destinations[i].routeName,
                          replaceStack: !destinations[i].primary,
                          onTap: () => handleSelection(i),
                        ),
                  ],
                ),
              );
              return const SizedBox.shrink();
            }

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: tightToEdges ? 0 : 8),
              child: AppNavigationBar(
                height: compact ? 60 : 64,
                selectionVisible: selectionVisible,
                selectedIndex: effectiveSelectedIndex,
                primaryVisible: !menuOpen && effectiveShowPrimaryFab,
                destinations: destinations
                    .map(
                      (destination) => AppNavigationDestination(
                        label: destination.label,
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(destination.selectedIcon),
                        isPrimary: destination.primary,
                      ),
                    )
                    .toList(growable: false),
                onDestinationSelected: handleSelection,
              ),
            );
          },
        );
      },
    );
  }
}

class _AdminDockDestination {
  const _AdminDockDestination({
    required this.id,
    required this.tab,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.routeName,
    this.primary = false,
  });

  final String id;
  final AdminDockTab tab;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String routeName;
  final bool primary;
}

List<_AdminDockDestination> _visibleDestinations({
  required String homeLabel,
  required String usersLabel,
  required String createLabel,
  required String activityLabel,
}) {
  final candidates = [
    _AdminDockDestination(
      id: 'admin-home',
      tab: AdminDockTab.home,
      label: homeLabel,
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      routeName: AppRoutes.adminHome,
    ),
    _AdminDockDestination(
      id: 'admin-suppliers',
      tab: AdminDockTab.suppliers,
      label: usersLabel,
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups_rounded,
      routeName: AppRoutes.adminSuppliers,
    ),
    _AdminDockDestination(
      id: 'admin-create',
      tab: AdminDockTab.settings,
      label: createLabel,
      icon: Icons.add_rounded,
      selectedIcon: Icons.add_rounded,
      routeName: AppRoutes.adminCreateHub,
      primary: true,
    ),
    _AdminDockDestination(
      id: 'admin-activity',
      tab: AdminDockTab.activity,
      label: activityLabel,
      icon: Icons.history_outlined,
      selectedIcon: Icons.history_rounded,
      routeName: AppRoutes.adminActivity,
    ),
  ];
  return candidates
      .where((destination) => AppRouter.canOpenRoute(destination.routeName))
      .toList(growable: false);
}
