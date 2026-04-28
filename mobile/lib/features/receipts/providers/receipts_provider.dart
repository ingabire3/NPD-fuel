import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../repositories/receipts_repository.dart';

final receiptsRepositoryProvider = Provider<ReceiptsRepository>(
  (ref) => ReceiptsRepository(ref.read(apiClientProvider)),
);

final receiptsListProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.read(receiptsRepositoryProvider).getReceipts(),
);

class UploadReceiptState {
  final bool isLoading;
  final String? error;
  final bool success;
  const UploadReceiptState({this.isLoading = false, this.error, this.success = false});
}

class UploadReceiptNotifier extends StateNotifier<UploadReceiptState> {
  final ReceiptsRepository _repo;
  UploadReceiptNotifier(this._repo) : super(const UploadReceiptState());

  Future<bool> upload({
    required String requestId,
    required String filePath,
  }) async {
    state = const UploadReceiptState(isLoading: true);
    try {
      await _repo.uploadReceipt(requestId: requestId, filePath: filePath);
      state = const UploadReceiptState(success: true);
      return true;
    } catch (e) {
      state = UploadReceiptState(error: e.toString());
      return false;
    }
  }
}

final uploadReceiptProvider =
    StateNotifierProvider.autoDispose<UploadReceiptNotifier, UploadReceiptState>(
  (ref) => UploadReceiptNotifier(ref.read(receiptsRepositoryProvider)),
);
