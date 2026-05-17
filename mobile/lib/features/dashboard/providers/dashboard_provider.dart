import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../repositories/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref.read(apiClientProvider)),
);

final dashboardStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  // Re-fetch whenever the authenticated user changes (role matters for RPC result)
  final user = ref.watch(authProvider).user;
  if (user == null) return {};
  return ref.read(dashboardRepositoryProvider).getStats();
});
