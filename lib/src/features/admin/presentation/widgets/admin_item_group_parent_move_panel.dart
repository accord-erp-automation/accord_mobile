import '../../../../core/api/mobile_api.dart';
import '../../../../core/widgets/display/common_widgets.dart';
import '../../../shared/models/app_models.dart';
import 'admin_top_notice.dart';
import 'package:flutter/material.dart';

const double _itemGroupPanelCornerRadius = 8;

class AdminItemGroupParentMovePanel extends StatefulWidget {
  const AdminItemGroupParentMovePanel({
    super.key,
    required this.groups,
    required this.onMoved,
  });

  final List<String> groups;
  final ValueChanged<AdminItemGroup> onMoved;

  @override
  State<AdminItemGroupParentMovePanel> createState() =>
      _AdminItemGroupParentMovePanelState();
}

class _AdminItemGroupParentMovePanelState
    extends State<AdminItemGroupParentMovePanel> {
  String? groupName;
  String? parentName;
  bool submitting = false;

  List<String> get movableGroups => widget.groups
      .map((group) => group.trim())
      .where((group) => group.isNotEmpty && group != 'All Item Groups')
      .toSet()
      .toList()
    ..sort();

  List<String> get parentGroups {
    final current = groupName?.trim() ?? '';
    return widget.groups
        .map((group) => group.trim())
        .where((group) => group.isNotEmpty && group != current)
        .toSet()
        .toList()
      ..sort();
  }

  @override
  void didUpdateWidget(AdminItemGroupParentMovePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final movable = movableGroups;
    final parents = parentGroups;
    if (groupName != null && !movable.contains(groupName)) {
      groupName = null;
    }
    if (parentName != null && !parents.contains(parentName)) {
      parentName =
          parents.contains('All Item Groups') ? 'All Item Groups' : null;
    }
  }

  Future<void> _move() async {
    final group = groupName?.trim() ?? '';
    final parent = parentName?.trim() ?? '';
    if (group.isEmpty || parent.isEmpty || submitting) {
      return;
    }
    setState(() => submitting = true);
    try {
      final moved = await MobileApi.instance.adminMoveItemGroupParent(
        name: group,
        parent: parent,
      );
      if (!mounted) {
        return;
      }
      widget.onMoved(moved);
      showAdminTopNotice(context, '${moved.itemGroupName} parenti yangilandi');
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Parent yangilanmadi: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final movable = movableGroups;
    final parents = parentGroups;
    final canSubmit = !submitting &&
        (groupName?.isNotEmpty ?? false) &&
        (parentName?.isNotEmpty ?? false);
    return SoftCard(
      borderRadius: _itemGroupPanelCornerRadius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Parentni ko‘chirish',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Mavjud groupni boshqa parent ostiga o‘tkazish uchun ishlatiladi.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            key: ValueKey('move-group-${groupName ?? ''}-${movable.length}'),
            initialValue: movable.contains(groupName) ? groupName : null,
            items: [
              for (final group in movable)
                DropdownMenuItem(value: group, child: Text(group)),
            ],
            onChanged: submitting
                ? null
                : (value) {
                    setState(() {
                      groupName = value;
                      if (parentName == value) {
                        parentName = parents.contains('All Item Groups')
                            ? 'All Item Groups'
                            : null;
                      }
                    });
                  },
            decoration: _moveInputDecoration('Ko‘chiriladigan group'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('move-parent-${parentName ?? ''}-${parents.length}'),
            initialValue: parents.contains(parentName) ? parentName : null,
            items: [
              for (final parent in parents)
                DropdownMenuItem(value: parent, child: Text(parent)),
            ],
            onChanged: submitting
                ? null
                : (value) => setState(() => parentName = value),
            decoration: _moveInputDecoration('Yangi parent'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: canSubmit ? _move : null,
            child:
                Text(submitting ? 'Ko‘chirilmoqda...' : 'Parentni yangilash'),
          ),
        ],
      ),
    );
  }
}

InputDecoration _moveInputDecoration(String label) {
  const border = OutlineInputBorder(
    borderRadius: BorderRadius.all(
      Radius.circular(_itemGroupPanelCornerRadius),
    ),
  );
  return const InputDecoration(
    labelText: '',
    border: border,
    enabledBorder: border,
    focusedBorder: border,
  ).copyWith(labelText: label);
}
