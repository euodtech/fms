import 'dart:convert';

enum OfflineActionType { finish, cancel, reschedule }

enum OfflineQueueStatus { pending, syncing }

class OfflineQueueItem {
  final int? id;
  final int jobId;
  final OfflineActionType actionType;
  final Map<String, dynamic> payload;
  final List<String>? imagePaths;
  final OfflineQueueStatus status;
  final int retryCount;
  final DateTime createdAt;

  OfflineQueueItem({
    this.id,
    required this.jobId,
    required this.actionType,
    required this.payload,
    this.imagePaths,
    required this.status,
    this.retryCount = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'job_id': jobId,
    'action_type': actionType.name,
    'payload': jsonEncode(payload),
    'image_paths': imagePaths != null ? jsonEncode(imagePaths) : null,
    'status': status.name,
    'retry_count': retryCount,
    'created_at': createdAt.toIso8601String(),
  };

  factory OfflineQueueItem.fromMap(Map<String, dynamic> map) {
    return OfflineQueueItem(
      id: map['id'] as int?,
      jobId: map['job_id'] as int,
      actionType: OfflineActionType.values.byName(map['action_type'] as String),
      payload: jsonDecode(map['payload'] as String) as Map<String, dynamic>,
      imagePaths: map['image_paths'] != null
          ? List<String>.from(jsonDecode(map['image_paths'] as String))
          : null,
      status: OfflineQueueStatus.values.byName(map['status'] as String),
      retryCount: (map['retry_count'] as int?) ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
