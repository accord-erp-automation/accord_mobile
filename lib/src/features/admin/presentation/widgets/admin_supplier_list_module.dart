import '../../../shared/models/app_models.dart';
import '../../../../core/widgets/common_widgets.dart';
import 'package:flutter/material.dart';

class AdminSupplierListModule extends StatefulWidget {
  const AdminSupplierListModule({
    super.key,
    required this.items,
    required this.onTapSupplier,
  });

  final List<AdminSupplier> items;
  final ValueChanged<AdminSupplier> onTapSupplier;

  @override
  State<AdminSupplierListModule> createState() =>
      _AdminSupplierListModuleState();
}

class _AdminSupplierListModuleState extends State<AdminSupplierListModule> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => setState(() => expanded = !expanded),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Supplier list',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Ro‘yxatni ochish uchun bosing',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 180),
                    turns: expanded ? 0.25 : 0,
                    child:
                        const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1),
            if (widget.items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  'Supplierlar topilmadi.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            else
              ...widget.items.map(
                (item) => InkWell(
                  onTap: () => widget.onTapSupplier(item),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (item.blocked)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0x22C53B30),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Blocked',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: const Color(0xFFC53B30)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
