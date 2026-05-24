class CachedDocument {
  late String serverId;
  late String title;
  late String description;
  late String fileName;
  late String fileUrl;
  late int fileSize;
  late String mimeType;
  late String uploadedByUserId;
  late String uploadedByUserName;
  late String uploadedByUserRole;
  late String status; // Draft, Submitted, Under Review, Approved, Rejected
  late int version;
  late DateTime createdAt;
  late DateTime updatedAt;

  CachedDocument({
    required this.serverId,
    required this.title,
    required this.description,
    required this.fileName,
    required this.fileUrl,
    required this.fileSize,
    required this.mimeType,
    required this.uploadedByUserId,
    required this.uploadedByUserName,
    required this.uploadedByUserRole,
    required this.status,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
  });

  CachedDocument.empty();

  Map<String, dynamic> toJson() => {
        'serverId': serverId,
        'title': title,
        'description': description,
        'fileName': fileName,
        'fileUrl': fileUrl,
        'fileSize': fileSize,
        'mimeType': mimeType,
        'uploadedByUserId': uploadedByUserId,
        'uploadedByUserName': uploadedByUserName,
        'uploadedByUserRole': uploadedByUserRole,
        'status': status,
        'version': version,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory CachedDocument.fromJson(Map<String, dynamic> json) => CachedDocument(
        serverId: json['serverId'] ?? '',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        fileName: json['fileName'] ?? '',
        fileUrl: json['fileUrl'] ?? '',
        fileSize: json['fileSize'] ?? 0,
        mimeType: json['mimeType'] ?? '',
        uploadedByUserId: json['uploadedByUserId'] ?? '',
        uploadedByUserName: json['uploadedByUserName'] ?? '',
        uploadedByUserRole: json['uploadedByUserRole'] ?? '',
        status: json['status'] ?? 'Draft',
        version: json['version'] ?? 1,
        createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
        updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      );
}
