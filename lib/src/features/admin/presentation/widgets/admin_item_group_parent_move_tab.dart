import '../../../shared/models/app_models.dart';
import 'admin_item_group_parent_move_panel.dart';
import 'package:flutter/material.dart';

class AdminItemGroupParentMoveTab extends StatelessWidget {
  const AdminItemGroupParentMoveTab({
    super.key,
    required this.itemGroupsFuture,
    required this.onMoved,
  });

  final Future<List<String>> itemGroupsFuture;
  final ValueChanged<AdminItemGroup> onMoved;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: itemGroupsFuture,
      builder: (context, snapshot) {
        final groups = snapshot.data ?? const <String>[];
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || groups.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Item grouplar yuklanmadi',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
          children: [
            AdminItemGroupParentMovePanel(
              groups: groups,
              onMoved: onMoved,
            ),
          ],
        );
      },
    );
  }
}
