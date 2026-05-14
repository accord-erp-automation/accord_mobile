import '../../models/admin_item_group_tree_entry.dart';
import 'package:flutter/material.dart';

class AdminItemGroupTreePanel extends StatelessWidget {
  const AdminItemGroupTreePanel({
    super.key,
    required this.entries,
  });

  final List<AdminItemGroupTreeEntry> entries;

  @override
  Widget build(BuildContext context) {
    final nodes = _buildNodes(entries);
    if (nodes.isEmpty) {
      return const _EmptyTree();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Item Group tree',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(
          'Parent va child guruhlarni ERPNext tree tartibida ko‘rsatadi.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 14),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            children: [
              for (int index = 0; index < nodes.length; index++)
                _TreeNodeTile(
                  node: nodes[index],
                  isLast: index == nodes.length - 1,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TreeNode {
  _TreeNode(this.entry);

  final AdminItemGroupTreeEntry entry;
  final List<_TreeNode> children = [];
}

List<_TreeNode> _buildNodes(List<AdminItemGroupTreeEntry> entries) {
  final byName = <String, _TreeNode>{};
  for (final entry in entries) {
    final name = entry.name.trim();
    if (name.isEmpty || byName.containsKey(name)) {
      continue;
    }
    byName[name] = _TreeNode(entry);
  }

  final roots = <_TreeNode>[];
  for (final node in byName.values) {
    final parent = node.entry.parentItemGroup.trim();
    final parentNode = byName[parent];
    if (parent.isEmpty || parent == node.entry.name || parentNode == null) {
      roots.add(node);
    } else {
      parentNode.children.add(node);
    }
  }
  return _flatten(roots, 0);
}

List<_TreeNode> _flatten(List<_TreeNode> nodes, int depth) {
  final result = <_TreeNode>[];
  for (final node in nodes) {
    result.add(_DepthNode(node.entry, depth, node.children));
    result.addAll(_flatten(node.children, depth + 1));
  }
  return result;
}

class _DepthNode extends _TreeNode {
  _DepthNode(super.entry, this.depth, List<_TreeNode> children) {
    this.children.addAll(children);
  }

  final int depth;
}

class _TreeNodeTile extends StatelessWidget {
  const _TreeNodeTile({
    required this.node,
    required this.isLast,
  });

  final _TreeNode node;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final depth = node is _DepthNode ? (node as _DepthNode).depth : 0;
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(12 + depth * 18, 12, 12, 12),
        child: Row(
          children: [
            Icon(
              node.entry.isGroup
                  ? Icons.account_tree_rounded
                  : Icons.label_outline_rounded,
              size: 20,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    node.entry.itemGroupName.isEmpty
                        ? node.entry.name
                        : node.entry.itemGroupName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  if (node.entry.parentItemGroup.trim().isNotEmpty)
                    Text(
                      'parent: ${node.entry.parentItemGroup}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                ],
              ),
            ),
            if (node.children.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${node.children.length}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTree extends StatelessWidget {
  const _EmptyTree();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Tree bo‘sh',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
