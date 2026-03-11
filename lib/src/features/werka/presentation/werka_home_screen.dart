import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../shared/models/app_models.dart';
import 'widgets/werka_dock.dart';
import 'package:flutter/material.dart';

class WerkaHomeScreen extends StatefulWidget {
  const WerkaHomeScreen({super.key});

  @override
  State<WerkaHomeScreen> createState() => _WerkaHomeScreenState();
}

class _WerkaHomeScreenState extends State<WerkaHomeScreen>
    with WidgetsBindingObserver {
  late Future<_WerkaHomeData> _homeFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _homeFuture = _loadHome();
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
    final future = _loadHome();
    setState(() {
      _homeFuture = future;
    });
    await future;
  }

  Future<_WerkaHomeData> _loadHome() async {
    final results = await Future.wait<dynamic>([
      MobileApi.instance.werkaPending(),
      MobileApi.instance.werkaHistory(),
    ]);
    return _WerkaHomeData(
      pending: results[0] as List<DispatchRecord>,
      history: results[1] as List<DispatchRecord>,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Werka',
      subtitle: '',
      bottom: const WerkaDock(activeTab: WerkaDockTab.home),
      child: Column(
        children: [
          Expanded(
            child: FutureBuilder<_WerkaHomeData>(
              future: _homeFuture,
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

                final data = snapshot.data ??
                    const _WerkaHomeData(
                      pending: <DispatchRecord>[],
                      history: <DispatchRecord>[],
                    );
                final items = data.pending;
                final confirmedCount = data.history
                    .where((item) =>
                        item.status == DispatchStatus.accepted ||
                        item.status == DispatchStatus.partial)
                    .length;
                final previewItems =
                    items.length > 3 ? items.take(3).toList() : items;

                return RefreshIndicator.adaptive(
                  onRefresh: _reload,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: MetricBadge(
                              label: 'Jarayondagi mahsulotlar',
                              value: items.length.toString(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: MetricBadge(
                              label: 'Tasdiqlangan mahsulotlar',
                              value: confirmedCount.toString(),
                            ),
                          ),
                        ],
                      ),
                      if (previewItems.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Jarayondagi mahsulotlar',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ],
                      ...previewItems.asMap().entries.map((entry) {
                        final index = entry.key;
                        final DispatchRecord record = entry.value;
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == previewItems.length - 1 ? 0 : 12,
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

class _WerkaHomeData {
  const _WerkaHomeData({
    required this.pending,
    required this.history,
  });

  final List<DispatchRecord> pending;
  final List<DispatchRecord> history;
}
