import 'package:equatable/equatable.dart';

class Like extends Equatable {
  final String id;
  final String userId;
  final String targetId;
  final String targetType; // 'investor', 'entrepreneur', 'project'
  final DateTime createdAt;

  const Like({
    required this.id,
    required this.userId,
    required this.targetId,
    required this.targetType,
    required this.createdAt,
  });

  factory Like.fromJson(Map<String, dynamic> json) {
    return Like(
      id: json['id'] ?? json['_id'] ?? '',
      userId: json['user_id'] ?? json['userId'] ?? '',
      targetId: json['target_id'] ?? json['targetId'] ?? '',
      targetType: json['target_type'] ?? json['targetType'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'target_id': targetId,
      'target_type': targetType,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        targetId,
        targetType,
        createdAt,
      ];
}
