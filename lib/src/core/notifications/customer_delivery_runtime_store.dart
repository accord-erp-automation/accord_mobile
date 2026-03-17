import '../../features/shared/models/app_models.dart';
import 'package:flutter/foundation.dart';

class CustomerDeliveryRuntimeStore extends ChangeNotifier {
  CustomerDeliveryRuntimeStore._();

  static final CustomerDeliveryRuntimeStore instance =
      CustomerDeliveryRuntimeStore._();

  final Map<String, _CustomerDeliveryMutation> _mutations = {};

  void recordTransition({
    required DispatchRecord before,
    required DispatchRecord after,
  }) {
    final id = after.id.trim();
    if (id.isEmpty) {
      return;
    }
    _mutations[id] = _CustomerDeliveryMutation(
      fromStatus: before.status,
      updated: after,
      createdAt: DateTime.now(),
    );
    notifyListeners();
  }

  List<DispatchRecord> applyStatusList(
    CustomerStatusKind kind,
    List<DispatchRecord> items,
  ) {
    final target = switch (kind) {
      CustomerStatusKind.pending => DispatchStatus.pending,
      CustomerStatusKind.confirmed => DispatchStatus.accepted,
      CustomerStatusKind.rejected => DispatchStatus.rejected,
    };
    final byId = <String, DispatchRecord>{
      for (final item in items) item.id: item,
    };
    for (final mutation in _activeMutations()) {
      if (mutation.updated.status == target) {
        byId[mutation.updated.id] = mutation.updated;
      } else {
        byId.remove(mutation.updated.id);
      }
    }
    return _sorted(byId.values);
  }

  List<DispatchRecord> applyHistory(List<DispatchRecord> items) {
    final byId = <String, DispatchRecord>{
      for (final item in items) item.id: item,
    };
    for (final mutation in _activeMutations()) {
      if (byId.containsKey(mutation.updated.id)) {
        byId[mutation.updated.id] = mutation.updated;
      }
    }
    return _sorted(byId.values);
  }

  Iterable<_CustomerDeliveryMutation> _activeMutations() sync* {
    final now = DateTime.now();
    for (final mutation in _mutations.values) {
      if (now.difference(mutation.createdAt) <= const Duration(seconds: 20)) {
        yield mutation;
      }
    }
  }

  List<DispatchRecord> _sorted(Iterable<DispatchRecord> records) {
    final result = records.toList();
    result.sort((a, b) => b.createdLabel.compareTo(a.createdLabel));
    return result;
  }
}

class _CustomerDeliveryMutation {
  const _CustomerDeliveryMutation({
    required this.fromStatus,
    required this.updated,
    required this.createdAt,
  });

  final DispatchStatus fromStatus;
  final DispatchRecord updated;
  final DateTime createdAt;
}
