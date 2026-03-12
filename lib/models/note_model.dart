/// Note / Task model — menggunakan Firestore document ID (String)
class NoteModel {
  final String id;
  final String userId;
  final String title;
  final String? content;
  final bool isTask;
  final bool isCompleted;
  final String color;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NoteModel({
    required this.id,
    required this.userId,
    required this.title,
    this.content,
    required this.isTask,
    required this.isCompleted,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return NoteModel(
      id:          docId ?? json['id'] as String? ?? '',
      userId:      json['user_id'] as String? ?? '',
      title:       json['title'] as String,
      content:     json['content'] as String?,
      isTask:      json['is_task'] as bool? ?? false,
      isCompleted: json['is_completed'] as bool? ?? false,
      color:       json['color'] as String? ?? '#FFFFFF',
      createdAt:   json['created_at'] is String
          ? DateTime.parse(json['created_at'] as String)
          : (json['created_at'] as dynamic)?.toDate() ?? DateTime.now(),
      updatedAt:   json['updated_at'] is String
          ? DateTime.parse(json['updated_at'] as String)
          : (json['updated_at'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id':      userId,
    'title':        title,
    'content':      content,
    'is_task':      isTask,
    'is_completed': isCompleted,
    'color':        color,
    'created_at':   createdAt.toIso8601String(),
    'updated_at':   updatedAt.toIso8601String(),
  };

  NoteModel copyWith({
    String? title,
    String? content,
    bool? isTask,
    bool? isCompleted,
    String? color,
  }) {
    return NoteModel(
      id:          id,
      userId:      userId,
      title:       title ?? this.title,
      content:     content ?? this.content,
      isTask:      isTask ?? this.isTask,
      isCompleted: isCompleted ?? this.isCompleted,
      color:       color ?? this.color,
      createdAt:   createdAt,
      updatedAt:   DateTime.now(),
    );
  }
}
