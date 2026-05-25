class SyncQueueItem {
  late String localId; // client-side generated UUID
  late String title;
  late String description;
  late String filePath;
  late String mimeType;
  late String uploadedByUserId;
  late String uploadedByUserName;
  late DateTime createdAt;
  late String syncStatus; // 'pending' | 'failed'
  String? errorMessage;

  SyncQueueItem({
    required this.localId,
    required this.title,
    required this.description,
    required this.filePath,
    required this.mimeType,
    required this.uploadedByUserId,
    required this.uploadedByUserName,
    required this.createdAt,
    required this.syncStatus,
    this.errorMessage,
  });

  SyncQueueItem.empty();

  Map<String, dynamic> toJson() => {
        'localId': localId,
        'title': title,
        'description': description,
        'filePath': filePath,
        'mimeType': mimeType,
        'uploadedByUserId': uploadedByUserId,
        'uploadedByUserName': uploadedByUserName,
        'createdAt': createdAt.toIso8601String(),
        'syncStatus': syncStatus,
        'errorMessage': errorMessage,
      };

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) => SyncQueueItem(
        localId: json['localId'] ?? '',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        filePath: json['filePath'] ?? '',
        mimeType: json['mimeType'] ?? '',
        uploadedByUserId: json['uploadedByUserId'] ?? '',
        uploadedByUserName: json['uploadedByUserName'] ?? '',
        createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
        syncStatus: json['syncStatus'] ?? 'pending',
        errorMessage: json['errorMessage'],
      );
}
