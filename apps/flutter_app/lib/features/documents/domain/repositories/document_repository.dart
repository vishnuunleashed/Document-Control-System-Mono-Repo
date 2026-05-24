import 'dart:typed_data';
import '../../data/models/document_model.dart';
import '../../data/datasources/local/sync_queue_item.dart';

abstract class DocumentRepository {
  Future<List<DocumentModel>> getDocuments({String? status, String? search});
  Future<DocumentModel> uploadDocument(
    String title,
    String description,
    String filePath, {
    Uint8List? fileBytes,
    String? fileName,
  });
  Future<void> updateDocument(String id, String title, String description);
  Future<void> deleteDocument(String id);
  Future<List<SyncQueueItem>> getOfflineQueue();
  Future<void> syncOfflineQueue();
}
