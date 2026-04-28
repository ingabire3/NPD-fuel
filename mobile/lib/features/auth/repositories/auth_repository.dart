import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabase;
  AuthRepository(this._supabase);

  Future<String> register({
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
    // Step 1: Create auth user — trigger auto-creates users row with PENDING status
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName, 'role': 'DRIVER'},
    );
    final userId = response.user?.id;
    if (userId == null) throw Exception('Registration failed — no user returned.');

    // Step 2: Populate profile + vehicle via SECURITY DEFINER RPC
    await _supabase.rpc('register_driver', params: {
      'p_user_id': userId,
      'p_phone': phone,
      'p_home_lat': homeLat,
      'p_home_lng': homeLng,
      'p_home_address': homeAddress,
      'p_work_lat': workLat,
      'p_work_lng': workLng,
      'p_work_address': workAddress,
      'p_plate_number': plateNumber,
      'p_vehicle_make': vehicleMake,
      'p_vehicle_model': vehicleModel,
      'p_vehicle_year': vehicleYear,
      'p_fuel_type': fuelType,
      'p_tank_capacity': tankCapacity,
      'p_average_km_per_l': averageKmPerL,
    });

    // Step 3: Sign out — account needs admin approval before first login
    await _supabase.auth.signOut();

    return 'Registration successful! Your account is pending admin approval.';
  }
}
