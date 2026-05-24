import '../../../../core/network/api_client.dart';
import '../../data/models/audit_log_model.dart';
import '../../domain/repositories/approval_repository.dart';

class ApprovalRepositoryImpl implements ApprovalRepository {
  final ApiClient _apiClient;

  ApprovalRepositoryImpl(this._apiClient);

  @override
  Future<void> submitDocument(String documentId, {String? comments}) async {
    await _apiClient.post('/approvals/$documentId/submit', data: {
      'comments': comments ?? '',
    });
  }

  @override
  Future<void> reviewDocument(String documentId, {String? comments}) async {
    await _apiClient.post('/approvals/$documentId/review', data: {
      'comments': comments ?? '',
    });
  }

  @override
  Future<void> actionDocument(String documentId, String action, String comments) async {
    await _apiClient.post('/approvals/$documentId/action', data: {
      'action': action, // 'Approved' | 'Rejected'
      'comments': comments,
    });
  }

  @override
  Future<List<AuditLogModel>> getAuditLogs(String documentId) async {
    final response = await _apiClient.get('/approvals/logs/$documentId');
    final List<dynamic> logsList = response.data['logs'] ?? [];
    return logsList.map((json) => AuditLogModel.fromJson(json)).toList();
  }
}
