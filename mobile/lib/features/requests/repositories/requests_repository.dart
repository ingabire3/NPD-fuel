import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/fuel_request_model.dart';
import '../../../core/services/location_service.dart';

class RequestsRepository {
  final SupabaseClient _supabase;
  RequestsRepository(this._supabase);

  Future<List<FuelRequestModel>> getRequests({String? status}) async {
    var query = _supabase
        .from('fuel_requests')
        .select('*, driver:users!driver_id(name), vehicle:vehicles!vehicle_id(plate_number)');

    if (status != null) query = query.eq('status', status);

    final data = await query.order('created_at', ascending: false);
    return (data as List).map((e) => FuelRequestModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<FuelRequestModel> getRequest(String id) async {
    final data = await _supabase
        .from('fuel_requests')
        .select('*, driver:users!driver_id(name), vehicle:vehicles!vehicle_id(plate_number)')
        .eq('id', id)
        .single();
    return FuelRequestModel.fromJson(data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>?> getEstimate(String vehicleId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final vehicle = await _supabase.from('vehicles').select('fuel_efficiency').eq('id', vehicleId).single();
    final location = await _supabase
        .from('locations')
        .select('home_lat,home_lng,work_lat,work_lng')
        .eq('user_id', userId)
        .maybeSingle();

    if (location == null) return null;
    final homeLat = (location['home_lat'] as num?)?.toDouble();
    final homeLng = (location['home_lng'] as num?)?.toDouble();
    final workLat = (location['work_lat'] as num?)?.toDouble();
    final workLng = (location['work_lng'] as num?)?.toDouble();
    if (homeLat == null || homeLng == null || workLat == null || workLng == null) return null;

    final distanceKm = LocationService.haversineKm(homeLat, homeLng, workLat, workLng) * 2;
    final avgKmPerL = (vehicle['fuel_efficiency'] as num?)?.toDouble() ?? 10.0;
    final expectedFuel = (distanceKm / avgKmPerL) * 1.15;

    return {'distanceKm': distanceKm, 'expectedFuel': expectedFuel};
  }

  Future<String> uploadOdometerImage(String filePath) async {
    final userId = _supabase.auth.currentUser!.id;
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = '$userId/odometer_$ts.jpg';
    final bytes = await File(filePath).readAsBytes();
    await _supabase.storage
        .from('odometers')
        .uploadBinary(path, bytes, fileOptions: const FileOptions(contentType: 'image/jpeg'));
    return _supabase.storage.from('odometers').getPublicUrl(path);
  }

  Future<FuelRequestModel> createRequest({
    required String vehicleId,
    required double liters,
    required String purpose,
    required double odometerBefore,
    String? odometerImageUrl,
  }) async {
    final userId = _supabase.auth.currentUser!.id;
    final estimate = await getEstimate(vehicleId);

    String variance = 'NORMAL';
    if (estimate != null && (estimate['expectedFuel'] as double) > 0) {
      final ratio = liters / (estimate['expectedFuel'] as double);
      if (ratio > 1.2) variance = 'SUSPICIOUS';
      else if (ratio >= 1.1) variance = 'WARNING';
    }

    final data = await _supabase.from('fuel_requests').insert({
      'driver_id': userId,
      'vehicle_id': vehicleId,
      'requested_liters': liters,
      'requested_amount': liters * 1500,
      'purpose': purpose,
      'odometer_before': odometerBefore,
      if (odometerImageUrl != null) 'odometer_image_url': odometerImageUrl,
      if (estimate != null) 'estimated_distance': estimate['distanceKm'],
      if (estimate != null) 'expected_fuel': estimate['expectedFuel'],
      'fuel_variance': variance,
    }).select('*, driver:users!driver_id(name), vehicle:vehicles!vehicle_id(plate_number)').single();

    return FuelRequestModel.fromJson(data as Map<String, dynamic>);
  }

  Future<FuelRequestModel> approveRequest(String id) async {
    final result = await _supabase.rpc('review_fuel_request', params: {
      'p_request_id': id,
      'p_status': 'APPROVED',
    });
    return FuelRequestModel.fromJson((result as List).first as Map<String, dynamic>);
  }

  Future<FuelRequestModel> rejectRequest(String id, String reason) async {
    final result = await _supabase.rpc('review_fuel_request', params: {
      'p_request_id': id,
      'p_status': 'REJECTED',
      'p_rejection_reason': reason,
    });
    return FuelRequestModel.fromJson((result as List).first as Map<String, dynamic>);
  }

  Future<FuelRequestModel> fulfillRequest(String id, double odometerAfter) async {
    await _supabase.from('fuel_requests').update({'odometer_after': odometerAfter}).eq('id', id);
    final result = await _supabase.rpc('fulfill_fuel_request', params: {'p_request_id': id});
    return FuelRequestModel.fromJson((result as List).first as Map<String, dynamic>);
  }
}
