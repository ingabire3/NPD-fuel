import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/vehicle_model.dart';
import '../repositories/users_repository.dart';
import '../repositories/vehicles_repository.dart';
import '../../auth/providers/auth_provider.dart';

final _usersRepoProvider = Provider((ref) => UsersRepository(ref.read(apiClientProvider)));
final _vehiclesRepoProvider = Provider((ref) => VehiclesRepository(ref.read(apiClientProvider)));

// Users
final usersListProvider = FutureProvider<List<UserModel>>((ref) {
  return ref.watch(_usersRepoProvider).getAll();
});

final driversListProvider = FutureProvider<List<UserModel>>((ref) {
  return ref.watch(_usersRepoProvider).getAll(role: 'DRIVER');
});

class CreateUserState {
  final bool isLoading;
  final String? error;
  final bool success;

  const CreateUserState({this.isLoading = false, this.error, this.success = false});

  CreateUserState copyWith({bool? isLoading, String? error, bool? success}) =>
      CreateUserState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        success: success ?? this.success,
      );
}

class CreateUserNotifier extends StateNotifier<CreateUserState> {
  final UsersRepository _repo;
  final Ref _ref;

  CreateUserNotifier(this._repo, this._ref) : super(const CreateUserState());

  Future<void> create({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? phone,
    String? department,
  }) async {
    state = state.copyWith(isLoading: true, error: null, success: false);
    try {
      await _repo.create(
        fullName: fullName,
        email: email,
        password: password,
        role: role,
        phone: phone,
        department: department,
      );
      _ref.invalidate(usersListProvider);
      state = state.copyWith(isLoading: false, success: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deactivate(String id) async {
    try {
      await _repo.deactivate(id);
      _ref.invalidate(usersListProvider);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final createUserProvider =
    StateNotifierProvider<CreateUserNotifier, CreateUserState>(
  (ref) => CreateUserNotifier(ref.read(_usersRepoProvider), ref),
);

// Vehicles
final vehiclesListProvider = FutureProvider<List<VehicleModel>>((ref) {
  return ref.watch(_vehiclesRepoProvider).getAll();
});

class VehicleActionNotifier extends StateNotifier<AsyncValue<void>> {
  final VehiclesRepository _repo;
  final Ref _ref;

  VehicleActionNotifier(this._repo, this._ref) : super(const AsyncValue.data(null));

  Future<void> create({
    required String plateNumber,
    required String make,
    required String model,
    required int year,
    required String fuelType,
    required double tankCapacity,
    required double averageKmPerL,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.create(
        plateNumber: plateNumber,
        make: make,
        model: model,
        year: year,
        fuelType: fuelType,
        tankCapacity: tankCapacity,
        averageKmPerL: averageKmPerL,
      );
      _ref.invalidate(vehiclesListProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> assignDriver(String vehicleId, String driverId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.assignDriver(vehicleId, driverId);
      _ref.invalidate(vehiclesListProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final vehicleActionProvider =
    StateNotifierProvider<VehicleActionNotifier, AsyncValue<void>>(
  (ref) => VehicleActionNotifier(ref.read(_vehiclesRepoProvider), ref),
);
