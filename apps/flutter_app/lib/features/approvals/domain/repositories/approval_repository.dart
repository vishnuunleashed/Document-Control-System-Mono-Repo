import '../../data/models/audit_log_model.dart';

abstract class ApprovalRepository {
  Future<void> submitDocument(String documentId, {String? comments});
  Future<void> reviewDocument(String documentId, {String? comments});
  Future<void> actionDocument(String documentId, String action, String comments);
  Future<List<AuditLogModel>> getAuditLogs(String documentId);
}
