class FuelRequestModel {
  final String id;
  final String driverId;
  final String? driverName;
  final String vehicleId;
  final String? vehiclePlate;
  final double requestedLiters;
  final String purpose;
  final double? odometerBefore;
  final double? odometerAfter;
  final String status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? fulfilledAt;
  final DateTime? approvedAt;
  final double? estimatedDistance;
  final double? expectedFuel;
  final String? fuelVariance;

  FuelRequestModel({
    required this.id,
    required this.driverId,
    this.driverName,
    required this.vehicleId,
    this.vehiclePlate,
    required this.requestedLiters,
    required this.purpose,
    this.odometerBefore,
    this.odometerAfter,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
    this.fulfilledAt,
    this.approvedAt,
    this.estimatedDistance,
    this.expectedFuel,
    this.fuelVariance,
  });

  factory FuelRequestModel.fromJson(Map<String, dynamic> json) => FuelRequestModel(
        id: json['id'] as String,
        driverId: json['driver_id'] as String,
        driverName: json['driver']?['full_name'] as String?,
        vehicleId: json['vehicle_id'] as String,
        vehiclePlate: json['vehicle']?['plate_number'] as String?,
        requestedLiters: (json['requested_liters'] as num).toDouble(),
        purpose: json['purpose'] as String,
        odometerBefore: (json['odometer_before'] as num?)?.toDouble(),
        odometerAfter: (json['odometer_after'] as num?)?.toDouble(),
        status: json['status'] as String,
        rejectionReason: json['rejection_reason'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        fulfilledAt: json['fulfilled_at'] != null ? DateTime.parse(json['fulfilled_at'] as String) : null,
        approvedAt: json['approved_at'] != null ? DateTime.parse(json['approved_at'] as String) : null,
        estimatedDistance: (json['estimated_distance'] as num?)?.toDouble(),
        expectedFuel: (json['expected_fuel'] as num?)?.toDouble(),
        fuelVariance: json['fuel_variance'] as String?,
      );
}
