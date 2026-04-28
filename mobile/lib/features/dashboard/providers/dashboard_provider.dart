import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../repositories/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref.read(apiClientProvider)),
);

final dashboardStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.read(dashboardRepositoryProvider).getStats();
});
