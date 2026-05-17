class VehicleModel {
  final String id;
  final String plateNumber;
  final String make;
  final String model;
  final int year;
  final String fuelType;
  final double tankCapacity;
  final double fuelEfficiency;
  final String? assignedDriverId;
  final String? assignedDriverName;
  final bool isActive;

  VehicleModel({
    required this.id,
    required this.plateNumber,
    required this.make,
    required this.model,
    required this.year,
    required this.fuelType,
    required this.tankCapacity,
    required this.fuelEfficiency,
    this.assignedDriverId,
    this.assignedDriverName,
    required this.isActive,
  });

  String get displayName => '$plateNumber — $make $model ($year)';

  factory VehicleModel.fromJson(Map<String, dynamic> j) => VehicleModel(
        id: j['id'] as String,
        plateNumber: j['plate_number'] as String,
        make: j['make'] as String,
        model: j['model'] as String,
        year: j['year'] as int,
        fuelType: j['fuel_type'] as String,
        tankCapacity: (j['tank_capacity'] as num).toDouble(),
        fuelEfficiency: (j['fuel_efficiency'] as num?)?.toDouble() ?? 10.0,
        assignedDriverId: j['user_id'] as String?,
        assignedDriverName: (j['assigned_driver']?['name'] ?? j['assigned_driver']?['full_name']) as String?,
        isActive: j['is_active'] as bool? ?? true,
      );
}
