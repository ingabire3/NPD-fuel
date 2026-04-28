class AllocationModel {
  final String id;
  final String userId;
  final String vehicleId;
  final int month;
  final int year;
  final double allocatedLiters;
  final double allocatedAmount;
  final double remainingLiters;
  final String? userName;
  final String? vehiclePlate;
  final DateTime createdAt;

  AllocationModel({
    required this.id,
    required this.userId,
    required this.vehicleId,
    required this.month,
    required this.year,
    required this.allocatedLiters,
    required this.allocatedAmount,
    required this.remainingLiters,
    this.userName,
    this.vehiclePlate,
    required this.createdAt,
  });

  double get usedLiters => allocatedLiters - remainingLiters;
  double get usagePercent => allocatedLiters > 0 ? (usedLiters / allocatedLiters).clamp(0.0, 1.0) : 0;

  static final _monthNames = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  String get monthLabel => '${_monthNames[month]} $year';

  factory AllocationModel.fromJson(Map<String, dynamic> j) => AllocationModel(
        id: j['id'] as String,
        userId: j['user_id'] as String,
        vehicleId: j['vehicle_id'] as String,
        month: j['month'] as int,
        year: j['year'] as int,
        allocatedLiters: (j['allocated_liters'] as num).toDouble(),
        allocatedAmount: (j['allocated_amount'] as num).toDouble(),
        remainingLiters: (j['remaining_liters'] as num).toDouble(),
        userName: j['user']?['full_name'] as String?,
        vehiclePlate: j['vehicle']?['plate_number'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}
