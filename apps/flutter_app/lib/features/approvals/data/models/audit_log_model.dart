class AuditLogModel {
  final String id;
  final String documentId;
  final String action; // Create, Update, Submit, Review, Approve, Reject
  final String performedByUserId;
  final String performedByUserName;
  final String performedByUserRole;
  final String comments;
  final int version;
  final DateTime timestamp;

  AuditLogModel({
    required this.id,
    required this.documentId,
    required this.action,
    required this.performedByUserId,
    required this.performedByUserName,
    required this.performedByUserRole,
    required this.comments,
    required this.version,
    required this.timestamp,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    final performedBy = json['performedBy'];
    String uId = '';
    String uName = 'System';
    String uRole = 'Employee';

    if (performedBy is Map) {
      uId = performedBy['_id'] ?? '';
      uName = performedBy['name'] ?? 'System';
      uRole = performedBy['role'] ?? 'Employee';
    } else if (performedBy is String) {
      uId = performedBy;
    }

    return AuditLogModel(
      id: json['_id'] ?? '',
      documentId: json['documentId'] ?? '',
      action: json['action'] ?? '',
      performedByUserId: uId,
      performedByUserName: uName,
      performedByUserRole: uRole,
      comments: json['comments'] ?? '',
      version: json['version'] ?? 1,
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}
