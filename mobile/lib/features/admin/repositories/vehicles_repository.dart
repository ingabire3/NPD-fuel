import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/vehicle_model.dart';

class VehiclesRepository {
  final SupabaseClient _supabase;
  VehiclesRepository(this._supabase);

  Future<List<VehicleModel>> getAll() async {
    final data = await _supabase
        .from('vehicles')
        .select('*, assigned_driver:users!user_id(name)')
        .order('created_at', ascending: false);
    return (data as List).map((e) => VehicleModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<VehicleModel> create({
    required String plateNumber,
    required String make,
    required String model,
    required int year,
    required String fuelType,
    required double tankCapacity,
    required double fuelEfficiency,
  }) async {
    final data = await _supabase.from('vehicles').insert({
      'plate_number': plateNumber,
      'make': make,
      'model': model,
      'year': year,
      'fuel_type': fuelType,
      'tank_capacity': tankCapacity,
      'fuel_efficiency': fuelEfficiency,
    }).select('*, assigned_driver:users!user_id(name)').single();
    return VehicleModel.fromJson(data as Map<String, dynamic>);
  }

  Future<VehicleModel> assignDriver(String vehicleId, String driverId) async {
    final data = await _supabase
        .from('vehicles')
        .update({'user_id': driverId})
        .eq('id', vehicleId)
        .select('*, assigned_driver:users!user_id(name)')
        .single();
    return VehicleModel.fromJson(data as Map<String, dynamic>);
  }
}
