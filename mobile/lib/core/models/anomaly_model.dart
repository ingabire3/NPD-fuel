class AnomalyModel {
  final String id;
  final String? requestId;
  final String userId;
  final String? userName;
  final String type;
  final String description;
  final String status;
  final String? resolvedBy;
  final String? resolution;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  AnomalyModel({
    required this.id,
    this.requestId,
    required this.userId,
    this.userName,
    required this.type,
    required this.description,
    required this.status,
    this.resolvedBy,
    this.resolution,
    required this.createdAt,
    this.resolvedAt,
  });

  bool get isOpen => status == 'OPEN';

  factory AnomalyModel.fromJson(Map<String, dynamic> j) => AnomalyModel(
        id: j['id'] as String,
        requestId: j['request_id'] as String?,
        userId: j['user_id'] as String,
        userName: j['user']?['full_name'] as String?,
        type: j['type'] as String,
        description: j['description'] as String,
        status: j['status'] as String,
        resolvedBy: j['resolved_by'] as String?,
        resolution: j['resolution'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
        resolvedAt: j['resolved_at'] != null ? DateTime.parse(j['resolved_at'] as String) : null,
      );
}
