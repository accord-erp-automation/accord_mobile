import '../../../core/api/mobile_api.dart';
import '../../../core/theme/app_theme.dart';
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
  static const _sampleMapID = 'hotlunch-test';
  static const _sampleProductCode = 'HOTLUNCH';
  static const _sampleTitle = 'Hotlunch test map';

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

  ProductionMapProgram? program;
  bool saving = false;

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      final saved = await MobileApi.instance.adminSaveProductionMap(
        ProductionMapDefinition(
          id: _sampleMapID,
          productCode: _sampleProductCode,
          title: _sampleTitle,
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
                  const _InfoLine(label: 'Map ID', value: _sampleMapID),
                  const SizedBox(height: 6),
                  const _InfoLine(
                    label: 'Mahsulot',
                    value: _sampleProductCode,
                  ),
                  const SizedBox(height: 6),
                  const _InfoLine(label: 'Nomi', value: _sampleTitle),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _PlainActionButton(
                          label: 'Wait node',
                          icon: Icons.hourglass_bottom_rounded,
                          onTap: _addWaitNode,
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
                    _MapNodeRow(node: nodes[i]),
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
                  Text('Edges', style: Theme.of(context).textTheme.titleMedium),
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
                    for (final operation in program!.operations)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Text(
                          '${operation.order}. ${operation.opCode} (${operation.nodeId})',
                          style: Theme.of(context).textTheme.bodyMedium,
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

class _PlainActionButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    final background = tonal ? scheme.secondaryContainer : scheme.primary;
    final foreground = tonal ? scheme.onSecondaryContainer : scheme.onPrimary;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Opacity(
          opacity: enabled ? 1 : 0.48,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: foreground, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
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
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
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
      ],
    );
  }
}

class _MapNodeRow extends StatelessWidget {
  const _MapNodeRow({required this.node});

  final ProductionMapNode node;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _colorFor(node.kind, scheme),
        borderRadius: BorderRadius.circular(18),
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
          ],
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
}
