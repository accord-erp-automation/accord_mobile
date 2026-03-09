import '../../../core/api/mobile_api.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../shared/models/app_models.dart';
import 'package:flutter/material.dart';

class SupplierRecentScreen extends StatelessWidget {
  const SupplierRecentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Recent',
      subtitle: 'Supplier qilgan avvalgi harakatlar.',
      child: FutureBuilder<List<DispatchRecord>>(
        future: MobileApi.instance.supplierHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: SoftCard(
                child: Text('Recent yuklanmadi: ${snapshot.error}'),
              ),
            );
          }

          final items = snapshot.data ?? <DispatchRecord>[];
          if (items.isEmpty) {
            return const Center(
              child: SoftCard(
                child: Text('Hali jo‘natishlar yo‘q.'),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              color: Color(0xFF1D1D1D),
            ),
            itemBuilder: (context, index) {
              final record = items[index];
              return SmoothAppear(
                delay: Duration(milliseconds: 40 + (index * 35)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 44,
                        width: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFF111111),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.itemCode,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              record.itemName,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${record.sentQty.toStringAsFixed(0)} ${record.uom}',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          StatusPill(status: record.status),
                          const SizedBox(height: 8),
                          Text(
                            record.createdLabel,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
