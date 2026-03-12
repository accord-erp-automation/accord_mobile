import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../shared/models/app_models.dart';
import 'werka_unannounced_qty_screen.dart';
import 'widgets/werka_dock.dart';
import 'package:flutter/material.dart';

class WerkaUnannouncedItemScreen extends StatefulWidget {
  const WerkaUnannouncedItemScreen({
    super.key,
    required this.supplier,
  });

  final SupplierDirectoryEntry supplier;

  @override
  State<WerkaUnannouncedItemScreen> createState() =>
      _WerkaUnannouncedItemScreenState();
}

class _WerkaUnannouncedItemScreenState extends State<WerkaUnannouncedItemScreen> {
  final TextEditingController _controller = TextEditingController();
  late Future<List<SupplierItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = MobileApi.instance.werkaSupplierItems(
      supplierRef: widget.supplier.ref,
    );
  }

  Future<void> _reload() async {
    final future = MobileApi.instance.werkaSupplierItems(
      supplierRef: widget.supplier.ref,
      query: _controller.text,
    );
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Mol tanlang',
      subtitle: widget.supplier.name,
      leading: AppShellIconAction(
        icon: Icons.arrow_back_rounded,
        onTap: () => Navigator.of(context).maybePop(),
      ),
      bottom: const WerkaDock(activeTab: null),
      child: Column(
        children: [
          TextField(
            controller: _controller,
            onChanged: (_) => _reload(),
            decoration: const InputDecoration(
              hintText: 'Mahsulot qidiring',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<SupplierItem>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: SoftCard(child: Text('${snapshot.error}')));
                }
                final items = snapshot.data ?? const <SupplierItem>[];
                return ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => Navigator.of(context).pushNamed(
                        AppRoutes.werkaUnannouncedQty,
                        arguments: WerkaUnannouncedQtyArgs(
                          supplier: widget.supplier,
                          item: item,
                        ),
                      ),
                      child: SoftCard(
                        child: Text(item.name, style: Theme.of(context).textTheme.titleLarge),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
