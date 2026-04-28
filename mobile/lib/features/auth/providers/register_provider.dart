import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import '../repositories/auth_repository.dart';

class RegisterState {
  final bool isLoading;
  final bool isSuccess;
  final String? error;
  final String? successMessage;

  const RegisterState({
    this.isLoading = false,
    this.isSuccess = false,
    this.error,
    this.successMessage,
  });

  RegisterState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? error,
    String? successMessage,
  }) =>
      RegisterState(
        isLoading: isLoading ?? this.isLoading,
        isSuccess: isSuccess ?? this.isSuccess,
        error: error,
        successMessage: successMessage ?? this.successMessage,
      );
}

class RegisterNotifier extends StateNotifier<RegisterState> {
  final AuthRepository _repo;

  RegisterNotifier(this._repo) : super(const RegisterState());

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    required double homeLat,
    required double homeLng,
    String? homeAddress,
    required double workLat,
    required double workLng,
    String? workAddress,
    required String plateNumber,
    required String vehicleMake,
    required String vehicleModel,
    required int vehicleYear,
    required String fuelType,
    required double tankCapacity,
    double? averageKmPerL,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final message = await _repo.register(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
        homeLat: homeLat,
        homeLng: homeLng,
        homeAddress: homeAddress,
        workLat: workLat,
        workLng: workLng,
        workAddress: workAddress,
        plateNumber: plateNumber,
        vehicleMake: vehicleMake,
        vehicleModel: vehicleModel,
        vehicleYear: vehicleYear,
        fuelType: fuelType,
        tankCapacity: tankCapacity,
        averageKmPerL: averageKmPerL,
      );
      state = RegisterState(isSuccess: true, successMessage: message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final registerProvider =
    StateNotifierProvider.autoDispose<RegisterNotifier, RegisterState>(
  (ref) => RegisterNotifier(AuthRepository(ref.read(apiClientProvider))),
);
