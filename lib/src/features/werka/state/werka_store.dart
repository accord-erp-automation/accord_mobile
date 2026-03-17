import '../../../core/api/mobile_api.dart';
import '../../../core/notifications/werka_runtime_store.dart';
import '../../shared/models/app_models.dart';
import 'package:flutter/foundation.dart';

class WerkaStore extends ChangeNotifier {
  WerkaStore._() {
    WerkaRuntimeStore.instance.addListener(_forwardRuntimeChange);
  }

  static final WerkaStore instance = WerkaStore._();

  bool _loadingHome = false;
  bool _loadingHistory = false;
  bool _loadedHome = false;
  bool _loadedHistory = false;
  Object? _homeError;
  Object? _historyError;
  final Map<WerkaStatusKind, bool> _loadingBreakdown = {};
  final Map<WerkaStatusKind, Object?> _breakdownErrors = {};
  final Map<WerkaStatusKind, List<WerkaStatusBreakdownEntry>> _breakdownItems =
      {};
  final Map<String, bool> _loadingDetail = {};
  final Map<String, Object?> _detailErrors = {};
  final Map<String, List<DispatchRecord>> _detailItems = {};

  WerkaHomeSummary _summary = const WerkaHomeSummary(
    pendingCount: 0,
    confirmedCount: 0,
    returnedCount: 0,
  );
  List<DispatchRecord> _pendingItems = const <DispatchRecord>[];
  List<DispatchRecord> _historyItems = const <DispatchRecord>[];

  bool get loadingHome => _loadingHome;
  bool get loadingHistory => _loadingHistory;
  bool get loadedHome => _loadedHome;
  bool get loadedHistory => _loadedHistory;
  Object? get homeError => _homeError;
  Object? get historyError => _historyError;
  WerkaHomeSummary get summary =>
      WerkaRuntimeStore.instance.applySummary(_summary);
  List<DispatchRecord> get pendingItems =>
      WerkaRuntimeStore.instance.applyPendingItems(_pendingItems);
  List<DispatchRecord> get historyItems => _historyItems;
  List<WerkaStatusBreakdownEntry> breakdownItems(WerkaStatusKind kind) =>
      _breakdownItems[kind] ?? const <WerkaStatusBreakdownEntry>[];
  bool loadingBreakdown(WerkaStatusKind kind) => _loadingBreakdown[kind] == true;
  Object? breakdownError(WerkaStatusKind kind) => _breakdownErrors[kind];
  List<DispatchRecord> detailItems(WerkaStatusKind kind, String supplierRef) =>
      _detailItems[_detailKey(kind, supplierRef)] ?? const <DispatchRecord>[];
  bool loadingDetail(WerkaStatusKind kind, String supplierRef) =>
      _loadingDetail[_detailKey(kind, supplierRef)] == true;
  Object? detailError(WerkaStatusKind kind, String supplierRef) =>
      _detailErrors[_detailKey(kind, supplierRef)];

  Future<void> bootstrapHome({bool force = false}) async {
    if (_loadingHome) return;
    if (_loadedHome && !force) return;
    await refreshHome();
  }

  Future<void> bootstrapHistory({bool force = false}) async {
    if (_loadingHistory) return;
    if (_loadedHistory && !force) return;
    await refreshHistory();
  }

  Future<void> refreshHome() async {
    if (_loadingHome) return;
    _loadingHome = true;
    _homeError = null;
    notifyListeners();
    try {
      final results = await Future.wait<dynamic>([
        MobileApi.instance.werkaSummary(),
        MobileApi.instance.werkaPending(),
      ]);
      _summary = results[0] as WerkaHomeSummary;
      _pendingItems = results[1] as List<DispatchRecord>;
      _loadedHome = true;
    } catch (error) {
      _homeError = error;
    } finally {
      _loadingHome = false;
      notifyListeners();
    }
  }

  Future<void> refreshHistory() async {
    if (_loadingHistory) return;
    _loadingHistory = true;
    _historyError = null;
    notifyListeners();
    try {
      _historyItems = await MobileApi.instance.werkaHistory();
      _loadedHistory = true;
    } catch (error) {
      _historyError = error;
    } finally {
      _loadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([
      refreshHome(),
      refreshHistory(),
    ]);
  }

  Future<void> bootstrapBreakdown(WerkaStatusKind kind,
      {bool force = false}) async {
    if (loadingBreakdown(kind)) return;
    if (_breakdownItems.containsKey(kind) && !force) return;
    await refreshBreakdown(kind);
  }

  Future<void> refreshBreakdown(WerkaStatusKind kind) async {
    if (loadingBreakdown(kind)) return;
    _loadingBreakdown[kind] = true;
    _breakdownErrors[kind] = null;
    notifyListeners();
    try {
      _breakdownItems[kind] = await MobileApi.instance.werkaStatusBreakdown(kind);
    } catch (error) {
      _breakdownErrors[kind] = error;
    } finally {
      _loadingBreakdown[kind] = false;
      notifyListeners();
    }
  }

  Future<void> bootstrapDetail(WerkaStatusKind kind, String supplierRef,
      {bool force = false}) async {
    final key = _detailKey(kind, supplierRef);
    if (_loadingDetail[key] == true) return;
    if (_detailItems.containsKey(key) && !force) return;
    await refreshDetail(kind, supplierRef);
  }

  Future<void> refreshDetail(WerkaStatusKind kind, String supplierRef) async {
    final key = _detailKey(kind, supplierRef);
    if (_loadingDetail[key] == true) return;
    _loadingDetail[key] = true;
    _detailErrors[key] = null;
    notifyListeners();
    try {
      _detailItems[key] = await MobileApi.instance.werkaStatusDetails(
        kind: kind,
        supplierRef: supplierRef,
      );
    } catch (error) {
      _detailErrors[key] = error;
    } finally {
      _loadingDetail[key] = false;
      notifyListeners();
    }
  }

  void recordCreatedPending(DispatchRecord record) {
    WerkaRuntimeStore.instance.recordCreatedPending(record);
  }

  void recordTransition({
    required DispatchRecord before,
    required DispatchRecord after,
  }) {
    WerkaRuntimeStore.instance.recordTransition(before: before, after: after);
  }

  void _forwardRuntimeChange() {
    notifyListeners();
  }

  String _detailKey(WerkaStatusKind kind, String supplierRef) =>
      '${kind.name}:${supplierRef.trim()}';

  void clear() {
    _loadingHome = false;
    _loadingHistory = false;
    _loadedHome = false;
    _loadedHistory = false;
    _homeError = null;
    _historyError = null;
    _loadingBreakdown.clear();
    _breakdownErrors.clear();
    _breakdownItems.clear();
    _loadingDetail.clear();
    _detailErrors.clear();
    _detailItems.clear();
    _summary = const WerkaHomeSummary(
      pendingCount: 0,
      confirmedCount: 0,
      returnedCount: 0,
    );
    _pendingItems = const <DispatchRecord>[];
    _historyItems = const <DispatchRecord>[];
    notifyListeners();
  }
}
