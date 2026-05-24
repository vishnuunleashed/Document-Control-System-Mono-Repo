import '../datasources/local/cached_document.dart';

class DocumentModel {
  final String id;
  final String title;
  final String description;
  final String fileName;
  final String fileUrl;
  final int fileSize;
  final String mimeType;
  final String uploadedByUserId;
  final String uploadedByUserName;
  final String uploadedByUserRole;
  final int version;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  DocumentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.fileName,
    required this.fileUrl,
    required this.fileSize,
    required this.mimeType,
    required this.uploadedByUserId,
    required this.uploadedByUserName,
    required this.uploadedByUserRole,
    required this.version,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    // uploadedBy can be populate object or ObjectId string
    final uploadedBy = json['uploadedBy'];
    String uId = '';
    String uName = 'Unknown';
    String uRole = 'Employee';

    if (uploadedBy is Map) {
      uId = uploadedBy['_id'] ?? '';
      uName = uploadedBy['name'] ?? 'Unknown';
      uRole = uploadedBy['role'] ?? 'Employee';
    } else if (uploadedBy is String) {
      uId = uploadedBy;
    }

    return DocumentModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      fileName: json['fileName'] ?? '',
      fileUrl: json['fileUrl'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      mimeType: json['mimeType'] ?? '',
      uploadedByUserId: uId,
      uploadedByUserName: uName,
      uploadedByUserRole: uRole,
      version: json['version'] ?? 1,
      status: json['status'] ?? 'Draft',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  factory DocumentModel.fromCached(CachedDocument cached) {
    return DocumentModel(
      id: cached.serverId,
      title: cached.title,
      description: cached.description,
      fileName: cached.fileName,
      fileUrl: cached.fileUrl,
      fileSize: cached.fileSize,
      mimeType: cached.mimeType,
      uploadedByUserId: cached.uploadedByUserId,
      uploadedByUserName: cached.uploadedByUserName,
      uploadedByUserRole: cached.uploadedByUserRole,
      version: cached.version,
      status: cached.status,
      createdAt: cached.createdAt,
      updatedAt: cached.updatedAt,
    );
  }

  CachedDocument toCached() {
    return CachedDocument.empty()
      ..serverId = id
      ..title = title
      ..description = description
      ..fileName = fileName
      ..fileUrl = fileUrl
      ..fileSize = fileSize
      ..mimeType = mimeType
      ..uploadedByUserId = uploadedByUserId
      ..uploadedByUserName = uploadedByUserName
      ..uploadedByUserRole = uploadedByUserRole
      ..status = status
      ..version = version
      ..createdAt = createdAt
      ..updatedAt = updatedAt;
  }
}
