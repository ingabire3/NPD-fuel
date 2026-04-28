import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/anomaly_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../repositories/anomalies_repository.dart';

final _repoProvider = Provider((ref) => AnomaliesRepository(ref.read(apiClientProvider)));

final anomalyStatusFilterProvider = StateProvider<String>((ref) => 'ALL');

final anomaliesListProvider = FutureProvider<List<AnomalyModel>>((ref) {
  final status = ref.watch(anomalyStatusFilterProvider);
  return ref.watch(_repoProvider).getAll(status: status == 'ALL' ? null : status);
});

class ResolveAnomalyNotifier extends StateNotifier<AsyncValue<void>> {
  final AnomaliesRepository _repo;
  final Ref _ref;

  ResolveAnomalyNotifier(this._repo, this._ref) : super(const AsyncValue.data(null));

  Future<void> resolve(String id, String resolution) async {
    state = const AsyncValue.loading();
    try {
      await _repo.resolve(id, resolution);
      _ref.invalidate(anomaliesListProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final resolveAnomalyProvider =
    StateNotifierProvider<ResolveAnomalyNotifier, AsyncValue<void>>(
  (ref) => ResolveAnomalyNotifier(ref.read(_repoProvider), ref),
);
