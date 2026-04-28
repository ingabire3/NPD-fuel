import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/allocation_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../repositories/allocations_repository.dart';

final _repoProvider = Provider((ref) => AllocationsRepository(ref.read(apiClientProvider)));

final allocationsListProvider = FutureProvider<List<AllocationModel>>((ref) {
  return ref.watch(_repoProvider).getAll();
});

final myCurrentAllocationProvider = FutureProvider<AllocationModel?>((ref) {
  return ref.watch(_repoProvider).getMyCurrent();
});

class CreateAllocationState {
  final bool isLoading;
  final String? error;
  final bool success;

  const CreateAllocationState({this.isLoading = false, this.error, this.success = false});

  CreateAllocationState copyWith({bool? isLoading, String? error, bool? success}) =>
      CreateAllocationState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        success: success ?? this.success,
      );
}

class CreateAllocationNotifier extends StateNotifier<CreateAllocationState> {
  final AllocationsRepository _repo;
  CreateAllocationNotifier(this._repo) : super(const CreateAllocationState());

  Future<void> create({
    required String userId,
    required String vehicleId,
    required int month,
    required int year,
    required double allocatedLiters,
    required double allocatedAmount,
  }) async {
    state = state.copyWith(isLoading: true, error: null, success: false);
    try {
      await _repo.create(
        userId: userId,
        vehicleId: vehicleId,
        month: month,
        year: year,
        allocatedLiters: allocatedLiters,
        allocatedAmount: allocatedAmount,
      );
      state = state.copyWith(isLoading: false, success: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final createAllocationProvider =
    StateNotifierProvider<CreateAllocationNotifier, CreateAllocationState>(
  (ref) => CreateAllocationNotifier(ref.read(_repoProvider)),
);
