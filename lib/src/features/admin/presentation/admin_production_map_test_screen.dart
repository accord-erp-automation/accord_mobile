import '../../../app/app_router.dart';
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
      x: 420,
      y: 32,
    ),
    const ProductionMapNode(
      id: 'cpp_calc',
      kind: 'formula',
      title: 'CPP hisob',
      itemCode: 'CPP',
      x: 420,
      y: 164,
      formula: ProductionFormula(
        target: 'cpp_kg',
        expression: 'order_qty * 1.08',
      ),
    ),
    const ProductionMapNode(
      id: 'qty_check',
      kind: 'condition',
      title: 'Katta partiyami?',
      x: 420,
      y: 296,
      formula: ProductionFormula(
        target: '',
        expression: 'order_qty >= 100',
      ),
    ),
    const ProductionMapNode(
      id: 'large_batch',
      kind: 'task',
      title: 'Katta partiya',
      roleCode: 'rezkachi',
      x: 140,
      y: 448,
    ),
    const ProductionMapNode(
      id: 'rezka_task',
      kind: 'task',
      title: 'Rezkaga yuborish',
      roleCode: 'rezkachi',
      x: 700,
      y: 448,
    ),
    const ProductionMapNode(
      id: 'end',
      kind: 'end',
      title: 'End',
      x: 420,
      y: 620,
    ),
  ];
  final edges = <ProductionMapEdge>[
    const ProductionMapEdge(from: 'start', to: 'cpp_calc'),
    const ProductionMapEdge(from: 'cpp_calc', to: 'qty_check'),
    const ProductionMapEdge(
        from: 'qty_check', to: 'large_batch', branch: 'true'),
    const ProductionMapEdge(
        from: 'qty_check', to: 'rezka_task', branch: 'false'),
    const ProductionMapEdge(from: 'large_batch', to: 'end'),
    const ProductionMapEdge(from: 'rezka_task', to: 'end'),
  ];

  bool saving = false;
  bool running = false;
  int _nextNodeIndex = 1;

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

  Future<void> _run() async {
    final qty = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _RunMapSheet(),
    );
    if (qty == null || qty <= 0 || !mounted) {
      return;
    }
    setState(() => running = true);
    try {
      final result = await MobileApi.instance.adminRunProductionMap(
        ProductionMapRunRequest(
          mapId: mapID,
          productCode: productCode,
          orderQty: qty,
        ),
      );
      if (!mounted) {
        return;
      }
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _RunResultSheet(result: result),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hisoblash bajarilmadi: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => running = false);
      }
    }
  }

  void _addNode(String kind) {
    final id = '${kind}_${_nextNodeIndex++}';
    setState(() {
      if (kind == 'condition') {
        _addConditionBranch(id);
      } else {
        _insertBeforeEnd(_newNode(id, kind));
      }
    });
  }

  ProductionMapNode _newNode(String id, String kind) {
    final end = nodes.firstWhere((node) => node.kind == 'end');
    return switch (kind) {
      'material' => ProductionMapNode(
          id: id,
          kind: 'material',
          title: 'Material tanlash',
          itemCode: 'CPP',
          x: end.x,
          y: end.y - 132,
        ),
      'formula' => ProductionMapNode(
          id: id,
          kind: 'formula',
          title: 'Hisob kitob',
          x: end.x,
          y: end.y - 132,
          formula: const ProductionFormula(
            target: 'result_kg',
            expression: 'order_qty',
          ),
        ),
      'wait' => ProductionMapNode(
          id: id,
          kind: 'wait',
          title: 'Material kutish',
          x: end.x,
          y: end.y - 132,
        ),
      'output' => ProductionMapNode(
          id: id,
          kind: 'output',
          title: 'Natija chiqarish',
          itemCode: productCode,
          x: end.x,
          y: end.y - 132,
        ),
      _ => ProductionMapNode(
          id: id,
          kind: 'task',
          title: 'Yangi location',
          roleCode: 'worker',
          x: end.x,
          y: end.y - 132,
        ),
    };
  }

  void _insertBeforeEnd(ProductionMapNode node) {
    final endIndex = nodes.indexWhere((item) => item.kind == 'end');
    final previous = nodes[endIndex - 1];
    final end = nodes[endIndex];
    nodes.insert(endIndex, node);
    edges.removeWhere((edge) => edge.from == previous.id && edge.to == end.id);
    edges
      ..add(ProductionMapEdge(from: previous.id, to: node.id))
      ..add(ProductionMapEdge(from: node.id, to: end.id));
    _pushEndDown();
  }

  void _addConditionBranch(String id) {
    final endIndex = nodes.indexWhere((item) => item.kind == 'end');
    final previous = nodes[endIndex - 1];
    final end = nodes[endIndex];
    final condition = ProductionMapNode(
      id: id,
      kind: 'condition',
      title: 'Shart',
      x: end.x,
      y: end.y - 220,
      formula: const ProductionFormula(
        target: '',
        expression: 'order_qty >= 100',
      ),
    );
    final trueTask = ProductionMapNode(
      id: '${id}_true',
      kind: 'task',
      title: 'Ha yo‘li',
      roleCode: 'worker',
      x: end.x - 280,
      y: end.y - 68,
    );
    final falseTask = ProductionMapNode(
      id: '${id}_false',
      kind: 'task',
      title: 'Yo‘q yo‘li',
      roleCode: 'worker',
      x: end.x + 280,
      y: end.y - 68,
    );
    nodes
      ..insert(endIndex, condition)
      ..insert(endIndex + 1, trueTask)
      ..insert(endIndex + 2, falseTask);
    edges.removeWhere((edge) => edge.from == previous.id && edge.to == end.id);
    edges
      ..add(ProductionMapEdge(from: previous.id, to: condition.id))
      ..add(ProductionMapEdge(
        from: condition.id,
        to: trueTask.id,
        branch: 'true',
      ))
      ..add(ProductionMapEdge(
        from: condition.id,
        to: falseTask.id,
        branch: 'false',
      ))
      ..add(ProductionMapEdge(from: trueTask.id, to: end.id))
      ..add(ProductionMapEdge(from: falseTask.id, to: end.id));
    _pushEndDown();
  }

  void _pushEndDown() {
    final endIndex = nodes.indexWhere((node) => node.kind == 'end');
    final end = nodes[endIndex];
    final deepest = nodes
        .where((node) => node.id != end.id)
        .map((node) => node.y)
        .fold<double>(end.y, (max, y) => y > max ? y : max);
    nodes[endIndex] = end.copyWith(y: deepest + 172);
  }

  void _moveNode(String nodeID, Offset delta) {
    final index = nodes.indexWhere((node) => node.id == nodeID);
    if (index < 0) {
      return;
    }
    final node = nodes[index];
    setState(() {
      nodes[index] = node.copyWith(
        x: (node.x + delta.dx).clamp(24, 1060).toDouble(),
        y: (node.y + delta.dy).clamp(24, 1260).toDouble(),
      );
    });
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
      edges.removeWhere((edge) => edge.from == node.id || edge.to == node.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom + 136.0;
    return AppShell(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () {
          final nav = Navigator.of(context);
          if (nav.canPop()) {
            nav.pop();
          } else {
            nav.pushNamedAndRemoveUntil(
              AppRoutes.adminHome,
              (route) => false,
            );
          }
        },
      ),
      title: 'Production map test',
      subtitle: '',
      nativeTopBar: true,
      nativeTitleTextStyle: AppTheme.werkaNativeAppBarTitleStyle(context),
      contentPadding: EdgeInsets.zero,
      animateOnEnter: false,
      bottom: const AdminDock(activeTab: AdminDockTab.home),
      child: ColoredBox(
        color: scheme.surface,
        child: ListView(
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
                          label: 'Condition',
                          icon: Icons.call_split_rounded,
                          onTap: () => _addNode('condition'),
                          tonal: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PlainActionButton(
                          label: 'Material',
                          icon: Icons.inventory_2_rounded,
                          onTap: () => _addNode('material'),
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
                          label: 'Wait',
                          icon: Icons.hourglass_bottom_rounded,
                          onTap: () => _addNode('wait'),
                          tonal: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PlainActionButton(
                          label: 'Output',
                          icon: Icons.flag_rounded,
                          onTap: () => _addNode('output'),
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
                          label: running ? 'Hisoblanmoqda' : 'Hisoblash',
                          icon: Icons.play_arrow_rounded,
                          onTap: running ? null : _run,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PlainActionButton(
                          label: saving ? 'Saqlanyapti' : 'Saqlash',
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
            _ProductionMapCanvas(
              nodes: nodes,
              edges: edges,
              onNodeTap: (node) => _editNode(nodes.indexOf(node)),
              onNodeDelete: (node) => _deleteNode(nodes.indexOf(node)),
              onNodeMoved: _moveNode,
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
            onTapCancel:
                enabled ? () => setState(() => _pressed = false) : null,
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

class _ProductionMapCanvas extends StatelessWidget {
  const _ProductionMapCanvas({
    required this.nodes,
    required this.edges,
    required this.onNodeTap,
    required this.onNodeDelete,
    required this.onNodeMoved,
  });

  static const _canvasSize = Size(1180, 900);
  static const _nodeSize = Size(260, 82);

  final List<ProductionMapNode> nodes;
  final List<ProductionMapEdge> edges;
  final ValueChanged<ProductionMapNode> onNodeTap;
  final ValueChanged<ProductionMapNode> onNodeDelete;
  final void Function(String nodeID, Offset delta) onNodeMoved;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: SizedBox(
          height: 560,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _GridPaperPainter(scheme: scheme),
                ),
              ),
              InteractiveViewer(
                constrained: false,
                minScale: 0.35,
                maxScale: 2.4,
                boundaryMargin: const EdgeInsets.all(420),
                child: SizedBox(
                  width: _canvasSize.width,
                  height: _canvasSize.height,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        width: _canvasSize.width,
                        height: _canvasSize.height,
                        child: CustomPaint(
                          size: _canvasSize,
                          painter: _MapCanvasPainter(
                            nodes: nodes,
                            edges: edges,
                            nodeSize: _nodeSize,
                            scheme: scheme,
                          ),
                        ),
                      ),
                      for (final node in nodes)
                        Positioned(
                          left: node.x,
                          top: node.y,
                          width: _nodeSize.width,
                          child: Listener(
                            onPointerMove: (event) =>
                                onNodeMoved(node.id, event.delta),
                            child: _MapNodeVisual(
                              node: node,
                              onTap: () => onNodeTap(node),
                              onDelete:
                                  node.kind == 'start' || node.kind == 'end'
                                      ? null
                                      : () => onNodeDelete(node),
                              floating: false,
                              highlighted: false,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridPaperPainter extends CustomPainter {
  const _GridPaperPainter({required this.scheme});

  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    _paintGrid(canvas, size, scheme);
  }

  @override
  bool shouldRepaint(covariant _GridPaperPainter oldDelegate) {
    return oldDelegate.scheme != scheme;
  }
}

void _paintGrid(Canvas canvas, Size size, ColorScheme scheme) {
  final gridColor = scheme.brightness == Brightness.dark
      ? scheme.onSurface.withValues(alpha: 0.24)
      : scheme.outlineVariant.withValues(alpha: 0.42);
  final paint = Paint()
    ..color = gridColor
    ..strokeWidth = 1;
  for (var x = 0.0; x <= size.width; x += 40) {
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
  }
  for (var y = 0.0; y <= size.height; y += 40) {
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }
}

class _MapCanvasPainter extends CustomPainter {
  const _MapCanvasPainter({
    required this.nodes,
    required this.edges,
    required this.nodeSize,
    required this.scheme,
  });

  final List<ProductionMapNode> nodes;
  final List<ProductionMapEdge> edges;
  final Size nodeSize;
  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    final byID = {
      for (final node in nodes) node.id: node,
    };
    for (final edge in edges) {
      final from = byID[edge.from];
      final to = byID[edge.to];
      if (from == null || to == null) {
        continue;
      }
      _paintEdge(canvas, from, to, edge.branch);
    }
  }

  void _paintEdge(
    Canvas canvas,
    ProductionMapNode from,
    ProductionMapNode to,
    String branch,
  ) {
    final start = Offset(from.x + nodeSize.width / 2, from.y + nodeSize.height);
    final end = Offset(to.x + nodeSize.width / 2, to.y);
    final controlY = start.dy + ((end.dy - start.dy) / 2);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(start.dx, controlY, end.dx, controlY, end.dx, end.dy);
    final branchKey = branch.trim().toLowerCase();
    final color = switch (branchKey) {
      'true' => scheme.primary,
      'false' => scheme.error,
      _ => scheme.onSurfaceVariant,
    };
    final paint = Paint()
      ..color = color.withValues(alpha: 0.76)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);
    _paintArrow(canvas, end, color);
    if (branchKey.isNotEmpty) {
      _paintBranchLabel(
        canvas,
        Offset((start.dx + end.dx) / 2, controlY - 16),
        branchKey == 'true' ? 'Ha' : 'Yo‘q',
        color,
      );
    }
  }

  void _paintArrow(Canvas canvas, Offset tip, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx - 7, tip.dy - 11)
      ..lineTo(tip.dx + 7, tip.dy - 11)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _paintBranchLabel(
    Canvas canvas,
    Offset center,
    String label,
    Color color,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: scheme.onPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final rect = Rect.fromCenter(
      center: center,
      width: textPainter.width + 18,
      height: textPainter.height + 10,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(99));
    canvas.drawRRect(rrect, Paint()..color = color);
    textPainter.paint(
      canvas,
      Offset(
        rect.left + (rect.width - textPainter.width) / 2,
        rect.top + (rect.height - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _MapCanvasPainter oldDelegate) {
    return oldDelegate.nodes != nodes ||
        oldDelegate.edges != edges ||
        oldDelegate.scheme != scheme;
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _subtitleFor(node),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
      'condition' => Icons.call_split_rounded,
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
      'condition' => 'if',
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
      if (node.kind == 'condition') {
        return formula.expression;
      }
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
      'condition' => scheme.primaryContainer,
      'task' => scheme.secondaryContainer,
      'wait' => scheme.errorContainer,
      'output' => scheme.primaryContainer,
      _ => scheme.surfaceContainerHighest,
    };
  }

  BorderRadius _shapeFor(String kind) {
    return BorderRadius.circular(28);
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
              if (widget.node.kind == 'condition') ...[
                const SizedBox(height: 10),
                _SheetField(
                  label: 'Shart',
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
        formula:
            widget.node.kind == 'formula' || widget.node.kind == 'condition'
                ? ProductionFormula(
                    target: widget.node.kind == 'condition'
                        ? ''
                        : formulaTarget.isEmpty
                            ? 'result'
                            : formulaTarget,
                    expression: formulaExpression.isEmpty
                        ? widget.node.formula?.expression ?? 'order_qty'
                        : formulaExpression,
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

class _RunMapSheet extends StatefulWidget {
  const _RunMapSheet();

  @override
  State<_RunMapSheet> createState() => _RunMapSheetState();
}

class _RunMapSheetState extends State<_RunMapSheet> {
  final _qty = TextEditingController(text: '100');

  @override
  void dispose() {
    _qty.dispose();
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
                'Production hisob',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _qty,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Buyurtma miqdori',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _PlainActionButton(
                label: 'Hisoblash',
                icon: Icons.play_arrow_rounded,
                onTap: _run,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _run() {
    final qty = double.tryParse(_qty.text.trim().replaceAll(',', '.')) ?? 0;
    if (qty <= 0) {
      return;
    }
    Navigator.of(context).pop(qty);
  }
}

class _RunResultSheet extends StatelessWidget {
  const _RunResultSheet({required this.result});

  final ProductionMapRunResult result;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final variables = result.variables.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return SafeArea(
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
              'Run natijasi',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 12),
            for (final variable in variables)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.functions_rounded),
                title: Text(variable.key),
                trailing: Text(_formatQty(variable.value)),
              ),
            if (result.tasks.isNotEmpty) ...[
              const Divider(height: 24),
              for (final task in result.tasks)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.engineering_rounded),
                  title: Text(task.title),
                  subtitle: Text([
                    if (task.roleCode.trim().isNotEmpty) task.roleCode,
                    if (task.itemCode.trim().isNotEmpty) task.itemCode,
                    task.taskKind,
                  ].join(' · ')),
                  trailing: Text(_formatQty(task.qty)),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatQty(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(3);
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
