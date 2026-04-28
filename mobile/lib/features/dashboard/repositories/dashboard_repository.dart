import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardRepository {
  final SupabaseClient _supabase;
  DashboardRepository(this._supabase);

  Future<Map<String, dynamic>> getStats() async {
    final result = await _supabase.rpc('get_dashboard_stats');
    return (result as Map<String, dynamic>?) ?? {};
  }
}
