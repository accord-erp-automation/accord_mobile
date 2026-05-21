import '../../../core/api/mobile_api.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/display/motion_widgets.dart';
import '../../../core/widgets/lists/m3_segmented_list.dart';
import '../../../core/widgets/scroll/top_refresh_scroll_physics.dart';
import '../../../core/widgets/shell/app_loading_indicator.dart';
import '../../../core/widgets/shell/app_retry_state.dart';
import '../../../core/widgets/shell/app_shell.dart';
import '../../shared/models/app_models.dart';
import 'widgets/admin_dock.dart';
import 'widgets/admin_navigation_drawer.dart';
import 'widgets/admin_top_notice.dart';
import 'package:flutter/material.dart';

class AdminRolesScreen extends StatefulWidget {
  const AdminRolesScreen({super.key});

  @override
  State<AdminRolesScreen> createState() => _AdminRolesScreenState();
}

class _AdminRolesScreenState extends State<AdminRolesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late Future<_AdminRolesData> _future;
  bool _openingRoute = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _future = _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<_AdminRolesData> _load() async {
    final results = await Future.wait<Object>([
      MobileApi.instance.adminCapabilities(),
      MobileApi.instance.adminRoles(),
      MobileApi.instance.adminRoleAssignments(),
      MobileApi.instance.adminSettings(),
      MobileApi.instance.adminSuppliers(limit: 100),
      MobileApi.instance.adminCustomers(limit: 100),
    ]);
    return _AdminRolesData(
      capabilities: results[0] as List<AdminCapability>,
      roles: results[1] as List<AdminRoleDefinition>,
      assignments: results[2] as List<AdminRoleAssignment>,
      settings: results[3] as AdminSettings,
      suppliers: results[4] as List<AdminSupplier>,
      customers: results[5] as List<CustomerDirectoryEntry>,
    );
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  void _openDrawerRoute(String routeName) {
    if (_openingRoute) {
      return;
    }
    final current = ModalRoute.of(context)?.settings.name;
    if (current == routeName) {
      return;
    }
    _openingRoute = true;
    Navigator.of(context).pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
    );
  }

  Future<void> _openRoleEditor(_AdminRolesData data) async {
    final role = await showModalBottomSheet<AdminRoleDefinition>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _AdminRoleEditorSheet(data: data),
    );
    if (role == null || !mounted) {
      return;
    }
    try {
      final saved = await MobileApi.instance.adminUpsertRole(role);
      if (!mounted) {
        return;
      }
      setState(() {
        _future = Future<_AdminRolesData>.value(data.upsertRole(saved));
      });
      showAdminTopNotice(
        context,
        context.l10n.adminRoleSaved,
        icon: Icons.verified_user,
      );
    } catch (_) {
      if (mounted) {
        showAdminTopNotice(
          context,
          context.l10n.adminRoleSaveFailed,
          icon: Icons.error,
        );
      }
    }
  }

  Future<void> _assignRole(
    _AdminRolesData data,
    _RolePrincipal principal,
  ) async {
    final assignment = await showModalBottomSheet<AdminRoleAssignment>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        return _RoleAssignmentSheet(principal: principal, roles: data.roles);
      },
    );
    if (assignment == null || !mounted) {
      return;
    }
    try {
      final saved = await MobileApi.instance.adminUpsertRoleAssignment(
        assignment,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _future = Future<_AdminRolesData>.value(data.upsertAssignment(saved));
      });
      showAdminTopNotice(
        context,
        context.l10n.adminRoleAssigned,
        icon: Icons.assignment_turned_in_outlined,
      );
    } catch (_) {
      if (mounted) {
        showAdminTopNotice(
          context,
          context.l10n.adminRoleAssignFailed,
          icon: Icons.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom + 136.0;
    return AppShell(
      drawer: AdminNavigationDrawer(
        selectedIndex: 3,
        onNavigate: _openDrawerRoute,
      ),
      title: context.l10n.adminRolesTitle,
      subtitle: '',
      nativeTopBar: true,
      nativeTitleTextStyle: AppTheme.werkaNativeAppBarTitleStyle(context),
      bottom: const AdminDock(activeTab: AdminDockTab.settings),
      bottomDockFadeStrength: null,
      contentPadding: EdgeInsets.zero,
      child: FutureBuilder<_AdminRolesData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: AppLoadingIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return AppRetryState(onRetry: _reload);
          }
          final data = snapshot.data!;
          return Column(
            children: [
              _AdminRoleTabs(controller: _tabController),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _RolesTab(
                      data: data,
                      bottomPadding: bottomPadding,
                      onRefresh: _reload,
                      onCreateRole: () => _openRoleEditor(data),
                    ),
                    _AssignmentsTab(
                      data: data,
                      bottomPadding: bottomPadding,
                      onRefresh: _reload,
                      onAssign: (principal) => _assignRole(data, principal),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AdminRoleTabs extends StatelessWidget {
  const _AdminRoleTabs({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      child: TabBar(
        controller: controller,
        tabs: [
          Tab(text: context.l10n.adminRolesTitle),
          Tab(text: context.l10n.adminRolesAssignTab),
        ],
      ),
    );
  }
}

class _RolesTab extends StatefulWidget {
  const _RolesTab({
    required this.data,
    required this.bottomPadding,
    required this.onRefresh,
    required this.onCreateRole,
  });

  final _AdminRolesData data;
  final double bottomPadding;
  final Future<void> Function() onRefresh;
  final VoidCallback onCreateRole;

  @override
  State<_RolesTab> createState() => _RolesTabState();
}

class _RolesTabState extends State<_RolesTab> {
  String? _expandedRoleId;

  @override
  Widget build(BuildContext context) {
    return AppRefreshIndicator(
      onRefresh: widget.onRefresh,
      allowRefreshOnShortContent: true,
      child: ListView(
        physics: const TopRefreshScrollPhysics(),
        padding: EdgeInsets.fromLTRB(12, 12, 12, widget.bottomPadding),
        children: [
          SmoothAppear(
            child: FilledButton.icon(
              onPressed: widget.onCreateRole,
              icon: const Icon(Icons.add_rounded),
              label: Text(context.l10n.adminNewRole),
            ),
          ),
          const SizedBox(height: 12),
          M3SegmentSpacedColumn(
            children: [
              for (int index = 0; index < widget.data.roles.length; index++)
                _RoleDefinitionTile(
                  role: widget.data.roles[index],
                  capabilities: widget.data.capabilities,
                  expanded: _expandedRoleId == widget.data.roles[index].id,
                  onExpandedChanged: (expanded) {
                    setState(() {
                      _expandedRoleId =
                          expanded ? widget.data.roles[index].id : null;
                    });
                  },
                  slot: M3SegmentedListGeometry.standaloneListSlotForIndex(
                    index,
                    widget.data.roles.length,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoleDefinitionTile extends StatelessWidget {
  const _RoleDefinitionTile({
    required this.role,
    required this.capabilities,
    required this.expanded,
    required this.onExpandedChanged,
    required this.slot,
  });

  final AdminRoleDefinition role;
  final List<AdminCapability> capabilities;
  final bool expanded;
  final ValueChanged<bool> onExpandedChanged;
  final M3SegmentVerticalSlot slot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final capabilityLabels = role.capabilityCodes
        .map((code) => _capabilityLabel(l10n, code, capabilities))
        .toList(growable: false);
    return M3SegmentFilledSurface(
      key: ValueKey('admin-role-card-${role.id}'),
      slot: slot,
      cornerRadius: M3SegmentedListGeometry.cornerLarge,
      onTap: () => onExpandedChanged(!expanded),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  role.system
                      ? Icons.admin_panel_settings_outlined
                      : Icons.verified_user_outlined,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _roleDefinitionLabel(context, role),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  key: ValueKey('admin-role-details-${role.id}'),
                  tooltip: expanded
                      ? l10n.adminRoleDetailsHide
                      : l10n.adminRoleDetailsShow,
                  onPressed: () => onExpandedChanged(!expanded),
                  icon: AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    child: const Icon(Icons.keyboard_arrow_down_rounded),
                  ),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: expanded
                  ? Padding(
                      padding: const EdgeInsets.only(left: 36, right: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Text(
                            _roleDefinitionSummary(l10n, role),
                            style: theme.textTheme.bodySmall,
                          ),
                          if (capabilityLabels.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              capabilityLabels.join(', '),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignmentsTab extends StatelessWidget {
  const _AssignmentsTab({
    required this.data,
    required this.bottomPadding,
    required this.onRefresh,
    required this.onAssign,
  });

  final _AdminRolesData data;
  final double bottomPadding;
  final Future<void> Function() onRefresh;
  final ValueChanged<_RolePrincipal> onAssign;

  @override
  Widget build(BuildContext context) {
    final principals = data.principalsForDisplay(context.l10n);
    return AppRefreshIndicator(
      onRefresh: onRefresh,
      allowRefreshOnShortContent: true,
      child: ListView(
        physics: const TopRefreshScrollPhysics(),
        padding: EdgeInsets.fromLTRB(12, 12, 12, bottomPadding),
        children: [
          M3SegmentSpacedColumn(
            children: [
              for (int index = 0; index < principals.length; index++)
                _RoleAssignmentTile(
                  principal: principals[index],
                  assignedRole: data.roleForPrincipal(principals[index]),
                  slot: M3SegmentedListGeometry.standaloneListSlotForIndex(
                    index,
                    principals.length,
                  ),
                  onAssign: () => onAssign(principals[index]),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoleAssignmentTile extends StatelessWidget {
  const _RoleAssignmentTile({
    required this.principal,
    required this.assignedRole,
    required this.slot,
    required this.onAssign,
  });

  final _RolePrincipal principal;
  final AdminRoleDefinition? assignedRole;
  final M3SegmentVerticalSlot slot;
  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return M3SegmentFilledSurface(
      slot: slot,
      cornerRadius: M3SegmentedListGeometry.cornerLarge,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          children: [
            Icon(principal.icon, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(principal.name, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text(
                    '${l10n.roleLabelForCode(userRoleToJson(principal.role))} • ${principal.ref}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    assignedRole == null
                        ? l10n.adminDefaultRole
                        : _roleDefinitionLabel(context, assignedRole!),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              onPressed: onAssign,
              child: Text(l10n.archiveSelectDateAction),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminRoleEditorSheet extends StatefulWidget {
  const _AdminRoleEditorSheet({required this.data});

  final _AdminRolesData data;

  @override
  State<_AdminRoleEditorSheet> createState() => _AdminRoleEditorSheetState();
}

class _AdminRoleEditorSheetState extends State<_AdminRoleEditorSheet> {
  final TextEditingController _labelController = TextEditingController();
  final Set<String> _capabilityCodes = <String>{};

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final l10n = context.l10n;
    final canSave =
        _labelController.text.trim().isNotEmpty && _capabilityCodes.isNotEmpty;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.82;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.adminNewRole,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton.filledTonal(
                  key: const ValueKey('admin-role-save-action'),
                  tooltip: l10n.save,
                  onPressed: canSave ? _save : null,
                  icon: const Icon(Icons.check_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _labelController,
              decoration: InputDecoration(
                labelText: l10n.adminRoleNameLabel,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  for (final capability in widget.data.capabilities)
                    CheckboxListTile(
                      value: _capabilityCodes.contains(capability.code),
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            _capabilityCodes.add(capability.code);
                          } else {
                            _capabilityCodes.remove(capability.code);
                          }
                        });
                      },
                      title: Text(
                        l10n.adminCapabilityLabel(
                          capability.code,
                          capability.label,
                        ),
                      ),
                      subtitle: Text(capability.code),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    Navigator.of(context).pop(
      AdminRoleDefinition(
        id: _roleIdFromLabel(_labelController.text),
        label: _labelController.text.trim(),
        baseRole: null,
        capabilityCodes: _capabilityCodes.toList(growable: false),
        system: false,
      ),
    );
  }
}

class _RoleAssignmentSheet extends StatelessWidget {
  const _RoleAssignmentSheet({
    required this.principal,
    required this.roles,
  });

  final _RolePrincipal principal;
  final List<AdminRoleDefinition> roles;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      top: false,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
        children: [
          Text(
            l10n.adminRoleForPrincipal(principal.name),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          for (final role in roles)
            ListTile(
              enabled: _roleCanAssignToPrincipal(role, principal),
              leading: Icon(
                role.system
                    ? Icons.admin_panel_settings_outlined
                    : Icons.verified_user_outlined,
              ),
              title: Text(_roleDefinitionLabel(context, role)),
              subtitle: Text(_roleAssignmentSubtitle(l10n, role)),
              onTap: _roleCanAssignToPrincipal(role, principal)
                  ? () {
                      Navigator.of(context).pop(
                        AdminRoleAssignment(
                          principalRole: principal.role,
                          principalRef: principal.ref,
                          roleId: role.id,
                        ),
                      );
                    }
                  : null,
            ),
        ],
      ),
    );
  }
}

class _AdminRolesData {
  const _AdminRolesData({
    required this.capabilities,
    required this.roles,
    required this.assignments,
    required this.settings,
    required this.suppliers,
    required this.customers,
  });

  final List<AdminCapability> capabilities;
  final List<AdminRoleDefinition> roles;
  final List<AdminRoleAssignment> assignments;
  final AdminSettings settings;
  final List<AdminSupplier> suppliers;
  final List<CustomerDirectoryEntry> customers;

  List<_RolePrincipal> get _principals {
    return <_RolePrincipal>[
      _RolePrincipal(
        role: UserRole.werka,
        ref: 'werka',
        name: settings.werkaName.trim(),
        icon: Icons.badge_outlined,
      ),
      for (final supplier in suppliers)
        _RolePrincipal(
          role: UserRole.supplier,
          ref: supplier.ref,
          name: supplier.name,
          icon: Icons.local_shipping_outlined,
        ),
      for (final customer in customers)
        _RolePrincipal(
          role: UserRole.customer,
          ref: customer.ref,
          name: customer.name,
          icon: Icons.person_outline_rounded,
        ),
    ];
  }

  List<_RolePrincipal> principalsForDisplay(AppLocalizations l10n) {
    final principals = _principals
        .map((principal) {
          final isWerka =
              principal.role == UserRole.werka && principal.ref == 'werka';
          if (isWerka && principal.name.trim().isEmpty) {
            return principal.copyWith(name: l10n.werkaRoleName);
          }
          return principal;
        })
        .where((principal) => principal.name.trim().isNotEmpty)
        .toList(growable: false);
    if (principals.isNotEmpty) {
      return principals;
    }
    return <_RolePrincipal>[
      _RolePrincipal(
        role: UserRole.werka,
        ref: 'werka',
        name: l10n.werkaRoleName,
        icon: Icons.badge_outlined,
      ),
    ];
  }

  AdminRoleDefinition? roleForPrincipal(_RolePrincipal principal) {
    final assignment = assignments
        .where(
          (item) =>
              item.principalRole == principal.role &&
              item.principalRef == principal.ref,
        )
        .letFirstOrNull();
    if (assignment == null) {
      return roles
          .where(
            (role) =>
                role.system &&
                role.baseRole == principal.role &&
                role.id == userRoleToJson(principal.role),
          )
          .letFirstOrNull();
    }
    return roles.where((role) => role.id == assignment.roleId).letFirstOrNull();
  }

  _AdminRolesData upsertRole(AdminRoleDefinition role) {
    final nextRoles = roles.where((item) => item.id != role.id).toList()
      ..add(role)
      ..sort((left, right) {
        if (left.system != right.system) {
          return left.system ? -1 : 1;
        }
        return left.label.compareTo(right.label);
      });
    return copyWith(roles: nextRoles);
  }

  _AdminRolesData upsertAssignment(AdminRoleAssignment assignment) {
    final nextAssignments = assignments
        .where(
          (item) =>
              item.principalRole != assignment.principalRole ||
              item.principalRef != assignment.principalRef,
        )
        .toList()
      ..add(assignment);
    return copyWith(assignments: nextAssignments);
  }

  _AdminRolesData copyWith({
    List<AdminRoleDefinition>? roles,
    List<AdminRoleAssignment>? assignments,
  }) {
    return _AdminRolesData(
      capabilities: capabilities,
      roles: roles ?? this.roles,
      assignments: assignments ?? this.assignments,
      settings: settings,
      suppliers: suppliers,
      customers: customers,
    );
  }
}

class _RolePrincipal {
  const _RolePrincipal({
    required this.role,
    required this.ref,
    required this.name,
    required this.icon,
  });

  final UserRole role;
  final String ref;
  final String name;
  final IconData icon;

  _RolePrincipal copyWith({String? name}) {
    return _RolePrincipal(
      role: role,
      ref: ref,
      name: name ?? this.name,
      icon: icon,
    );
  }
}

String _roleIdFromLabel(String value) {
  final normalized = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return normalized.isEmpty ? 'custom_role' : normalized;
}

String _roleDefinitionLabel(BuildContext context, AdminRoleDefinition role) {
  if (!role.system) {
    return role.label;
  }
  return context.l10n.systemRoleLabel(role.id, role.label);
}

String _roleDefinitionSummary(
  AppLocalizations l10n,
  AdminRoleDefinition role,
) {
  final baseRole = role.baseRole;
  if (baseRole == null) {
    return l10n.adminRoleKindLabel(role.system);
  }
  return '${l10n.roleLabelForCode(userRoleToJson(baseRole))} • ${l10n.adminRoleKindLabel(role.system)}';
}

bool _roleCanAssignToPrincipal(
  AdminRoleDefinition role,
  _RolePrincipal principal,
) {
  return !role.system || role.baseRole == principal.role;
}

String _roleAssignmentSubtitle(
  AppLocalizations l10n,
  AdminRoleDefinition role,
) {
  final baseRole = role.baseRole;
  if (baseRole == null) {
    return l10n.adminRoleKindLabel(role.system);
  }
  return l10n.roleLabelForCode(userRoleToJson(baseRole));
}

String _capabilityLabel(
  AppLocalizations l10n,
  String code,
  List<AdminCapability> capabilities,
) {
  final fallback = capabilities
          .where((capability) => capability.code == code)
          .map((capability) => capability.label)
          .letFirstOrNull() ??
      code;
  return l10n.adminCapabilityLabel(code, fallback);
}

extension _FirstOrNull<T> on Iterable<T> {
  T? letFirstOrNull() {
    final iterator = this.iterator;
    if (!iterator.moveNext()) {
      return null;
    }
    return iterator.current;
  }
}
