import '../../../core/api/mobile_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shell/app_loading_indicator.dart';
import '../../../core/widgets/shell/app_retry_state.dart';
import '../../../core/widgets/shell/app_shell.dart';
import '../../shared/models/app_models.dart';
import '../../werka/presentation/widgets/m3_picker_sheet.dart';
import 'admin_suppliers_screen.dart';
import 'widgets/admin_dock.dart';
import 'widgets/admin_top_notice.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AdminUserCreateScreen extends StatefulWidget {
  const AdminUserCreateScreen({super.key});

  @override
  State<AdminUserCreateScreen> createState() => _AdminUserCreateScreenState();
}

class _AdminUserCreateScreenState extends State<AdminUserCreateScreen> {
  late Future<List<_AdminUserCreateChoice>> _roleChoices;
  _AdminUserCreateChoice _choice = _AdminUserCreateChoice.system(
    _AdminUserCreateKind.werka,
  );

  @override
  void initState() {
    super.initState();
    _roleChoices = _loadRoleChoices();
  }

  Future<List<_AdminUserCreateChoice>> _loadRoleChoices() async {
    final fallbackChoices = _AdminUserCreateKind.values
        .map(_AdminUserCreateChoice.system)
        .toList(growable: true);
    try {
      final roles = await MobileApi.instance.adminRoles();
      return [
        ...roles
            .where((role) => !role.system)
            .map(_AdminUserCreateChoice.custom),
        ...fallbackChoices,
      ];
    } catch (_) {
      return fallbackChoices;
    }
  }

  Future<void> _openRolePicker() async {
    final choices = await _roleChoices;
    if (!mounted) {
      return;
    }
    final picked = await showModalBottomSheet<_AdminUserCreateChoice>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.32),
      sheetAnimationStyle: kM3PickerSheetAnimation,
      builder: (context) {
        return M3PickerSheet<_AdminUserCreateChoice>(
          title: 'Role tanlang',
          hintText: 'Role qidiring',
          items: choices,
          itemTitle: (choice) => choice.label,
          itemSubtitle: (choice) => choice.subtitle,
          matchesQuery: (choice, query) {
            final normalized = query.trim().toLowerCase();
            return choice.label.toLowerCase().contains(normalized) ||
                choice.subtitle.toLowerCase().contains(normalized);
          },
          onSelected: (choice) => Navigator.of(context).pop(choice),
        );
      },
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _choice = picked);
  }

  @override
  Widget build(BuildContext context) {
    final kind = _choice.kind;
    return AppShell(
      title: 'Foydalanuvchi qo‘shish',
      subtitle: '',
      nativeTopBar: true,
      nativeTitleTextStyle: AppTheme.werkaNativeAppBarTitleStyle(context),
      bottom: const AdminDock(activeTab: AdminDockTab.settings),
      contentPadding: EdgeInsets.zero,
      child: Column(
        children: [
          _RoleSelector(
            choice: _choice,
            onTap: _openRolePicker,
          ),
          Expanded(
            child: switch (kind) {
              _AdminUserCreateKind.werka => _WerkaCreateTab(
                  assignedRole: _choice.customRole,
                ),
              _AdminUserCreateKind.customer => _CustomerCreateTab(
                  assignedRole: _choice.customRole,
                ),
              _AdminUserCreateKind.supplier => _SupplierCreateTab(
                  assignedRole: _choice.customRole,
                ),
              _AdminUserCreateKind.custom => _CustomRoleCreateTab(
                  assignedRole: _choice.customRole!,
                ),
            },
          ),
        ],
      ),
    );
  }
}

class _AdminUserCreateChoice {
  const _AdminUserCreateChoice({
    required this.kind,
    required this.label,
    required this.subtitle,
    this.customRole,
  });

  factory _AdminUserCreateChoice.system(_AdminUserCreateKind kind) {
    return _AdminUserCreateChoice(
      kind: kind,
      label: kind.label,
      subtitle: kind.subtitle,
    );
  }

  factory _AdminUserCreateChoice.custom(AdminRoleDefinition role) {
    final kind = _kindForRole(role);
    return _AdminUserCreateChoice(
      kind: kind,
      label: role.label,
      subtitle: kind.label,
      customRole: role,
    );
  }

  final _AdminUserCreateKind kind;
  final String label;
  final String subtitle;
  final AdminRoleDefinition? customRole;
}

enum _AdminUserCreateKind {
  werka,
  customer,
  supplier,
  custom;

  String get label {
    return switch (this) {
      _AdminUserCreateKind.werka => 'Omborchi',
      _AdminUserCreateKind.customer => 'Haridor',
      _AdminUserCreateKind.supplier => 'Ta’minotchi',
      _AdminUserCreateKind.custom => 'Foydalanuvchi',
    };
  }

  String get subtitle {
    return switch (this) {
      _AdminUserCreateKind.werka => 'Warehouse worker account',
      _AdminUserCreateKind.customer => 'Mahsulot qabul qiluvchi haridor',
      _AdminUserCreateKind.supplier => 'Mahsulot yuboruvchi ta’minotchi',
      _AdminUserCreateKind.custom => 'Role asosidagi foydalanuvchi',
    };
  }
}

_AdminUserCreateKind _kindForRole(AdminRoleDefinition role) {
  final baseRole = role.baseRole;
  if (baseRole == UserRole.supplier) {
    return _AdminUserCreateKind.supplier;
  }
  if (baseRole == UserRole.customer) {
    return _AdminUserCreateKind.customer;
  }
  if (role.capabilityCodes.contains('supplier.access')) {
    return _AdminUserCreateKind.supplier;
  }
  if (role.capabilityCodes.contains('customer.access')) {
    return _AdminUserCreateKind.customer;
  }
  if (role.capabilityCodes.contains('werka.access')) {
    return _AdminUserCreateKind.werka;
  }
  return _AdminUserCreateKind.custom;
}

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({
    required this.choice,
    required this.onTap,
  });

  final _AdminUserCreateChoice choice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Role tanlash',
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Material(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onTap,
              child: Container(
                constraints: const BoxConstraints(minHeight: 58),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.admin_panel_settings_outlined,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            choice.label,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            choice.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.expand_more_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerCreateTab extends StatefulWidget {
  const _CustomerCreateTab({required this.assignedRole});

  final AdminRoleDefinition? assignedRole;

  @override
  State<_CustomerCreateTab> createState() => _CustomerCreateTabState();
}

class _CustomerCreateTabState extends State<_CustomerCreateTab> {
  final TextEditingController name = TextEditingController();
  final TextEditingController phone = TextEditingController();
  bool saving = false;

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() => saving = true);
    try {
      final customer = await MobileApi.instance.adminCreateCustomer(
        name: name.text.trim(),
        phone: phone.text.trim(),
      );
      await _assignCustomRole(
        widget.assignedRole,
        UserRole.customer,
        customer.ref,
      );
      if (!mounted) {
        return;
      }
      name.clear();
      phone.clear();
      AdminSuppliersScreen.invalidateCache();
      showAdminTopNotice(context, 'Haridor yaratildi');
    } catch (_) {
      if (mounted) {
        showAdminTopNotice(context, 'Haridor yaratilmadi');
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _CreateUserForm(
      name: name,
      phone: phone,
      nameLabel: 'Haridor name',
      phoneLabel: 'Haridor phone',
      actionLabel: saving ? 'Qo‘shilmoqda...' : 'Haridor qo‘shish',
      saving: saving,
      onSubmit: _create,
    );
  }
}

class _SupplierCreateTab extends StatefulWidget {
  const _SupplierCreateTab({required this.assignedRole});

  final AdminRoleDefinition? assignedRole;

  @override
  State<_SupplierCreateTab> createState() => _SupplierCreateTabState();
}

class _SupplierCreateTabState extends State<_SupplierCreateTab> {
  final TextEditingController name = TextEditingController();
  final TextEditingController phone = TextEditingController();
  bool saving = false;

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() => saving = true);
    try {
      final supplier = await MobileApi.instance.adminCreateSupplier(
        name: name.text.trim(),
        phone: phone.text.trim(),
      );
      await _assignCustomRole(
        widget.assignedRole,
        UserRole.supplier,
        supplier.ref,
      );
      if (!mounted) {
        return;
      }
      name.clear();
      phone.clear();
      AdminSuppliersScreen.invalidateCache();
      showAdminTopNotice(context, 'Ta’minotchi yaratildi');
    } catch (_) {
      if (mounted) {
        showAdminTopNotice(context, 'Ta’minotchi yaratilmadi');
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _CreateUserForm(
      name: name,
      phone: phone,
      nameLabel: 'Ta’minotchi name',
      phoneLabel: 'Ta’minotchi phone',
      actionLabel: saving ? 'Qo‘shilmoqda...' : 'Ta’minotchi qo‘shish',
      saving: saving,
      onSubmit: _create,
    );
  }
}

class _CustomRoleCreateTab extends StatefulWidget {
  const _CustomRoleCreateTab({required this.assignedRole});

  final AdminRoleDefinition assignedRole;

  @override
  State<_CustomRoleCreateTab> createState() => _CustomRoleCreateTabState();
}

class _CustomRoleCreateTabState extends State<_CustomRoleCreateTab> {
  final TextEditingController name = TextEditingController();
  final TextEditingController phone = TextEditingController();
  bool saving = false;

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() => saving = true);
    try {
      final user = await MobileApi.instance.adminCreateCustomer(
        name: name.text.trim(),
        phone: phone.text.trim(),
      );
      await _assignCustomRole(widget.assignedRole, UserRole.customer, user.ref);
      if (!mounted) {
        return;
      }
      name.clear();
      phone.clear();
      AdminSuppliersScreen.invalidateCache();
      showAdminTopNotice(context, 'Foydalanuvchi yaratildi');
    } catch (_) {
      if (mounted) {
        showAdminTopNotice(context, 'Foydalanuvchi yaratilmadi');
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _CreateUserForm(
      name: name,
      phone: phone,
      nameLabel: 'Foydalanuvchi name',
      phoneLabel: 'Foydalanuvchi phone',
      actionLabel: saving ? 'Saqlanmoqda...' : 'Foydalanuvchi saqlash',
      saving: saving,
      onSubmit: _create,
    );
  }
}

class _WerkaCreateTab extends StatefulWidget {
  const _WerkaCreateTab({required this.assignedRole});

  final AdminRoleDefinition? assignedRole;

  @override
  State<_WerkaCreateTab> createState() => _WerkaCreateTabState();
}

class _WerkaCreateTabState extends State<_WerkaCreateTab> {
  late Future<AdminSettings> _future;
  final TextEditingController phone = TextEditingController();
  final TextEditingController name = TextEditingController();
  String werkaCode = '';
  int _retryAfterSec = 0;
  bool saving = false;
  bool regenerating = false;
  bool hydrated = false;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    _future = MobileApi.instance.adminSettings();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    phone.dispose();
    name.dispose();
    super.dispose();
  }

  void _fill(AdminSettings settings) {
    if (hydrated) {
      return;
    }
    phone.text = settings.werkaPhone;
    name.text = settings.werkaName;
    werkaCode = settings.werkaCode;
    _setRetryAfter(settings.werkaCodeRetryAfterSec);
    hydrated = true;
  }

  void _setRetryAfter(int seconds) {
    _retryTimer?.cancel();
    _retryAfterSec = seconds > 0 ? seconds : 0;
    if (_retryAfterSec <= 0) {
      return;
    }
    _retryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _retryAfterSec <= 1) {
        timer.cancel();
        if (mounted) {
          setState(() => _retryAfterSec = 0);
        }
        return;
      }
      setState(() => _retryAfterSec -= 1);
    });
  }

  Future<void> _reload() async {
    final future = MobileApi.instance.adminSettings();
    setState(() {
      hydrated = false;
      _future = future;
    });
  }

  Future<void> _save(AdminSettings current) async {
    setState(() => saving = true);
    try {
      final updated = await MobileApi.instance.updateAdminSettings(
        AdminSettings(
          erpUrl: current.erpUrl,
          erpApiKey: current.erpApiKey,
          erpApiSecret: current.erpApiSecret,
          defaultTargetWarehouse: current.defaultTargetWarehouse,
          defaultUom: current.defaultUom,
          werkaPhone: phone.text.trim(),
          werkaName: name.text.trim(),
          werkaCode: werkaCode,
          werkaCodeLocked: current.werkaCodeLocked,
          werkaCodeRetryAfterSec: _retryAfterSec,
          adminPhone: current.adminPhone,
          adminName: current.adminName,
        ),
      );
      await _assignCustomRole(widget.assignedRole, UserRole.werka, 'werka');
      if (!mounted) {
        return;
      }
      setState(() {
        werkaCode = updated.werkaCode;
      });
      AdminSuppliersScreen.invalidateCache();
      showAdminTopNotice(context, 'Omborchi saqlandi');
    } catch (_) {
      if (mounted) {
        showAdminTopNotice(context, 'Omborchi saqlanmadi');
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Future<void> _regenerate() async {
    setState(() => regenerating = true);
    try {
      final updated = await MobileApi.instance.adminRegenerateWerkaCode();
      if (!mounted) {
        return;
      }
      setState(() {
        werkaCode = updated.werkaCode;
      });
      _setRetryAfter(updated.werkaCodeRetryAfterSec);
      showAdminTopNotice(context, 'Omborchi code yangilandi');
    } catch (_) {
      if (mounted) {
        showAdminTopNotice(context, 'Code yangilanmadi');
      }
    } finally {
      if (mounted) {
        setState(() => regenerating = false);
      }
    }
  }

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: werkaCode));
    if (!mounted) {
      return;
    }
    showAdminTopNotice(context, 'Code nusxalandi');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AdminSettings>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: AppLoadingIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              AppRetryState(onRetry: _reload, padding: EdgeInsets.zero),
            ],
          );
        }
        final current = snapshot.data!;
        _fill(current);
        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          children: [
            _WerkaCodeField(
              code: werkaCode,
              regenerating: regenerating,
              retryAfterSec: _retryAfterSec,
              onCopy: werkaCode.trim().isEmpty ? null : _copyCode,
              onRegenerate:
                  regenerating || _retryAfterSec > 0 ? null : _regenerate,
            ),
            if (_retryAfterSec > 0) ...[
              const SizedBox(height: 12),
              Text('Keyingi code uchun $_retryAfterSec soniya kuting.'),
            ],
            const SizedBox(height: 14),
            _CreateUserForm(
              name: name,
              phone: phone,
              nameLabel: 'Omborchi name',
              phoneLabel: 'Omborchi phone',
              actionLabel: saving ? 'Saqlanmoqda...' : 'Omborchi saqlash',
              saving: saving,
              onSubmit: () => _save(current),
              padding: EdgeInsets.zero,
            ),
          ],
        );
      },
    );
  }
}

Future<void> _assignCustomRole(
  AdminRoleDefinition? role,
  UserRole principalRole,
  String principalRef,
) async {
  if (role == null || role.system) {
    return;
  }
  await MobileApi.instance.adminUpsertRoleAssignment(
    AdminRoleAssignment(
      principalRole: principalRole,
      principalRef: principalRef,
      roleId: role.id,
    ),
  );
}

class _CreateUserForm extends StatelessWidget {
  const _CreateUserForm({
    required this.name,
    required this.phone,
    required this.nameLabel,
    required this.phoneLabel,
    required this.actionLabel,
    required this.saving,
    required this.onSubmit,
    this.padding = const EdgeInsets.fromLTRB(12, 12, 12, 24),
  });

  final TextEditingController name;
  final TextEditingController phone;
  final String nameLabel;
  final String phoneLabel;
  final String actionLabel;
  final bool saving;
  final VoidCallback onSubmit;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: padding,
      shrinkWrap: padding == EdgeInsets.zero,
      physics: padding == EdgeInsets.zero
          ? const NeverScrollableScrollPhysics()
          : null,
      children: [
        TextField(
          controller: name,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(labelText: nameLabel),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: phone,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(labelText: phoneLabel),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: saving ? null : onSubmit,
            child: Text(actionLabel),
          ),
        ),
      ],
    );
  }
}

class _WerkaCodeField extends StatelessWidget {
  const _WerkaCodeField({
    required this.code,
    required this.regenerating,
    required this.retryAfterSec,
    required this.onCopy,
    required this.onRegenerate,
  });

  final String code;
  final bool regenerating;
  final int retryAfterSec;
  final VoidCallback? onCopy;
  final VoidCallback? onRegenerate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Code', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: SelectableText(
                  code,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: onCopy,
                icon: const Icon(Icons.content_copy_outlined),
              ),
              IconButton(
                onPressed: onRegenerate,
                icon: regenerating
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
