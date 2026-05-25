import '../../../core/api/mobile_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shell/app_shell.dart';
import '../../shared/models/app_models.dart';
import '../../werka/presentation/widgets/m3_picker_sheet.dart';
import '../models/production_map_models.dart';
import 'widgets/admin_dock.dart';
import 'package:flutter/material.dart';

class AdminProductionMapTestScreen extends StatefulWidget {
  const AdminProductionMapTestScreen({super.key});

  @override
  State<AdminProductionMapTestScreen> createState() =>
      _AdminProductionMapTestScreenState();
}

class _AdminProductionMapTestScreenState
    extends State<AdminProductionMapTestScreen> {
  String mapID = 'hotlunch-test';
  String productCode = 'HOTLUNCH';
  String productName = 'HOTLUNCH';
  String mapTitle = 'Hotlunch test map';

  final nodes = <ProductionMapNode>[
    const ProductionMapNode(
      id: 'start',
      kind: 'start',
      title: 'Start',
    ),
    const ProductionMapNode(
      id: 'cpp_calc',
      kind: 'formula',
      title: 'CPP hisob',
      itemCode: 'CPP',
      formula: ProductionFormula(
        target: 'cpp_kg',
        expression: 'order_qty * 1.08',
      ),
    ),
    const ProductionMapNode(
      id: 'rezka_task',
      kind: 'task',
      title: 'Rezkaga yuborish',
      roleCode: 'rezkachi',
    ),
    const ProductionMapNode(
      id: 'end',
      kind: 'end',
      title: 'End',
    ),
  ];
  final edges = <ProductionMapEdge>[
    const ProductionMapEdge(from: 'start', to: 'cpp_calc'),
    const ProductionMapEdge(from: 'cpp_calc', to: 'rezka_task'),
    const ProductionMapEdge(from: 'rezka_task', to: 'end'),
  ];

  bool saving = false;
  int _nextNodeIndex = 1;
  final _editorStackKey = GlobalKey();
  String? _draggingNodeID;
  double? _dragStartY;
  Offset? _floatingNodeOffset;
  Offset _floatingTouchOffset = Offset.zero;

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      await MobileApi.instance.adminSaveProductionMap(
        ProductionMapDefinition(
          id: mapID,
          productCode: productCode,
          title: mapTitle,
          nodes: nodes,
          edges: edges,
        ),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Map saqlandi va compiled bo‘ldi')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Map saqlanmadi: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  void _addNode(String kind) {
    final id = '${kind}_${_nextNodeIndex++}';
    setState(() {
      nodes.insert(
        nodes.length - 1,
        _newNode(id, kind),
      );
      _rebuildLinearEdges();
    });
  }

  ProductionMapNode _newNode(String id, String kind) {
    return switch (kind) {
      'material' => ProductionMapNode(
          id: id,
          kind: 'material',
          title: 'Material tanlash',
          itemCode: 'CPP',
        ),
      'formula' => ProductionMapNode(
          id: id,
          kind: 'formula',
          title: 'Hisob kitob',
          formula: const ProductionFormula(
            target: 'result_kg',
            expression: 'order_qty',
          ),
        ),
      'wait' => ProductionMapNode(
          id: id,
          kind: 'wait',
          title: 'Material kutish',
        ),
      'output' => ProductionMapNode(
          id: id,
          kind: 'output',
          title: 'Natija chiqarish',
          itemCode: productCode,
        ),
      _ => ProductionMapNode(
          id: id,
          kind: 'task',
          title: 'Yangi location',
          roleCode: 'worker',
        ),
    };
  }

  void _rebuildLinearEdges() {
    edges
      ..clear()
      ..addAll([
        for (var i = 0; i < nodes.length - 1; i++)
          ProductionMapEdge(from: nodes[i].id, to: nodes[i + 1].id),
      ]);
  }

  Future<void> _editMapInfo() async {
    final edited = await showModalBottomSheet<_MapInfo>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MapInfoSheet(
        mapID: mapID,
        title: mapTitle,
      ),
    );
    if (edited == null || !mounted) {
      return;
    }
    setState(() {
      mapID = edited.mapID;
      mapTitle = edited.title;
    });
  }

  Future<void> _openProductPicker() async {
    final picked = await showModalBottomSheet<SupplierItem>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.32),
      sheetAnimationStyle: kM3PickerSheetAnimation,
      builder: (context) {
        return M3AsyncPickerSheet<SupplierItem>(
          title: 'Mahsulot tanlang',
          hintText: 'Mahsulot qidiring',
          pageSize: 80,
          cacheKey: 'production-map:items',
          loadPage: (query, offset, limit) {
            return MobileApi.instance.adminItemsPage(
              query: query,
              offset: offset,
              limit: limit,
            );
          },
          itemTitle: (item) => item.name.trim().isEmpty ? item.code : item.name,
          itemSubtitle: (item) => item.code,
          onSelected: (item) => Navigator.of(context).pop(item),
        );
      },
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      productCode = picked.code;
      productName = picked.name.trim().isEmpty ? picked.code : picked.name;
    });
  }

  Future<void> _editNode(int index) async {
    final node = nodes[index];
    final edited = await showModalBottomSheet<ProductionMapNode>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NodeEditSheet(node: node),
    );
    if (edited == null || !mounted) {
      return;
    }
    setState(() => nodes[index] = edited);
  }

  void _deleteNode(int index) {
    final node = nodes[index];
    if (node.kind == 'start' || node.kind == 'end') {
      return;
    }
    setState(() {
      nodes.removeAt(index);
      _rebuildLinearEdges();
    });
  }

  void _reorderNode(int oldIndex, int newIndex) {
    if (oldIndex == 0 || oldIndex == nodes.length - 1) {
      return;
    }
    var targetIndex = newIndex;
    if (targetIndex > oldIndex) {
      targetIndex -= 1;
    }
    targetIndex = targetIndex.clamp(1, nodes.length - 2);
    if (oldIndex == targetIndex) {
      return;
    }
    setState(() {
      final node = nodes.removeAt(oldIndex);
      nodes.insert(targetIndex, node);
      _rebuildLinearEdges();
    });
  }

  ProductionMapNode? get _floatingNode {
    final nodeID = _draggingNodeID;
    if (nodeID == null) {
      return null;
    }
    for (final node in nodes) {
      if (node.id == nodeID) {
        return node;
      }
    }
    return null;
  }

  Offset? _localDragPosition(Offset globalPosition) {
    final context = _editorStackKey.currentContext;
    if (context == null) {
      return null;
    }
    final box = context.findRenderObject() as RenderBox?;
    return box?.globalToLocal(globalPosition);
  }

  void _startFloatingDrag(
    String nodeID,
    LongPressStartDetails details,
  ) {
    final index = nodes.indexWhere((node) => node.id == nodeID);
    if (index <= 0 || index >= nodes.length - 1) {
      return;
    }
    final localPosition = _localDragPosition(details.globalPosition);
    if (localPosition == null) {
      return;
    }
    setState(() {
      _draggingNodeID = nodeID;
      _dragStartY = details.globalPosition.dy;
      _floatingTouchOffset = details.localPosition;
      _floatingNodeOffset = localPosition - _floatingTouchOffset;
    });
  }

  void _updateFloatingDrag(LongPressMoveUpdateDetails details) {
    final nodeID = _draggingNodeID;
    if (nodeID == null) {
      return;
    }
    final localPosition = _localDragPosition(details.globalPosition);
    if (localPosition != null) {
      setState(() {
        _floatingNodeOffset = localPosition - _floatingTouchOffset;
      });
    }
    final startY = _dragStartY;
    if (startY == null) {
      _dragStartY = details.globalPosition.dy;
      return;
    }
    final currentIndex = nodes.indexWhere((node) => node.id == nodeID);
    if (currentIndex <= 0 || currentIndex >= nodes.length - 1) {
      return;
    }
    final deltaY = details.globalPosition.dy - startY;
    if (deltaY < -64 && currentIndex > 1) {
      _reorderNode(currentIndex, currentIndex - 1);
      _dragStartY = details.globalPosition.dy;
    } else if (deltaY > 64 && currentIndex < nodes.length - 2) {
      _reorderNode(currentIndex, currentIndex + 2);
      _dragStartY = details.globalPosition.dy;
    }
  }

  void _endFloatingDrag(LongPressEndDetails details) {
    setState(() {
      _draggingNodeID = null;
      _dragStartY = null;
      _floatingNodeOffset = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom + 136.0;
    final floatingNode = _floatingNode;
    final floatingOffset = _floatingNodeOffset;
    final floatingWidth = MediaQuery.sizeOf(context).width - 48;
    return AppShell(
      title: 'Production map test',
      subtitle: '',
      nativeTopBar: true,
      nativeTitleTextStyle: AppTheme.werkaNativeAppBarTitleStyle(context),
      contentPadding: EdgeInsets.zero,
      animateOnEnter: false,
      bottom: const AdminDock(activeTab: AdminDockTab.home),
      child: ColoredBox(
        color: scheme.surface,
        child: Stack(
          key: _editorStackKey,
          clipBehavior: Clip.none,
          children: [
            ListView(
              padding: EdgeInsets.fromLTRB(12, 12, 12, bottomPadding),
              children: [
                _SurfacePanel(
                  child: Column(
                    children: [
                      _InfoLine(
                        label: 'Map ID',
                        value: mapID,
                        onTap: _editMapInfo,
                      ),
                      const SizedBox(height: 6),
                      _InfoLine(
                        label: 'Mahsulot',
                        value: productName == productCode
                            ? productCode
                            : '$productName · $productCode',
                        onTap: _openProductPicker,
                      ),
                      const SizedBox(height: 6),
                      _InfoLine(
                        label: 'Nomi',
                        value: mapTitle,
                        onTap: _editMapInfo,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _PlainActionButton(
                              label: 'Location',
                              icon: Icons.account_tree_rounded,
                              onTap: () => _addNode('task'),
                              tonal: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _PlainActionButton(
                              label: 'Formula',
                              icon: Icons.functions_rounded,
                              onTap: () => _addNode('formula'),
                              tonal: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _PlainActionButton(
                              label: 'Material',
                              icon: Icons.inventory_2_rounded,
                              onTap: () => _addNode('material'),
                              tonal: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _PlainActionButton(
                              label: 'Wait',
                              icon: Icons.hourglass_bottom_rounded,
                              onTap: () => _addNode('wait'),
                              tonal: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _PlainActionButton(
                              label: 'Output',
                              icon: Icons.flag_rounded,
                              onTap: () => _addNode('output'),
                              tonal: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _PlainActionButton(
                              label: saving ? 'Saqlanyapti' : 'Save + compile',
                              icon: Icons.check_rounded,
                              onTap: saving ? null : _save,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SurfacePanel(
                  child: Column(
                    children: [
                      for (var i = 0; i < nodes.length; i++) ...[
                        Opacity(
                          opacity: _draggingNodeID == nodes[i].id ? 0.24 : 1,
                          child: _MapNodeRow(
                            node: nodes[i],
                            onTap: () => _editNode(i),
                            onDelete: nodes[i].kind == 'start' ||
                                    nodes[i].kind == 'end'
                                ? null
                                : () => _deleteNode(i),
                            canDrag: nodes[i].kind != 'start' &&
                                nodes[i].kind != 'end',
                            onLongPressStart: (details) =>
                                _startFloatingDrag(nodes[i].id, details),
                            onLongPressMoveUpdate: _updateFloatingDrag,
                            onLongPressEnd: _endFloatingDrag,
                          ),
                        ),
                        if (i < nodes.length - 1)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SurfacePanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edges',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      for (final edge in edges)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Text(
                            '${edge.from} -> ${edge.to}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (floatingNode != null && floatingOffset != null)
              Positioned(
                left: floatingOffset.dx.clamp(12, 48).toDouble(),
                top: floatingOffset.dy,
                width: floatingWidth,
                child: IgnorePointer(
                  child: _MapNodeVisual(
                    node: floatingNode,
                    onTap: () {},
                    onDelete: null,
                    floating: true,
                    highlighted: false,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlainActionButton extends StatefulWidget {
  const _PlainActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.tonal = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool tonal;

  @override
  State<_PlainActionButton> createState() => _PlainActionButtonState();
}

class _PlainActionButtonState extends State<_PlainActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = widget.onTap != null;
    final background =
        widget.tonal ? scheme.secondaryContainer : scheme.primary;
    final foreground =
        widget.tonal ? scheme.onSecondaryContainer : scheme.onPrimary;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        scale: _pressed ? 0.985 : 1,
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            splashColor: scheme.onPrimary.withValues(alpha: 0.12),
            highlightColor: scheme.onPrimary.withValues(alpha: 0.08),
            onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
            onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
            onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
            onTap: widget.onTap,
            child: Opacity(
              opacity: enabled ? 1 : 0.48,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.icon, color: foreground, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: foreground,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SurfacePanel extends StatelessWidget {
  const _SurfacePanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: child,
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final content = Row(
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (onTap != null)
          Icon(
            Icons.edit_rounded,
            size: 16,
            color: scheme.onSurfaceVariant,
          ),
      ],
    );
    if (onTap == null) {
      return content;
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: content,
      ),
    );
  }
}

class _MapNodeRow extends StatelessWidget {
  const _MapNodeRow({
    required this.node,
    required this.onTap,
    required this.onDelete,
    required this.canDrag,
    required this.onLongPressStart,
    required this.onLongPressMoveUpdate,
    required this.onLongPressEnd,
  });

  final ProductionMapNode node;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool canDrag;
  final GestureLongPressStartCallback onLongPressStart;
  final GestureLongPressMoveUpdateCallback onLongPressMoveUpdate;
  final GestureLongPressEndCallback onLongPressEnd;

  @override
  Widget build(BuildContext context) {
    final content = _MapNodeVisual(
      node: node,
      onTap: onTap,
      onDelete: onDelete,
      floating: false,
      highlighted: false,
    );
    if (!canDrag) {
      return content;
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: onLongPressStart,
      onLongPressMoveUpdate: onLongPressMoveUpdate,
      onLongPressEnd: onLongPressEnd,
      child: content,
    );
  }
}

class _MapNodeVisual extends StatelessWidget {
  const _MapNodeVisual({
    required this.node,
    required this.onTap,
    required this.onDelete,
    required this.floating,
    required this.highlighted,
  });

  final ProductionMapNode node;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool floating;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      label: '${node.title} node',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: _colorFor(node.kind, scheme),
            borderRadius: _shapeFor(node.kind),
            border: highlighted
                ? Border.all(color: scheme.primary, width: 2)
                : null,
            boxShadow: floating
                ? [
                    BoxShadow(
                      color: scheme.shadow.withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: scheme.surface.withValues(alpha: 0.55),
                  child: Icon(_iconFor(node.kind), size: 19),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        node.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _subtitleFor(node),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _labelFor(node.kind),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (onDelete != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onDelete,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String kind) {
    return switch (kind) {
      'formula' => Icons.functions_rounded,
      'task' => Icons.engineering_rounded,
      'wait' => Icons.hourglass_bottom_rounded,
      'output' => Icons.inventory_2_rounded,
      'end' => Icons.flag_rounded,
      _ => Icons.play_arrow_rounded,
    };
  }

  String _labelFor(String kind) {
    return switch (kind) {
      'material' => 'material',
      'formula' => 'formula',
      'task' => 'location',
      'wait' => 'wait',
      'output' => 'output',
      'end' => 'end',
      _ => 'start',
    };
  }

  String _subtitleFor(ProductionMapNode node) {
    final formula = node.formula;
    if (formula != null) {
      return '${formula.target} = ${formula.expression}';
    }
    if (node.roleCode.trim().isNotEmpty) {
      return node.roleCode;
    }
    if (node.itemCode.trim().isNotEmpty) {
      return node.itemCode;
    }
    return node.kind;
  }

  Color _colorFor(String kind, ColorScheme scheme) {
    return switch (kind) {
      'formula' => scheme.tertiaryContainer,
      'task' => scheme.secondaryContainer,
      'wait' => scheme.errorContainer,
      'output' => scheme.primaryContainer,
      _ => scheme.surfaceContainerHighest,
    };
  }

  BorderRadius _shapeFor(String kind) {
    return switch (kind) {
      'formula' => const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(28),
        ),
      'task' => BorderRadius.circular(18),
      'wait' => BorderRadius.circular(28),
      'output' => const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(28),
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(12),
        ),
      _ => BorderRadius.circular(14),
    };
  }
}

class _NodeEditSheet extends StatefulWidget {
  const _NodeEditSheet({required this.node});

  final ProductionMapNode node;

  @override
  State<_NodeEditSheet> createState() => _NodeEditSheetState();
}

class _NodeEditSheetState extends State<_NodeEditSheet> {
  late final TextEditingController _title;
  late final TextEditingController _itemCode;
  late final TextEditingController _roleCode;
  late final TextEditingController _formulaTarget;
  late final TextEditingController _formulaExpression;

  @override
  void initState() {
    super.initState();
    final formula = widget.node.formula;
    _title = TextEditingController(text: widget.node.title);
    _itemCode = TextEditingController(text: widget.node.itemCode);
    _roleCode = TextEditingController(text: widget.node.roleCode);
    _formulaTarget = TextEditingController(text: formula?.target ?? '');
    _formulaExpression = TextEditingController(text: formula?.expression ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _itemCode.dispose();
    _roleCode.dispose();
    _formulaTarget.dispose();
    _formulaExpression.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: viewInsets),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
            children: [
              Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const SizedBox(width: 44, height: 4),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Node sozlash',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 14),
              _SheetField(label: 'Nomi', controller: _title),
              if (widget.node.kind == 'material' ||
                  widget.node.kind == 'task' ||
                  widget.node.kind == 'output') ...[
                const SizedBox(height: 10),
                _SheetField(label: 'Mahsulot code', controller: _itemCode),
              ],
              if (widget.node.kind == 'task') ...[
                const SizedBox(height: 10),
                _SheetField(label: 'Vazifa / role code', controller: _roleCode),
              ],
              if (widget.node.kind == 'formula') ...[
                const SizedBox(height: 10),
                _SheetField(
                    label: 'Formula target', controller: _formulaTarget),
                const SizedBox(height: 10),
                _SheetField(
                  label: 'Formula',
                  controller: _formulaExpression,
                ),
              ],
              const SizedBox(height: 16),
              _PlainActionButton(
                label: 'Saqlash',
                icon: Icons.check_rounded,
                onTap: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    final title = _title.text.trim();
    final formulaTarget = _formulaTarget.text.trim();
    final formulaExpression = _formulaExpression.text.trim();
    Navigator.of(context).pop(
      ProductionMapNode(
        id: widget.node.id,
        kind: widget.node.kind,
        title: title.isEmpty ? widget.node.title : title,
        itemCode: _itemCode.text.trim(),
        roleCode: _roleCode.text.trim(),
        x: widget.node.x,
        y: widget.node.y,
        formula: widget.node.kind == 'formula'
            ? ProductionFormula(
                target: formulaTarget.isEmpty ? 'result' : formulaTarget,
                expression:
                    formulaExpression.isEmpty ? 'order_qty' : formulaExpression,
              )
            : null,
      ),
    );
  }
}

class _MapInfo {
  const _MapInfo({
    required this.mapID,
    required this.title,
  });

  final String mapID;
  final String title;
}

class _MapInfoSheet extends StatefulWidget {
  const _MapInfoSheet({
    required this.mapID,
    required this.title,
  });

  final String mapID;
  final String title;

  @override
  State<_MapInfoSheet> createState() => _MapInfoSheetState();
}

class _MapInfoSheetState extends State<_MapInfoSheet> {
  late final TextEditingController _mapID;
  late final TextEditingController _title;

  @override
  void initState() {
    super.initState();
    _mapID = TextEditingController(text: widget.mapID);
    _title = TextEditingController(text: widget.title);
  }

  @override
  void dispose() {
    _mapID.dispose();
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: viewInsets),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
            children: [
              Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const SizedBox(width: 44, height: 4),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Map sozlash',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 14),
              _SheetField(label: 'Map ID', controller: _mapID),
              const SizedBox(height: 10),
              _SheetField(label: 'Nomi', controller: _title),
              const SizedBox(height: 16),
              _PlainActionButton(
                label: 'Saqlash',
                icon: Icons.check_rounded,
                onTap: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    final mapID = _mapID.text.trim();
    final title = _title.text.trim();
    Navigator.of(context).pop(
      _MapInfo(
        mapID: mapID.isEmpty ? widget.mapID : mapID,
        title: title.isEmpty ? widget.title : title,
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.label,
    required this.controller,
  });

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
