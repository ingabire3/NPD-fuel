import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/allocation_model.dart';

class AllocationsRepository {
  final SupabaseClient _supabase;
  AllocationsRepository(this._supabase);

  Future<List<AllocationModel>> getAll({int? month, int? year}) async {
    var query = _supabase
        .from('fuel_allocations')
        .select('*, user:users!user_id(name), vehicle:vehicles!vehicle_id(plate_number)');

    if (month != null) query = query.eq('month', month);
    if (year != null) query = query.eq('year', year);

    final data = await query.order('created_at', ascending: false);
    return (data as List).map((e) => AllocationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<AllocationModel?> getMyCurrent() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final now = DateTime.now();
    final data = await _supabase
        .from('fuel_allocations')
        .select('*, user:users!user_id(name), vehicle:vehicles!vehicle_id(plate_number)')
        .eq('user_id', userId)
        .eq('month', now.month)
        .eq('year', now.year)
        .maybeSingle();

    if (data == null) return null;
    return AllocationModel.fromJson(data as Map<String, dynamic>);
  }

  Future<AllocationModel> create({
    required String userId,
    required String vehicleId,
    required int month,
    required int year,
    required double allocatedLiters,
    required double allocatedAmount,
  }) async {
    final data = await _supabase.from('fuel_allocations').insert({
      'user_id': userId,
      'vehicle_id': vehicleId,
      'month': month,
      'year': year,
      'allocated_liters': allocatedLiters,
      'allocated_amount': allocatedAmount,
      'remaining_liters': allocatedLiters,
    }).select('*, user:users!user_id(name), vehicle:vehicles!vehicle_id(plate_number)').single();
    return AllocationModel.fromJson(data as Map<String, dynamic>);
  }

  Future<AllocationModel> update({
    required String id,
    required double allocatedLiters,
    required double allocatedAmount,
  }) async {
    final existing = await _supabase
        .from('fuel_allocations')
        .select('used_liters')
        .eq('id', id)
        .single();
    final usedLiters = (existing['used_liters'] as num).toDouble();
    final newRemaining = (allocatedLiters - usedLiters).clamp(0.0, allocatedLiters);

    final data = await _supabase
        .from('fuel_allocations')
        .update({
          'allocated_liters': allocatedLiters,
          'allocated_amount': allocatedAmount,
          'remaining_liters': newRemaining,
        })
        .eq('id', id)
        .select('*, user:users!user_id(name), vehicle:vehicles!vehicle_id(plate_number)')
        .single();
    return AllocationModel.fromJson(data as Map<String, dynamic>);
  }
}
