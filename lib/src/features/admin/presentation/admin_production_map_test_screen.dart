import 'dart:math' as math;

import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/feedback/m3_confirm_dialog.dart';
import '../../../core/widgets/shell/app_shell.dart';
import '../../shared/models/app_models.dart';
import '../../werka/presentation/widgets/m3_picker_sheet.dart';
import '../models/production_map_models.dart';
import 'widgets/admin_create_hub_sheet.dart';
import 'widgets/admin_dock.dart';
import 'package:flutter/material.dart';

String productionMapBranchDisplayLabel(String branch) {
  return switch (branch.trim().toLowerCase()) {
    'true' => 'Shunda',
    'false' => 'Aks holda',
    _ => branch,
  };
}

class AdminProductionMapTestScreen extends StatefulWidget {
  const AdminProductionMapTestScreen({super.key});

  @override
  State<AdminProductionMapTestScreen> createState() =>
      _AdminProductionMapTestScreenState();
}

class _AdminProductionMapTestScreenState
    extends State<AdminProductionMapTestScreen> {
  static const _nodeGap = 18.0;
  static const _nodeStepX = 280.0;
  static const _nodeStepY = 132.0;
  static const _minNodeX = 24.0;
  static const _minNodeY = 24.0;
  static const _maxNodeX = 1600.0;
  static const _maxNodeY = 3200.0;

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
      qtyFormula: 'cpp_kg',
      fromLocation: 'CPP ombor',
      toLocation: 'Rezka apparat',
      x: 140,
      y: 448,
    ),
    const ProductionMapNode(
      id: 'rezka_task',
      kind: 'task',
      title: 'Rezkaga yuborish',
      roleCode: 'rezkachi',
      qtyFormula: 'order_qty / 6',
      fromLocation: 'CPP ombor',
      toLocation: 'Rezka apparat',
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
  String? _connectingFromNodeID;
  String _connectingFromBranch = '';
  Offset? _connectionPreviewEnd;
  bool _mapToolsMenuOpen = false;
  Set<String> _runVisitedNodeIDs = const {};
  String _runAwaitingNodeID = '';

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
    final input = await showModalBottomSheet<_RunMapInput>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _RunMapSheet(),
    );
    if (input == null || input.orderQty <= 0 || !mounted) {
      return;
    }
    setState(() => running = true);
    try {
      final variables = Map<String, double>.of(input.variables);
      while (mounted) {
        final result = await MobileApi.instance.adminRunProductionMap(
          ProductionMapRunRequest(
            mapId: mapID,
            productCode: productCode,
            orderQty: input.orderQty,
            variables: variables,
          ),
        );
        if (!mounted) {
          return;
        }
        setState(() {
          _runVisitedNodeIDs = result.visitedNodeIds.toSet();
          _runAwaitingNodeID = result.awaitingNodeId;
        });
        final next = await showModalBottomSheet<_RuntimeVariableInput>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => _RunResultSheet(result: result),
        );
        if (next == null || next.name.trim().isEmpty) {
          break;
        }
        variables[next.name.trim()] = next.value;
      }
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
          qtyFormula: 'order_qty',
          fromLocation: 'Ombor',
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
          qtyFormula: 'order_qty',
          toLocation: 'Tayyor mahsulot ombori',
          x: end.x,
          y: end.y - 132,
        ),
      _ => ProductionMapNode(
          id: id,
          kind: 'task',
          title: 'Yangi location',
          roleCode: 'worker',
          qtyFormula: 'order_qty',
          x: end.x,
          y: end.y - 132,
        ),
    };
  }

  void _insertBeforeEnd(ProductionMapNode node) {
    final endIndex = nodes.indexWhere((item) => item.kind == 'end');
    final previous = nodes[endIndex - 1];
    final end = nodes[endIndex];
    final placedNode = _placeNode(
      node.copyWith(
        x: previous.x,
        y: previous.y + _nodeStepY,
      ),
      ignoreIds: {end.id},
    );
    nodes.insert(endIndex, placedNode);
    edges.removeWhere((edge) => edge.from == previous.id && edge.to == end.id);
    edges
      ..add(ProductionMapEdge(from: previous.id, to: placedNode.id))
      ..add(ProductionMapEdge(from: placedNode.id, to: end.id));
    _pushEndDown();
  }

  void _addConditionBranch(String id) {
    final endIndex = nodes.indexWhere((item) => item.kind == 'end');
    final previous = nodes[endIndex - 1];
    final end = nodes[endIndex];
    final condition = _placeNode(
      ProductionMapNode(
        id: id,
        kind: 'condition',
        title: 'Shart',
        x: previous.x,
        y: previous.y + _nodeStepY,
        formula: const ProductionFormula(
          target: '',
          expression: 'order_qty >= 100',
        ),
      ),
      ignoreIds: {end.id},
    );
    nodes.insert(endIndex, condition);
    edges.removeWhere((edge) => edge.from == previous.id && edge.to == end.id);
    edges.add(ProductionMapEdge(from: previous.id, to: condition.id));
    _pushEndDown();
  }

  void _pushEndDown() {
    final endIndex = nodes.indexWhere((node) => node.kind == 'end');
    final end = nodes[endIndex];
    final deepest = nodes
        .where((node) => node.id != end.id)
        .map((node) => node.y)
        .fold<double>(end.y, (max, y) => y > max ? y : max);
    nodes[endIndex] = _placeNode(
      end.copyWith(y: deepest + _nodeStepY),
      ignoreIds: {end.id},
    );
  }

  void _moveNode(String nodeID, Offset delta) {
    final index = nodes.indexWhere((node) => node.id == nodeID);
    if (index < 0) {
      return;
    }
    final node = nodes[index];
    setState(() {
      final position = _clampNodePosition(Offset(node.x, node.y) + delta);
      nodes[index] = node.copyWith(x: position.dx, y: position.dy);
      _resolveNodeOverlaps(anchorID: nodeID);
    });
  }

  void _startConnection(String nodeID, [String branch = '']) {
    setState(() {
      _connectingFromNodeID = nodeID;
      _connectingFromBranch = branch.trim().toLowerCase();
      _connectionPreviewEnd = null;
    });
  }

  void _updateConnectionPreview(Offset canvasPosition) {
    if (_connectingFromNodeID == null) {
      return;
    }
    setState(() => _connectionPreviewEnd = canvasPosition);
  }

  void _finishConnection(Offset canvasPosition) {
    final fromID = _connectingFromNodeID;
    final branchKey = _connectingFromBranch;
    setState(() {
      _connectingFromNodeID = null;
      _connectingFromBranch = '';
      _connectionPreviewEnd = null;
      if (fromID == null) {
        return;
      }
      final target = _nodeAt(canvasPosition, exceptID: fromID);
      if (target == null) {
        return;
      }
      final exists = edges.any((edge) =>
          edge.from == fromID &&
          edge.to == target.id &&
          edge.branch.trim().toLowerCase() == branchKey);
      if (!exists) {
        if (branchKey.isNotEmpty) {
          edges.removeWhere((edge) =>
              edge.from == fromID &&
              edge.branch.trim().toLowerCase() == branchKey);
        }
        edges.add(
          ProductionMapEdge(from: fromID, to: target.id, branch: branchKey),
        );
      }
    });
  }

  void _cancelConnection() {
    setState(() {
      _connectingFromNodeID = null;
      _connectingFromBranch = '';
      _connectionPreviewEnd = null;
    });
  }

  Future<void> _confirmDetachBranch(
    ProductionMapNode node,
    String branch,
  ) async {
    final branchLabel = productionMapBranchDisplayLabel(branch);
    final confirmed = await showM3ConfirmDialog(
      context: context,
      title: 'Uzaymi?',
      message: '$branchLabel yo‘li ulangan carddan ajratiladi.',
      cancelLabel: 'Yo‘q',
      confirmLabel: 'Uzish',
      destructive: true,
      blurBackground: true,
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final branchKey = branch.trim().toLowerCase();
    setState(() {
      edges.removeWhere(
        (edge) =>
            edge.from == node.id &&
            edge.branch.trim().toLowerCase() == branchKey,
      );
    });
  }

  ProductionMapNode? _nodeAt(Offset position, {required String exceptID}) {
    for (final node in nodes.reversed) {
      if (node.id == exceptID) {
        continue;
      }
      final rect = Rect.fromLTWH(
        node.x,
        node.y,
        _ProductionMapCanvas._nodeSize.width,
        _ProductionMapCanvas._nodeSize.height,
      );
      if (rect.contains(position)) {
        return node;
      }
    }
    return null;
  }

  ProductionMapNode _placeNode(
    ProductionMapNode node, {
    Set<String> ignoreIds = const {},
    List<ProductionMapNode> extraNodes = const [],
  }) {
    final position = _firstFreePosition(
      Offset(node.x, node.y),
      nodeID: node.id,
      ignoreIds: ignoreIds,
      extraNodes: extraNodes,
    );
    return node.copyWith(x: position.dx, y: position.dy);
  }

  Offset _firstFreePosition(
    Offset preferred, {
    required String nodeID,
    Set<String> ignoreIds = const {},
    List<ProductionMapNode> extraNodes = const [],
  }) {
    final origin = _clampNodePosition(preferred);
    final tried = <String>{};
    for (var row = 0; row < 80; row++) {
      for (final column in const [0, -1, 1, -2, 2, -3, 3, -4, 4]) {
        final position = _clampNodePosition(
          Offset(
            origin.dx + column * _nodeStepX,
            origin.dy + row * _nodeStepY,
          ),
        );
        final key = '${position.dx}:${position.dy}';
        if (!tried.add(key)) {
          continue;
        }
        if (!_positionOverlapsAny(
          position,
          nodeID: nodeID,
          ignoreIds: ignoreIds,
          extraNodes: extraNodes,
        )) {
          return position;
        }
      }
    }
    return origin;
  }

  void _resolveNodeOverlaps({required String anchorID}) {
    for (var pass = 0; pass < 80; pass++) {
      var moved = false;
      for (var a = 0; a < nodes.length; a++) {
        for (var b = a + 1; b < nodes.length; b++) {
          final separation = _overlapSeparation(nodes[a], nodes[b]);
          if (separation == Offset.zero) {
            continue;
          }
          moved = true;
          if (nodes[a].id == anchorID) {
            _moveNodeByIndex(b, separation);
          } else if (nodes[b].id == anchorID) {
            _moveNodeByIndex(a, -separation);
          } else {
            _moveNodeByIndex(a, -separation / 2);
            _moveNodeByIndex(b, separation / 2);
          }
        }
      }
      if (!moved) {
        _repackRemainingOverlaps(anchorID: anchorID);
        return;
      }
    }
    _repackRemainingOverlaps(anchorID: anchorID);
  }

  Offset _overlapSeparation(ProductionMapNode a, ProductionMapNode b) {
    final aRect = _collisionRectAt(Offset(a.x, a.y));
    final bRect = _collisionRectAt(Offset(b.x, b.y));
    if (!aRect.overlaps(bRect)) {
      return Offset.zero;
    }
    final overlapX =
        math.min(aRect.right - bRect.left, bRect.right - aRect.left);
    final overlapY =
        math.min(aRect.bottom - bRect.top, bRect.bottom - aRect.top);
    if (overlapX <= 0 || overlapY <= 0) {
      return Offset.zero;
    }
    if (overlapX <= overlapY) {
      final direction = bRect.center.dx >= aRect.center.dx ? 1.0 : -1.0;
      return Offset((overlapX + 0.5) * direction, 0);
    }
    final direction = bRect.center.dy >= aRect.center.dy ? 1.0 : -1.0;
    return Offset(0, (overlapY + 0.5) * direction);
  }

  void _moveNodeByIndex(int index, Offset delta) {
    final node = nodes[index];
    final position = _clampNodePosition(Offset(node.x, node.y) + delta);
    nodes[index] = node.copyWith(x: position.dx, y: position.dy);
  }

  void _repackRemainingOverlaps({required String anchorID}) {
    for (var pass = 0; pass < nodes.length; pass++) {
      var changed = false;
      for (var i = 0; i < nodes.length; i++) {
        final node = nodes[i];
        if (node.id == anchorID || !_nodeOverlapsAny(node)) {
          continue;
        }
        final position = _firstFreePosition(
          Offset(node.x, node.y),
          nodeID: node.id,
        );
        if (position.dx != node.x || position.dy != node.y) {
          nodes[i] = node.copyWith(x: position.dx, y: position.dy);
          changed = true;
        }
      }
      if (!changed) {
        return;
      }
    }
  }

  bool _nodeOverlapsAny(ProductionMapNode node) {
    return _positionOverlapsAny(
      Offset(node.x, node.y),
      nodeID: node.id,
    );
  }

  Offset _clampNodePosition(Offset position) {
    return Offset(
      position.dx.clamp(_minNodeX, _maxNodeX).toDouble(),
      position.dy.clamp(_minNodeY, _maxNodeY).toDouble(),
    );
  }

  bool _positionOverlapsAny(
    Offset position, {
    required String nodeID,
    Set<String> ignoreIds = const {},
    List<ProductionMapNode> extraNodes = const [],
  }) {
    final candidate = _collisionRectAt(position);
    for (final node in [...nodes, ...extraNodes]) {
      if (node.id == nodeID || ignoreIds.contains(node.id)) {
        continue;
      }
      if (candidate.overlaps(_collisionRectAt(Offset(node.x, node.y)))) {
        return true;
      }
    }
    return false;
  }

  Rect _collisionRectAt(Offset position) {
    return Rect.fromLTWH(
      position.dx,
      position.dy,
      _ProductionMapCanvas._nodeSize.width,
      _ProductionMapCanvas._nodeSize.height,
    ).inflate(_nodeGap / 2);
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

  void _toggleMapToolsMenu() {
    setState(() => _mapToolsMenuOpen = !_mapToolsMenuOpen);
  }

  void _closeMapToolsMenu() {
    if (!_mapToolsMenuOpen) {
      return;
    }
    setState(() => _mapToolsMenuOpen = false);
  }

  void _runMapToolAction(VoidCallback action) {
    _closeMapToolsMenu();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        action();
      }
    });
  }

  List<AdminFabMenuAction> _mapToolActions() {
    return [
      AdminFabMenuAction(
        title: 'Map ma’lumotlari',
        icon: Icons.edit_rounded,
        onTap: () => _runMapToolAction(_editMapInfo),
      ),
      AdminFabMenuAction(
        title: 'Mahsulot',
        icon: Icons.inventory_2_rounded,
        onTap: () => _runMapToolAction(_openProductPicker),
      ),
      AdminFabMenuAction(
        title: 'Location',
        icon: Icons.account_tree_rounded,
        onTap: () => _runMapToolAction(() => _addNode('task')),
      ),
      AdminFabMenuAction(
        title: 'Formula',
        icon: Icons.functions_rounded,
        onTap: () => _runMapToolAction(() => _addNode('formula')),
      ),
      AdminFabMenuAction(
        title: 'Condition',
        icon: Icons.call_split_rounded,
        onTap: () => _runMapToolAction(() => _addNode('condition')),
      ),
      AdminFabMenuAction(
        title: 'Material',
        icon: Icons.inventory_2_rounded,
        onTap: () => _runMapToolAction(() => _addNode('material')),
      ),
      AdminFabMenuAction(
        title: 'Wait',
        icon: Icons.hourglass_bottom_rounded,
        onTap: () => _runMapToolAction(() => _addNode('wait')),
      ),
      AdminFabMenuAction(
        title: 'Output',
        icon: Icons.flag_rounded,
        onTap: () => _runMapToolAction(() => _addNode('output')),
      ),
      AdminFabMenuAction(
        title: running ? 'Hisoblanmoqda' : 'Hisoblash',
        icon: Icons.play_arrow_rounded,
        enabled: !running,
        onTap: () => _runMapToolAction(_run),
      ),
      AdminFabMenuAction(
        title: saving ? 'Saqlanyapti' : 'Saqlash',
        icon: Icons.check_rounded,
        enabled: !saving,
        onTap: () => _runMapToolAction(_save),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fabBottom = MediaQuery.viewPaddingOf(context).bottom + 92.0;
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
        child: Stack(
          children: [
            Positioned.fill(
              child: _ProductionMapCanvas(
                nodes: nodes,
                edges: edges,
                connectingFromNodeID: _connectingFromNodeID,
                connectingFromBranch: _connectingFromBranch,
                connectionPreviewEnd: _connectionPreviewEnd,
                runVisitedNodeIDs: _runVisitedNodeIDs,
                runAwaitingNodeID: _runAwaitingNodeID,
                onNodeTap: (node) => _editNode(nodes.indexOf(node)),
                onNodeDelete: (node) => _deleteNode(nodes.indexOf(node)),
                onNodeMoved: _moveNode,
                onConnectionStart: _startConnection,
                onConnectionUpdate: _updateConnectionPreview,
                onConnectionEnd: _finishConnection,
                onConnectionCancel: _cancelConnection,
                onBranchDetach: _confirmDetachBranch,
              ),
            ),
            if (_mapToolsMenuOpen)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _closeMapToolsMenu,
                  child: ColoredBox(
                    color: scheme.scrim.withValues(alpha: 0.16),
                  ),
                ),
              ),
            Positioned(
              left: 16,
              bottom: fabBottom,
              child: AdminFabActionMenu(
                open: _mapToolsMenuOpen,
                actions: _mapToolActions(),
                onToggle: _toggleMapToolsMenu,
                closedLabel: 'Map sozlamalari',
                openLabel: 'Yopish',
                closedIcon: Icons.tune_rounded,
                alignEnd: false,
                columns: 2,
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
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  State<_PlainActionButton> createState() => _PlainActionButtonState();
}

class _PlainActionButtonState extends State<_PlainActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = widget.onTap != null;
    final background = scheme.primary;
    final foreground = scheme.onPrimary;
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

class _ProductionMapCanvas extends StatefulWidget {
  const _ProductionMapCanvas({
    required this.nodes,
    required this.edges,
    required this.connectingFromNodeID,
    required this.connectingFromBranch,
    required this.connectionPreviewEnd,
    required this.runVisitedNodeIDs,
    required this.runAwaitingNodeID,
    required this.onNodeTap,
    required this.onNodeDelete,
    required this.onNodeMoved,
    required this.onConnectionStart,
    required this.onConnectionUpdate,
    required this.onConnectionEnd,
    required this.onConnectionCancel,
    required this.onBranchDetach,
  });

  static const _minCanvasSize = Size(1180, 900);
  static const _nodeSize = Size(260, 82);

  final List<ProductionMapNode> nodes;
  final List<ProductionMapEdge> edges;
  final String? connectingFromNodeID;
  final String connectingFromBranch;
  final Offset? connectionPreviewEnd;
  final Set<String> runVisitedNodeIDs;
  final String runAwaitingNodeID;
  final ValueChanged<ProductionMapNode> onNodeTap;
  final ValueChanged<ProductionMapNode> onNodeDelete;
  final void Function(String nodeID, Offset delta) onNodeMoved;
  final void Function(String nodeID, String branch) onConnectionStart;
  final ValueChanged<Offset> onConnectionUpdate;
  final ValueChanged<Offset> onConnectionEnd;
  final VoidCallback onConnectionCancel;
  final void Function(ProductionMapNode node, String branch) onBranchDetach;

  @override
  State<_ProductionMapCanvas> createState() => _ProductionMapCanvasState();
}

class _ProductionMapCanvasState extends State<_ProductionMapCanvas> {
  final _canvasKey = GlobalKey();
  late final TransformationController _transformController;
  bool _didSetInitialTransform = false;
  Offset? _lastConnectionPosition;

  @override
  void initState() {
    super.initState();
    _transformController = TransformationController();
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canvasSize = _canvasSizeFor(widget.nodes);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.56),
        ),
      ),
      child: SizedBox.expand(
        child: LayoutBuilder(
          builder: (context, constraints) {
            _scheduleInitialTransform(
              viewportSize: constraints.biggest,
              canvasSize: canvasSize,
            );
            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _GridPaperPainter(scheme: scheme),
                  ),
                ),
                InteractiveViewer(
                  transformationController: _transformController,
                  constrained: false,
                  minScale: 0.45,
                  maxScale: 2.4,
                  boundaryMargin: const EdgeInsets.all(760),
                  child: SizedBox(
                    key: _canvasKey,
                    width: canvasSize.width,
                    height: canvasSize.height,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: 0,
                          top: 0,
                          width: canvasSize.width,
                          height: canvasSize.height,
                          child: CustomPaint(
                            size: canvasSize,
                            painter: _MapCanvasPainter(
                              nodes: widget.nodes,
                              edges: widget.edges,
                              connectionFromNodeID: widget.connectingFromNodeID,
                              connectionFromBranch: widget.connectingFromBranch,
                              connectionPreviewEnd: widget.connectionPreviewEnd,
                              nodeSize: _ProductionMapCanvas._nodeSize,
                              scheme: scheme,
                            ),
                          ),
                        ),
                        for (final node in widget.nodes)
                          Positioned(
                            left: node.x,
                            top: node.y,
                            width: _ProductionMapCanvas._nodeSize.width,
                            child: _MapNodeVisual(
                              node: node,
                              onTap: () => widget.onNodeTap(node),
                              onDragUpdate: (details) {
                                final scale = _transformController.value
                                    .getMaxScaleOnAxis();
                                widget.onNodeMoved(
                                  node.id,
                                  details.delta / scale,
                                );
                              },
                              onDelete:
                                  node.kind == 'start' || node.kind == 'end'
                                      ? null
                                      : () => widget.onNodeDelete(node),
                              onConnectionDragStart: (globalPosition) {
                                final canvasPosition = _globalToCanvas(
                                  globalPosition,
                                );
                                _lastConnectionPosition = canvasPosition;
                                widget.onConnectionStart(node.id, '');
                                widget.onConnectionUpdate(canvasPosition);
                              },
                              onConnectionDragUpdate: (globalPosition) {
                                final canvasPosition = _globalToCanvas(
                                  globalPosition,
                                );
                                _lastConnectionPosition = canvasPosition;
                                widget.onConnectionUpdate(canvasPosition);
                              },
                              onConnectionDragEnd: () {
                                final position = _lastConnectionPosition;
                                _lastConnectionPosition = null;
                                if (position == null) {
                                  widget.onConnectionCancel();
                                  return;
                                }
                                widget.onConnectionEnd(position);
                              },
                              onConnectionDragCancel: () {
                                _lastConnectionPosition = null;
                                widget.onConnectionCancel();
                              },
                              floating: false,
                              highlighted: widget.connectingFromNodeID ==
                                      node.id ||
                                  widget.runVisitedNodeIDs.contains(node.id),
                              awaiting: widget.runAwaitingNodeID == node.id,
                            ),
                          ),
                        for (final node in widget.nodes)
                          if (node.kind == 'condition') ...[
                            Positioned(
                              left: _branchButtonLeft(node, 'true'),
                              top: _branchButtonTop(node),
                              child: _BranchAddButton(
                                branch: 'true',
                                connected: _hasBranchEdge(node, 'true'),
                                onConnectionDragStart: (globalPosition) {
                                  final canvasPosition =
                                      _globalToCanvas(globalPosition);
                                  _lastConnectionPosition = canvasPosition;
                                  widget.onConnectionStart(node.id, 'true');
                                  widget.onConnectionUpdate(canvasPosition);
                                },
                                onConnectionDragUpdate: (globalPosition) {
                                  final canvasPosition =
                                      _globalToCanvas(globalPosition);
                                  _lastConnectionPosition = canvasPosition;
                                  widget.onConnectionUpdate(canvasPosition);
                                },
                                onConnectionDragEnd: () {
                                  final position = _lastConnectionPosition;
                                  _lastConnectionPosition = null;
                                  if (position == null) {
                                    widget.onConnectionCancel();
                                    return;
                                  }
                                  widget.onConnectionEnd(position);
                                },
                                onConnectionDragCancel: () {
                                  _lastConnectionPosition = null;
                                  widget.onConnectionCancel();
                                },
                                onDetachRequest: () =>
                                    widget.onBranchDetach(node, 'true'),
                              ),
                            ),
                            Positioned(
                              left: _branchButtonLeft(node, 'false'),
                              top: _branchButtonTop(node),
                              child: _BranchAddButton(
                                branch: 'false',
                                connected: _hasBranchEdge(node, 'false'),
                                onConnectionDragStart: (globalPosition) {
                                  final canvasPosition =
                                      _globalToCanvas(globalPosition);
                                  _lastConnectionPosition = canvasPosition;
                                  widget.onConnectionStart(node.id, 'false');
                                  widget.onConnectionUpdate(canvasPosition);
                                },
                                onConnectionDragUpdate: (globalPosition) {
                                  final canvasPosition =
                                      _globalToCanvas(globalPosition);
                                  _lastConnectionPosition = canvasPosition;
                                  widget.onConnectionUpdate(canvasPosition);
                                },
                                onConnectionDragEnd: () {
                                  final position = _lastConnectionPosition;
                                  _lastConnectionPosition = null;
                                  if (position == null) {
                                    widget.onConnectionCancel();
                                    return;
                                  }
                                  widget.onConnectionEnd(position);
                                },
                                onConnectionDragCancel: () {
                                  _lastConnectionPosition = null;
                                  widget.onConnectionCancel();
                                },
                                onDetachRequest: () =>
                                    widget.onBranchDetach(node, 'false'),
                              ),
                            ),
                          ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _scheduleInitialTransform({
    required Size viewportSize,
    required Size canvasSize,
  }) {
    if (_didSetInitialTransform || viewportSize.isEmpty) {
      return;
    }
    _didSetInitialTransform = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _transformController.value = _initialTransform(
        viewportSize: viewportSize,
        canvasSize: canvasSize,
      );
    });
  }

  Offset _globalToCanvas(Offset globalPosition) {
    final context = _canvasKey.currentContext;
    if (context == null) {
      return Offset.zero;
    }
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) {
      return Offset.zero;
    }
    return box.globalToLocal(globalPosition);
  }

  Matrix4 _initialTransform({
    required Size viewportSize,
    required Size canvasSize,
  }) {
    final bounds = _nodeBounds();
    if (bounds == null) {
      return Matrix4.identity();
    }
    const padding = 56.0;
    final scaleToFitWidth = viewportSize.width / (bounds.width + padding * 2);
    final readableScale = scaleToFitWidth.clamp(0.88, 1.08);
    final dx = viewportSize.width / 2 - bounds.center.dx * readableScale;
    final dy = padding - bounds.top * readableScale;
    final minDx = viewportSize.width - canvasSize.width * readableScale;
    final minDy = viewportSize.height - canvasSize.height * readableScale;
    final maxDx = math.max(minDx, padding);
    final maxDy = math.max(minDy, padding);
    return Matrix4.identity()
      ..setEntry(0, 0, readableScale)
      ..setEntry(1, 1, readableScale)
      ..setEntry(0, 3, dx.clamp(minDx, maxDx))
      ..setEntry(1, 3, dy.clamp(minDy, maxDy));
  }

  Rect? _nodeBounds() {
    Rect? bounds;
    for (final node in widget.nodes) {
      final rect = Rect.fromLTWH(
        node.x,
        node.y,
        _ProductionMapCanvas._nodeSize.width,
        _ProductionMapCanvas._nodeSize.height,
      );
      bounds = bounds == null ? rect : bounds.expandToInclude(rect);
    }
    return bounds;
  }

  Size _canvasSizeFor(List<ProductionMapNode> nodes) {
    var maxX = _ProductionMapCanvas._minCanvasSize.width;
    var maxY = _ProductionMapCanvas._minCanvasSize.height;
    for (final node in nodes) {
      final right = node.x + _ProductionMapCanvas._nodeSize.width + 320;
      final bottom = node.y + _ProductionMapCanvas._nodeSize.height + 360;
      if (right > maxX) {
        maxX = right;
      }
      if (bottom > maxY) {
        maxY = bottom;
      }
    }
    return Size(maxX, maxY);
  }

  double _branchButtonLeft(ProductionMapNode node, String branch) {
    const buttonWidth = _BranchAddButton.width;
    final left = switch (branch) {
      'true' => node.x - buttonWidth / 2,
      'false' =>
        node.x + _ProductionMapCanvas._nodeSize.width - buttonWidth / 2,
      _ => node.x,
    };
    return math.max(8, left);
  }

  double _branchButtonTop(ProductionMapNode node) {
    return node.y +
        _ProductionMapCanvas._nodeSize.height / 2 -
        _BranchAddButton.height / 2;
  }

  bool _hasBranchEdge(ProductionMapNode node, String branch) {
    final branchKey = branch.trim().toLowerCase();
    return widget.edges.any(
      (edge) =>
          edge.from == node.id && edge.branch.trim().toLowerCase() == branchKey,
    );
  }
}

class _BranchAddButton extends StatelessWidget {
  const _BranchAddButton({
    required this.branch,
    required this.connected,
    required this.onConnectionDragStart,
    required this.onConnectionDragUpdate,
    required this.onConnectionDragEnd,
    required this.onConnectionDragCancel,
    required this.onDetachRequest,
  });

  static const width = 34.0;
  static const height = 34.0;

  final String branch;
  final bool connected;
  final ValueChanged<Offset> onConnectionDragStart;
  final ValueChanged<Offset> onConnectionDragUpdate;
  final VoidCallback onConnectionDragEnd;
  final VoidCallback onConnectionDragCancel;
  final VoidCallback onDetachRequest;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final branchKey = branch.trim().toLowerCase();
    final color = switch (branchKey) {
      'true' => scheme.primaryContainer,
      'false' => scheme.errorContainer,
      _ => scheme.secondaryContainer,
    };
    final foreground = switch (branchKey) {
      'true' => scheme.onPrimaryContainer,
      'false' => scheme.onErrorContainer,
      _ => scheme.onSecondaryContainer,
    };
    return Tooltip(
      message: connected
          ? '${productionMapBranchDisplayLabel(branch)} yo‘lini ushlab uzish'
          : '${productionMapBranchDisplayLabel(branch)} yo‘liga qo‘l tortish',
      child: SizedBox(
        key: ValueKey('production-map-branch-add-$branch'),
        width: width,
        height: height,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) =>
              onConnectionDragStart(details.globalPosition),
          onPanUpdate: (details) =>
              onConnectionDragUpdate(details.globalPosition),
          onPanEnd: (_) => onConnectionDragEnd(),
          onPanCancel: onConnectionDragCancel,
          onLongPress: connected ? onDetachRequest : null,
          child: Material(
            color: color,
            borderRadius: BorderRadius.circular(99),
            elevation: 2,
            shadowColor: scheme.shadow.withValues(alpha: 0.18),
            clipBehavior: Clip.antiAlias,
            child: Icon(Icons.add_link_rounded, size: 18, color: foreground),
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
    required this.connectionFromNodeID,
    required this.connectionFromBranch,
    required this.connectionPreviewEnd,
    required this.nodeSize,
    required this.scheme,
  });

  final List<ProductionMapNode> nodes;
  final List<ProductionMapEdge> edges;
  final String? connectionFromNodeID;
  final String connectionFromBranch;
  final Offset? connectionPreviewEnd;
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
    final previewFromID = connectionFromNodeID;
    final previewEnd = connectionPreviewEnd;
    if (previewFromID != null && previewEnd != null) {
      final from = byID[previewFromID];
      if (from != null) {
        _paintPreviewEdge(canvas, from, previewEnd, connectionFromBranch);
      }
    }
  }

  void _paintEdge(
    Canvas canvas,
    ProductionMapNode from,
    ProductionMapNode to,
    String branch,
  ) {
    final fromRect = _nodeRect(from);
    final toRect = _nodeRect(to);
    final branchKey = branch.trim().toLowerCase();
    final start = _startAnchor(from, branchKey, toRect.center);
    final end = _edgeAnchor(toRect, fromRect.center);
    final verticalCurve = (toRect.center.dy - fromRect.center.dy).abs() >=
        (toRect.center.dx - fromRect.center.dx).abs();
    final path = Path()..moveTo(start.dx, start.dy);
    if (verticalCurve) {
      final controlY = start.dy + ((end.dy - start.dy) / 2);
      path.cubicTo(start.dx, controlY, end.dx, controlY, end.dx, end.dy);
    } else {
      final controlX = start.dx + ((end.dx - start.dx) / 2);
      path.cubicTo(controlX, start.dy, controlX, end.dy, end.dx, end.dy);
    }
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
    _paintArrow(canvas, end, start, color);
    if (branchKey.isNotEmpty) {
      _paintBranchLabel(
        canvas,
        Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2 - 16),
        productionMapBranchDisplayLabel(branchKey),
        color,
      );
    }
  }

  void _paintPreviewEdge(
    Canvas canvas,
    ProductionMapNode from,
    Offset previewEnd,
    String branch,
  ) {
    final branchKey = branch.trim().toLowerCase();
    final start = _startAnchor(from, branchKey, previewEnd);
    final controlX = start.dx + ((previewEnd.dx - start.dx) / 2);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(controlX, start.dy, controlX, previewEnd.dy, previewEnd.dx,
          previewEnd.dy);
    final color = switch (branchKey) {
      'true' => scheme.primary,
      'false' => scheme.error,
      _ => scheme.primary,
    };
    final paint = Paint()
      ..color = color.withValues(alpha: 0.82)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);
    canvas.drawCircle(previewEnd, 7, Paint()..color = color);
    if (branchKey.isNotEmpty) {
      _paintBranchLabel(
        canvas,
        Offset((start.dx + previewEnd.dx) / 2,
            (start.dy + previewEnd.dy) / 2 - 16),
        productionMapBranchDisplayLabel(branchKey),
        color,
      );
    }
  }

  Rect _nodeRect(ProductionMapNode node) {
    return Rect.fromLTWH(node.x, node.y, nodeSize.width, nodeSize.height);
  }

  Offset _startAnchor(
    ProductionMapNode node,
    String branchKey,
    Offset fallbackToward,
  ) {
    final rect = _nodeRect(node);
    if (node.kind != 'condition') {
      return _edgeAnchor(rect, fallbackToward);
    }
    return switch (branchKey) {
      'true' => Offset(rect.left, rect.center.dy),
      'false' => Offset(rect.right, rect.center.dy),
      _ => _edgeAnchor(rect, fallbackToward),
    };
  }

  Offset _edgeAnchor(Rect rect, Offset toward) {
    final center = rect.center;
    final dx = toward.dx - center.dx;
    final dy = toward.dy - center.dy;
    if (dx == 0 && dy == 0) {
      return center;
    }
    final halfWidth = rect.width / 2;
    final halfHeight = rect.height / 2;
    final ratio = math.max(dx.abs() / halfWidth, dy.abs() / halfHeight);
    return Offset(center.dx + dx / ratio, center.dy + dy / ratio);
  }

  void _paintArrow(Canvas canvas, Offset tip, Offset tail, Color color) {
    final angle = math.atan2(tip.dy - tail.dy, tip.dx - tail.dx);
    const arrowSize = 12.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        tip.dx - math.cos(angle - math.pi / 6) * arrowSize,
        tip.dy - math.sin(angle - math.pi / 6) * arrowSize,
      )
      ..lineTo(
        tip.dx - math.cos(angle + math.pi / 6) * arrowSize,
        tip.dy - math.sin(angle + math.pi / 6) * arrowSize,
      )
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
    return true;
  }
}

class _MapNodeVisual extends StatelessWidget {
  const _MapNodeVisual({
    required this.node,
    required this.onTap,
    required this.onDragUpdate,
    required this.onDelete,
    required this.onConnectionDragStart,
    required this.onConnectionDragUpdate,
    required this.onConnectionDragEnd,
    required this.onConnectionDragCancel,
    required this.floating,
    required this.highlighted,
    required this.awaiting,
  });

  final ProductionMapNode node;
  final VoidCallback onTap;
  final GestureDragUpdateCallback onDragUpdate;
  final VoidCallback? onDelete;
  final ValueChanged<Offset> onConnectionDragStart;
  final ValueChanged<Offset> onConnectionDragUpdate;
  final VoidCallback onConnectionDragEnd;
  final VoidCallback onConnectionDragCancel;
  final bool floating;
  final bool highlighted;
  final bool awaiting;

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
        onPanUpdate: onDragUpdate,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: _colorFor(node.kind, scheme),
            borderRadius: _shapeFor(node.kind),
            border: awaiting
                ? Border.all(color: scheme.error, width: 3)
                : highlighted
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
                const SizedBox(width: 8),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (details) =>
                      onConnectionDragStart(details.globalPosition),
                  onPanUpdate: (details) =>
                      onConnectionDragUpdate(details.globalPosition),
                  onPanEnd: (_) => onConnectionDragEnd(),
                  onPanCancel: onConnectionDragCancel,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.add_link_rounded,
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
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
      return [
        node.roleCode,
        if (node.qtyFormula.trim().isNotEmpty) node.qtyFormula,
      ].join(' · ');
    }
    if (node.itemCode.trim().isNotEmpty) {
      return [
        node.itemCode,
        if (node.qtyFormula.trim().isNotEmpty) node.qtyFormula,
      ].join(' · ');
    }
    if (node.qtyFormula.trim().isNotEmpty) {
      return node.qtyFormula;
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
  late final TextEditingController _qtyFormula;
  late final TextEditingController _fromLocation;
  late final TextEditingController _toLocation;
  late final TextEditingController _formulaTarget;
  late final TextEditingController _formulaExpression;

  @override
  void initState() {
    super.initState();
    final formula = widget.node.formula;
    _title = TextEditingController(text: widget.node.title);
    _itemCode = TextEditingController(text: widget.node.itemCode);
    _roleCode = TextEditingController(text: widget.node.roleCode);
    _qtyFormula = TextEditingController(text: widget.node.qtyFormula);
    _fromLocation = TextEditingController(text: widget.node.fromLocation);
    _toLocation = TextEditingController(text: widget.node.toLocation);
    _formulaTarget = TextEditingController(text: formula?.target ?? '');
    _formulaExpression = TextEditingController(text: formula?.expression ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _itemCode.dispose();
    _roleCode.dispose();
    _qtyFormula.dispose();
    _fromLocation.dispose();
    _toLocation.dispose();
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
              if (widget.node.kind == 'material' ||
                  widget.node.kind == 'task' ||
                  widget.node.kind == 'wait' ||
                  widget.node.kind == 'output') ...[
                const SizedBox(height: 10),
                _SheetField(
                  label: 'Miqdor formulasi',
                  controller: _qtyFormula,
                ),
                const SizedBox(height: 10),
                _SheetField(
                  label: 'Qayerdan',
                  controller: _fromLocation,
                ),
                const SizedBox(height: 10),
                _SheetField(
                  label: 'Qayerga',
                  controller: _toLocation,
                ),
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
        qtyFormula: _qtyFormula.text.trim(),
        fromLocation: _fromLocation.text.trim(),
        toLocation: _toLocation.text.trim(),
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

class _RunMapInput {
  const _RunMapInput({
    required this.orderQty,
    required this.variables,
  });

  final double orderQty;
  final Map<String, double> variables;
}

class _RuntimeVariableInput {
  const _RuntimeVariableInput({
    required this.name,
    required this.value,
  });

  final String name;
  final double value;
}

class _RunMapSheetState extends State<_RunMapSheet> {
  final _qty = TextEditingController(text: '100');
  final _variables = TextEditingController();

  @override
  void dispose() {
    _qty.dispose();
    _variables.dispose();
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
              const SizedBox(height: 10),
              TextField(
                controller: _variables,
                minLines: 2,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Runtime variablelar',
                  hintText: 'pechat_ok=1',
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
    Navigator.of(context).pop(
      _RunMapInput(
        orderQty: qty,
        variables: _parseVariables(_variables.text),
      ),
    );
  }

  Map<String, double> _parseVariables(String raw) {
    final variables = <String, double>{};
    for (final line in raw.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || !trimmed.contains('=')) {
        continue;
      }
      final parts = trimmed.split('=');
      final key = parts.first.trim();
      final value = double.tryParse(
        parts.sublist(1).join('=').trim().replaceAll(',', '.'),
      );
      if (key.isNotEmpty && value != null) {
        variables[key] = value;
      }
    }
    return variables;
  }
}

class _RunResultSheet extends StatefulWidget {
  const _RunResultSheet({required this.result});

  final ProductionMapRunResult result;

  @override
  State<_RunResultSheet> createState() => _RunResultSheetState();
}

class _RunResultSheetState extends State<_RunResultSheet> {
  late final TextEditingController _runtimeValue;

  @override
  void initState() {
    super.initState();
    _runtimeValue = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _runtimeValue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final result = widget.result;
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
            if (result.awaitingVariable.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.pending_actions_rounded),
                title: Text('${result.awaitingVariable} kutilmoqda'),
                subtitle: Text(result.awaitingExpression),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _runtimeValue,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: InputDecoration(
                  labelText: result.awaitingVariable,
                  hintText: '1 yoki 0',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _PlainActionButton(
                      label: 'Shunda',
                      icon: Icons.check_rounded,
                      onTap: () => _continueWith(1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PlainActionButton(
                      label: 'Aks holda',
                      icon: Icons.close_rounded,
                      onTap: () => _continueWith(0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _PlainActionButton(
                label: 'Qiymat bilan davom etish',
                icon: Icons.play_arrow_rounded,
                onTap: _continueWithTypedValue,
              ),
            ],
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
                    if (task.fromLocation.trim().isNotEmpty ||
                        task.toLocation.trim().isNotEmpty)
                      '${task.fromLocation.trim().isEmpty ? '—' : task.fromLocation} → ${task.toLocation.trim().isEmpty ? '—' : task.toLocation}',
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

  void _continueWithTypedValue() {
    final value =
        double.tryParse(_runtimeValue.text.trim().replaceAll(',', '.'));
    if (value == null) {
      return;
    }
    _continueWith(value);
  }

  void _continueWith(double value) {
    final name = widget.result.awaitingVariable.trim();
    if (name.isEmpty) {
      return;
    }
    Navigator.of(context).pop(
      _RuntimeVariableInput(name: name, value: value),
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
