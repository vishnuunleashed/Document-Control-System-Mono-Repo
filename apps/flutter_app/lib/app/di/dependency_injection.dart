import '../../core/network/api_client.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/documents/data/repositories/document_repository_impl.dart';
import '../../features/documents/domain/repositories/document_repository.dart';
import '../../features/approvals/data/repositories/approval_repository_impl.dart';
import '../../features/approvals/domain/repositories/approval_repository.dart';
import '../../core/storage/local_storage.dart';
import '../../shared/services/session_manager.dart';

class DependencyInjection {
  static late final ApiClient apiClient;
  static late final AuthRepository authRepository;
  static late final DocumentRepository documentRepository;
  static late final ApprovalRepository approvalRepository;

  static Future<void> init() async {
    // Initialize Local Cache DB and Sessions
    await LocalStorageService.init();
    await SessionManager.init();

    // Initialize Network Client
    apiClient = ApiClient();

    // Initialize Feature Repositories
    authRepository = AuthRepositoryImpl(apiClient);
    documentRepository = DocumentRepositoryImpl(apiClient);
    approvalRepository = ApprovalRepositoryImpl(apiClient);
  }
}
