import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../shared/models/app_models.dart';
import 'package:flutter/material.dart';

class WerkaHomeScreen extends StatefulWidget {
  const WerkaHomeScreen({super.key});

  @override
  State<WerkaHomeScreen> createState() => _WerkaHomeScreenState();
}

class _WerkaHomeScreenState extends State<WerkaHomeScreen>
    with WidgetsBindingObserver {
  late Future<List<DispatchRecord>> _pendingFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pendingFuture = MobileApi.instance.werkaPending();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _reload();
    }
  }

  Future<void> _reload() async {
    final future = MobileApi.instance.werkaPending();
    setState(() {
      _pendingFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Werka',
      subtitle: 'Pending qabul qilish ro‘yxati.',
      actions: [
        AppShellIconAction(
          icon: Icons.person_outline_rounded,
          onTap: () => Navigator.of(context).pushNamed('/profile'),
        ),
      ],
      child: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<DispatchRecord>>(
              future: _pendingFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return RefreshIndicator.adaptive(
                    onRefresh: _reload,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 120),
                        SoftCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pending list yuklanmadi',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${snapshot.error}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: _reload,
                                  child: const Text('Qayta urinish'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final items = snapshot.data ?? <DispatchRecord>[];

                return RefreshIndicator.adaptive(
                  onRefresh: _reload,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SmoothAppear(
                        child: SoftCard(
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${items.length} ta pending bildirishnoma',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              const Icon(Icons.inventory_2_outlined),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final DispatchRecord record = entry.value;
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == items.length - 1 ? 0 : 12,
                          ),
                          child: SmoothAppear(
                            delay: Duration(milliseconds: 70 + (index * 80)),
                            offset: const Offset(0, 18),
                            child: PressableScale(
                              onTap: () => Navigator.of(context).pushNamed(
                                AppRoutes.werkaDetail,
                                arguments: record,
                              ),
                              child: SoftCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(record.supplierName,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge),
                                        ),
                                        const StatusPill(
                                            status: DispatchStatus.pending),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                        '${record.itemCode} • ${record.itemName}'),
                                    const SizedBox(height: 10),
                                    Text(
                                      '${record.sentQty.toStringAsFixed(0)} ${record.uom}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(record.createdLabel,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
