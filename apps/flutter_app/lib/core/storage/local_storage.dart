import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/documents/data/datasources/local/cached_document.dart';
import '../../features/documents/data/datasources/local/sync_queue_item.dart';

class LocalStorageService {
  static File? _docsCacheFile;
  static File? _queueCacheFile;

  static List<CachedDocument> _cachedDocs = [];
  static List<SyncQueueItem> _syncQueue = [];

  static List<CachedDocument> get cachedDocsList => _cachedDocs;

  static Future<void> init() async {
    if (kIsWeb) {
      // Memory-only fallback for Web
      return;
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      _docsCacheFile = File('${dir.path}/documents_cache.json');
      _queueCacheFile = File('${dir.path}/sync_queue_cache.json');

      // Load documents cache
      if (await _docsCacheFile!.exists()) {
        final content = await _docsCacheFile!.readAsString();
        if (content.isNotEmpty) {
          final List<dynamic> jsonList = jsonDecode(content);
          _cachedDocs = jsonList.map((j) => CachedDocument.fromJson(j)).toList();
        }
      }

      // Load sync queue
      if (await _queueCacheFile!.exists()) {
        final content = await _queueCacheFile!.readAsString();
        if (content.isNotEmpty) {
          final List<dynamic> jsonList = jsonDecode(content);
          _syncQueue = jsonList.map((j) => SyncQueueItem.fromJson(j)).toList();
        }
      }
    } catch (e) {
      print("⚠️ LocalStorageService init failed: $e");
    }
  }

  static Future<void> _saveDocs() async {
    if (kIsWeb || _docsCacheFile == null) return;
    try {
      final content = jsonEncode(_cachedDocs.map((d) => d.toJson()).toList());
      await _docsCacheFile!.writeAsString(content);
    } catch (e) {
      print("❌ Failed to save documents cache: $e");
    }
  }

  static Future<void> _saveQueue() async {
    if (kIsWeb || _queueCacheFile == null) return;
    try {
      final content = jsonEncode(_syncQueue.map((i) => i.toJson()).toList());
      await _queueCacheFile!.writeAsString(content);
    } catch (e) {
      print("❌ Failed to save sync queue: $e");
    }
  }

  // --- Cached Documents API ---

  static Future<List<CachedDocument>> getCachedDocuments() async {
    // Sort by updatedAt descending
    _cachedDocs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.from(_cachedDocs);
  }

  static Future<void> cacheDocuments(List<CachedDocument> docs) async {
    _cachedDocs = List.from(docs);
    await _saveDocs();
  }

  static Future<void> addOrUpdateCachedDocument(CachedDocument doc) async {
    final index = _cachedDocs.indexWhere((d) => d.serverId == doc.serverId);
    if (index >= 0) {
      _cachedDocs[index] = doc;
    } else {
      _cachedDocs.add(doc);
    }
    await _saveDocs();
  }

  static Future<void> deleteCachedDocument(String serverId) async {
    _cachedDocs.removeWhere((d) => d.serverId == serverId);
    await _saveDocs();
  }

  // --- Sync Queue API ---

  static Future<List<SyncQueueItem>> getSyncQueue() async {
    // Sort by createdAt ascending (FIFO queue)
    _syncQueue.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return List.from(_syncQueue);
  }

  static Future<void> addToSyncQueue(SyncQueueItem item) async {
    _syncQueue.add(item);
    await _saveQueue();
  }

  static Future<void> updateSyncQueueItem(SyncQueueItem item) async {
    final index = _syncQueue.indexWhere((i) => i.localId == item.localId);
    if (index >= 0) {
      _syncQueue[index] = item;
      await _saveQueue();
    }
  }

  static Future<void> removeFromSyncQueue(String localId) async {
    _syncQueue.removeWhere((i) => i.localId == localId);
    await _saveQueue();
  }

  static Future<void> clearAll() async {
    _cachedDocs.clear();
    _syncQueue.clear();
    await _saveDocs();
    await _saveQueue();
  }
}
