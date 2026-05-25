import '../../../core/api/mobile_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shell/app_loading_indicator.dart';
import '../../../core/widgets/shell/app_shell.dart';
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
  final mapID = TextEditingController(text: 'hotlunch-test');
  final productCode = TextEditingController(text: 'HOTLUNCH');
  final title = TextEditingController(text: 'Hotlunch test map');
  final nodes = <ProductionMapNode>[
    const ProductionMapNode(
      id: 'start',
      kind: 'start',
      title: 'Start',
      x: 32,
      y: 72,
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
      x: 220,
      y: 72,
    ),
    const ProductionMapNode(
      id: 'rezka_task',
      kind: 'task',
      title: 'Rezkaga yuborish',
      roleCode: 'rezkachi',
      x: 420,
      y: 72,
    ),
    const ProductionMapNode(
      id: 'end',
      kind: 'end',
      title: 'End',
      x: 640,
      y: 72,
    ),
  ];
  final edges = <ProductionMapEdge>[
    const ProductionMapEdge(from: 'start', to: 'cpp_calc'),
    const ProductionMapEdge(from: 'cpp_calc', to: 'rezka_task'),
    const ProductionMapEdge(from: 'rezka_task', to: 'end'),
  ];
  ProductionMapProgram? program;
  bool saving = false;

  @override
  void dispose() {
    mapID.dispose();
    productCode.dispose();
    title.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      final saved = await MobileApi.instance.adminSaveProductionMap(
        ProductionMapDefinition(
          id: mapID.text.trim(),
          productCode: productCode.text.trim(),
          title: title.text.trim(),
          nodes: nodes,
          edges: edges,
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() => program = saved.program);
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

  void _addWaitNode() {
    final id = 'wait_${nodes.length}';
    setState(() {
      nodes.insert(
        nodes.length - 1,
        ProductionMapNode(
          id: id,
          kind: 'wait',
          title: 'Material kutish',
          x: 420,
          y: 210 + nodes.length * 18,
        ),
      );
      final last = edges.removeLast();
      edges
        ..add(ProductionMapEdge(from: last.from, to: id))
        ..add(ProductionMapEdge(from: id, to: last.to));
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom + 136.0;
    return AppShell(
      title: 'Production map test',
      subtitle: '',
      nativeTopBar: true,
      nativeTitleTextStyle: AppTheme.werkaNativeAppBarTitleStyle(context),
      contentPadding: EdgeInsets.zero,
      bottom: const AdminDock(activeTab: null),
      child: ColoredBox(
        color: scheme.surface,
        child: ListView(
          padding: EdgeInsets.fromLTRB(12, 12, 12, bottomPadding),
          children: [
            _SurfacePanel(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _Field(controller: mapID, label: 'Map ID'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _Field(
                          controller: productCode,
                          label: 'Product code',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _Field(controller: title, label: 'Map nomi'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: _addWaitNode,
                        icon: const Icon(Icons.hourglass_bottom_rounded),
                        label: const Text('Wait node'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: saving ? null : _save,
                          icon: saving
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: AppLoadingIndicator(
                                    size: 18,
                                    glyphSize: 14,
                                  ),
                                )
                              : const Icon(Icons.check_rounded),
                          label: Text(
                            saving ? 'Saqlanyapti' : 'Save + compile',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 320,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: scheme.outlineVariant),
              ),
              clipBehavior: Clip.antiAlias,
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 2.5,
                boundaryMargin: const EdgeInsets.all(220),
                child: SizedBox(
                  width: 840,
                  height: 360,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _MapEdgePainter(
                            nodes: nodes,
                            edges: edges,
                            color: scheme.outline,
                          ),
                        ),
                      ),
                      for (final node in nodes)
                        Positioned(
                          left: node.x,
                          top: node.y,
                          child: _MapNodeCard(node: node),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _SurfacePanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Compiled program',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (program == null)
                    Text(
                      'Save bosilganda RS server JSON mapni tekshiradi va operation code ro‘yxatiga aylantiradi.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  else
                    ...program!.operations.map(
                      (operation) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 16,
                          child: Text(operation.order.toString()),
                        ),
                        title: Text(operation.opCode),
                        subtitle: Text(operation.nodeId),
                      ),
                    ),
                ],
              ),
            ),
          ],
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

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      style: TextStyle(color: scheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
      ),
    );
  }
}

class _MapNodeCard extends StatelessWidget {
  const _MapNodeCard({required this.node});

  final ProductionMapNode node;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _colorFor(node.kind, scheme),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            node.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            node.kind,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (node.formula != null) ...[
            const SizedBox(height: 8),
            Text(
              '${node.formula!.target} = ${node.formula!.expression}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
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
}

class _MapEdgePainter extends CustomPainter {
  const _MapEdgePainter({
    required this.nodes,
    required this.edges,
    required this.color,
  });

  final List<ProductionMapNode> nodes;
  final List<ProductionMapEdge> edges;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final byId = {for (final node in nodes) node.id: node};
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (final edge in edges) {
      final from = byId[edge.from];
      final to = byId[edge.to];
      if (from == null || to == null) {
        continue;
      }
      final start = Offset(from.x + 150, from.y + 44);
      final end = Offset(to.x, to.y + 44);
      final control = Offset((start.dx + end.dx) / 2, start.dy);
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
      canvas.drawPath(path, paint);
      canvas.drawPath(
        Path()
          ..moveTo(end.dx, end.dy)
          ..lineTo(end.dx - 9, end.dy - 5)
          ..lineTo(end.dx - 9, end.dy + 5)
          ..close(),
        arrowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MapEdgePainter oldDelegate) {
    return oldDelegate.nodes != nodes ||
        oldDelegate.edges != edges ||
        oldDelegate.color != color;
  }
}
