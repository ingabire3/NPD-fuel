import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/fuel_request_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../repositories/requests_repository.dart';

final requestsRepositoryProvider = Provider<RequestsRepository>(
  (ref) => RequestsRepository(ref.read(apiClientProvider)),
);

final requestsListProvider = FutureProvider.family<List<FuelRequestModel>, String?>(
  (ref, status) => ref.read(requestsRepositoryProvider).getRequests(status: status),
);

final requestDetailProvider = FutureProvider.family<FuelRequestModel, String>(
  (ref, id) => ref.read(requestsRepositoryProvider).getRequest(id),
);

// Create request state
class CreateRequestState {
  final bool isLoading;
  final String? error;
  final bool success;
  const CreateRequestState({this.isLoading = false, this.error, this.success = false});
}

class CreateRequestNotifier extends StateNotifier<CreateRequestState> {
  final RequestsRepository _repo;
  CreateRequestNotifier(this._repo) : super(const CreateRequestState());

  Future<FuelRequestModel?> submit({
    required String vehicleId,
    required double liters,
    required String purpose,
    required double odometerBefore,
    String? odometerImageUrl,
  }) async {
    state = const CreateRequestState(isLoading: true);
    try {
      final result = await _repo.createRequest(
        vehicleId: vehicleId,
        liters: liters,
        purpose: purpose,
        odometerBefore: odometerBefore,
        odometerImageUrl: odometerImageUrl,
      );
      state = const CreateRequestState(success: true);
      return result;
    } catch (e) {
      state = CreateRequestState(error: e.toString());
      return null;
    }
  }
}

final createRequestProvider =
    StateNotifierProvider.autoDispose<CreateRequestNotifier, CreateRequestState>(
  (ref) => CreateRequestNotifier(ref.read(requestsRepositoryProvider)),
);
