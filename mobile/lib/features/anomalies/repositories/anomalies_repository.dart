import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/anomaly_model.dart';

class AnomaliesRepository {
  final SupabaseClient _supabase;
  AnomaliesRepository(this._supabase);

  Future<List<AnomalyModel>> getAll({String? status}) async {
    var query = _supabase
        .from('anomaly_logs')
        .select('*, user:users!user_id(full_name)');

    if (status != null && status != 'ALL') query = query.eq('status', status);

    final data = await query.order('created_at', ascending: false);
    return (data as List).map((e) => AnomalyModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<AnomalyModel> resolve(String id, String resolution) async {
    final data = await _supabase
        .from('anomaly_logs')
        .update({
          'status': 'RESOLVED',
          'resolution': resolution,
          'resolved_at': DateTime.now().toIso8601String(),
          'resolved_by': _supabase.auth.currentUser?.id,
        })
        .eq('id', id)
        .select('*, user:users!user_id(full_name)')
        .single();
    return AnomalyModel.fromJson(data as Map<String, dynamic>);
  }
}
