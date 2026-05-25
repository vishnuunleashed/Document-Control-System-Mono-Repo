import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../shared/services/session_manager.dart';
import '../../data/datasources/local/cached_document.dart';
import '../../data/datasources/local/sync_queue_item.dart';
import '../models/document_model.dart';
import '../../domain/repositories/document_repository.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  final ApiClient _apiClient;

  DocumentRepositoryImpl(this._apiClient);

  Future<bool> _isOnline() async {
    try {
      final dynamic result = await Connectivity().checkConnectivity();
      if (result is List) {
        return result.isNotEmpty && !result.contains(ConnectivityResult.none);
      } else {
        return result != ConnectivityResult.none;
      }
    } catch (e) {
      return true; // Fallback to online, let API call throw on network failure
    }
  }

  @override
  Future<List<DocumentModel>> getDocuments({String? status, String? search}) async {
    final online = await _isOnline();

    if (online) {
      try {
        final queryParams = <String, dynamic>{};
        if (status != null && status.isNotEmpty) queryParams['status'] = status;
        if (search != null && search.isNotEmpty) queryParams['search'] = search;

        final response = await _apiClient.get('/documents', queryParameters: queryParams);
        final List<dynamic> docList = response.data['documents'] ?? [];
        
        final List<DocumentModel> docs = docList.map((json) => DocumentModel.fromJson(json)).toList();

        // Update local cache
        final cachedDocs = docs.map((d) => d.toCached()).toList();
        await LocalStorageService.cacheDocuments(cachedDocs);

        return docs;
      } catch (e) {
        // If API fails due to server down, fall back to cache
        return _getLocalCachedDocuments(status, search);
      }
    } else {
      return _getLocalCachedDocuments(status, search);
    }
  }

  List<DocumentModel> _getLocalCachedDocuments(String? status, String? search) {
    final allCached = LocalStorageService.cachedDocsList;
    
    var filtered = allCached;
    if (status != null && status.isNotEmpty) {
      filtered = filtered.where((d) => d.status.toLowerCase() == status.toLowerCase()).toList();
    }
    if (search != null && search.isNotEmpty) {
      filtered = filtered.where((d) => d.title.toLowerCase().contains(search.toLowerCase())).toList();
    }

    return filtered.map((d) => DocumentModel.fromCached(d)).toList();
  }

  @override
  Future<DocumentModel> uploadDocument(
    String title,
    String description,
    String filePath, {
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    final online = await _isOnline();

    if (online) {
      MultipartFile fileField;
      String finalFileName = fileName ?? "";
      String mimeType = 'application/octet-stream';

      if (kIsWeb) {
        if (fileBytes == null) {
          throw Exception("File bytes are required for web upload");
        }
        final ext = '.${finalFileName.split('.').last}'.toLowerCase();
        if (ext == '.pdf') mimeType = 'application/pdf';
        else if (ext == '.docx') mimeType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
        else if (ext == '.png') mimeType = 'image/png';
        else if (ext == '.jpg' || ext == '.jpeg') mimeType = 'image/jpeg';

        fileField = MultipartFile.fromBytes(
          fileBytes,
          filename: finalFileName,
          contentType: DioMediaType.parse(mimeType),
        );
      } else {
        final file = File(filePath);
        if (!await file.exists()) {
          throw Exception("File does not exist at path: $filePath");
        }
        finalFileName = p.basename(filePath);
        final ext = p.extension(filePath).toLowerCase();
        if (ext == '.pdf') mimeType = 'application/pdf';
        else if (ext == '.docx') mimeType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
        else if (ext == '.png') mimeType = 'image/png';
        else if (ext == '.jpg' || ext == '.jpeg') mimeType = 'image/jpeg';

        fileField = await MultipartFile.fromFile(
          filePath,
          filename: finalFileName,
          contentType: DioMediaType.parse(mimeType),
        );
      }

      final formData = FormData.fromMap({
        'title': title,
        'description': description,
        'file': fileField,
      });

      final response = await _apiClient.post('/documents', data: formData);
      final doc = DocumentModel.fromJson(response.data['document']);

      // Add to local cache
      await LocalStorageService.addOrUpdateCachedDocument(doc.toCached());
      return doc;
    } else {
      // Offline mode: Queue document upload
      final localId = const Uuid().v4();
      int size = 0;
      String finalFileName = fileName ?? "";
      String mimeType = 'application/octet-stream';

      if (kIsWeb) {
        size = fileBytes?.length ?? 0;
        final ext = '.${finalFileName.split('.').last}'.toLowerCase();
        if (ext == '.pdf') mimeType = 'application/pdf';
        else if (ext == '.docx') mimeType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
        else if (ext == '.png') mimeType = 'image/png';
        else if (ext == '.jpg' || ext == '.jpeg') mimeType = 'image/jpeg';
      } else {
        final file = File(filePath);
        size = await file.length();
        finalFileName = p.basename(filePath);
        final ext = p.extension(filePath).toLowerCase();
        if (ext == '.pdf') mimeType = 'application/pdf';
        else if (ext == '.docx') mimeType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
        else if (ext == '.png') mimeType = 'image/png';
        else if (ext == '.jpg' || ext == '.jpeg') mimeType = 'image/jpeg';
      }

      // Create a temporary document in our local cache
      final tempCached = CachedDocument(
        serverId: localId,
        title: title,
        description: description,
        fileName: finalFileName,
        fileUrl: kIsWeb ? "web-file" : filePath, // point to local file path or placeholder
        fileSize: size,
        mimeType: mimeType,
        uploadedByUserId: SessionManager.userId,
        uploadedByUserName: SessionManager.userName,
        uploadedByUserRole: SessionManager.userRole,
        status: 'Draft',
        version: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await LocalStorageService.addOrUpdateCachedDocument(tempCached);

      // Add to sync queue
      final queueItem = SyncQueueItem(
        localId: localId,
        title: title,
        description: description,
        filePath: kIsWeb ? "web-file" : filePath,
        mimeType: mimeType,
        uploadedByUserId: SessionManager.userId,
        uploadedByUserName: SessionManager.userName,
        createdAt: DateTime.now(),
        syncStatus: 'pending',
      );

      await LocalStorageService.addToSyncQueue(queueItem);

      return DocumentModel.fromCached(tempCached);
    }
  }

  @override
  Future<void> updateDocument(String id, String title, String description) async {
    final online = await _isOnline();
    if (online) {
      await _apiClient.put('/documents/$id', data: {
        'title': title,
        'description': description,
      });
      
      // Update cache
      final docList = LocalStorageService.cachedDocsList.where((d) => d.serverId == id).toList();
      final doc = docList.isNotEmpty ? docList.first : null;
      if (doc != null) {
        doc.title = title;
        doc.description = description;
        doc.updatedAt = DateTime.now();
        await LocalStorageService.addOrUpdateCachedDocument(doc);
      }
    } else {
      throw Exception("You must be online to update document metadata");
    }
  }

  @override
  Future<void> deleteDocument(String id) async {
    final online = await _isOnline();
    if (online) {
      await _apiClient.delete('/documents/$id');
      await LocalStorageService.deleteCachedDocument(id);
    } else {
      // Check if it's a queued offline item
      final queue = await LocalStorageService.getSyncQueue();
      final isQueued = queue.any((i) => i.localId == id);
      if (isQueued) {
        await LocalStorageService.removeFromSyncQueue(id);
        await LocalStorageService.deleteCachedDocument(id);
      } else {
        throw Exception("You must be online to delete documents synced with the server");
      }
    }
  }

  @override
  Future<List<SyncQueueItem>> getOfflineQueue() async {
    return await LocalStorageService.getSyncQueue();
  }

  @override
  Future<void> syncOfflineQueue() async {
    final online = await _isOnline();
    if (!online) return;

    final queue = await LocalStorageService.getSyncQueue();
    if (queue.isEmpty) return;

    print("📡 DCS Sync Engine: Starting sync of ${queue.length} offline uploads...");

    for (final item in queue) {
      try {
        final file = File(item.filePath);
        if (!await file.exists()) {
          // If file was deleted locally, clean up queue
          await LocalStorageService.removeFromSyncQueue(item.localId);
          await LocalStorageService.deleteCachedDocument(item.localId);
          continue;
        }

        final fileName = p.basename(item.filePath);
        final formData = FormData.fromMap({
          'title': item.title,
          'description': item.description,
          'file': await MultipartFile.fromFile(
            item.filePath,
            filename: fileName,
            contentType: DioMediaType.parse(item.mimeType),
          ),
        });

        final response = await _apiClient.post('/documents', data: formData);
        final serverDoc = DocumentModel.fromJson(response.data['document']);

        // Remove the temporary cache document & add the actual server document
        await LocalStorageService.deleteCachedDocument(item.localId);
        await LocalStorageService.addOrUpdateCachedDocument(serverDoc.toCached());

        // Remove from sync queue
        await LocalStorageService.removeFromSyncQueue(item.localId);
        print("✅ DCS Sync Engine: Successfully synced offline upload: ${item.title}");
      } catch (e) {
        print("❌ DCS Sync Engine: Sync failed for item ${item.localId}: $e");
        item.syncStatus = 'failed';
        item.errorMessage = e.toString();
        await LocalStorageService.updateSyncQueueItem(item);
        // Stop syncing subsequent items to maintain order or let user retry
        break;
      }
    }
  }
}
