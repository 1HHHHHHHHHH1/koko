import 'package:equatable/equatable.dart';

class Rating extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String targetId;
  final String targetType; // 'investor', 'entrepreneur', 'project'
  final int score; // 1-5
  final String? comment;
  final DateTime createdAt;

  const Rating({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.targetId,
    required this.targetType,
    required this.score,
    this.comment,
    required this.createdAt,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: json['id'] ?? json['_id'] ?? '',
      userId: json['user_id'] ?? json['userId'] ?? '',
      userName: json['user_name'] ?? json['userName'] ?? '',
      userAvatar: json['user_avatar'] ?? json['userAvatar'],
      targetId: json['target_id'] ?? json['targetId'] ?? '',
      targetType: json['target_type'] ?? json['targetType'] ?? '',
      score: json['score'] ?? 0,
      comment: json['comment'],
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
      'user_name': userName,
      'user_avatar': userAvatar,
      'target_id': targetId,
      'target_type': targetType,
      'score': score,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        userName,
        userAvatar,
        targetId,
        targetType,
        score,
        comment,
        createdAt,
      ];
}

class RatingSummary extends Equatable {
  final String targetId;
  final double averageRating;
  final int totalRatings;
  final Map<int, int> distribution; // score -> count

  const RatingSummary({
    required this.targetId,
    required this.averageRating,
    required this.totalRatings,
    required this.distribution,
  });

  factory RatingSummary.fromJson(Map<String, dynamic> json) {
    final dist = json['distribution'] ?? json['Distribution'] ?? {};
    final Map<int, int> distribution = {};
    
    dist.forEach((key, value) {
      distribution[int.parse(key.toString())] = value as int;
    });

    return RatingSummary(
      targetId: json['target_id'] ?? json['targetId'] ?? '',
      averageRating:
          (json['average_rating'] ?? json['averageRating'] ?? 0).toDouble(),
      totalRatings: json['total_ratings'] ?? json['totalRatings'] ?? 0,
      distribution: distribution,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, int> dist = {};
    distribution.forEach((key, value) {
      dist[key.toString()] = value;
    });

    return {
      'target_id': targetId,
      'average_rating': averageRating,
      'total_ratings': totalRatings,
      'distribution': dist,
    };
  }

  String get formattedRating => averageRating.toStringAsFixed(1);

  @override
  List<Object?> get props => [
        targetId,
        averageRating,
        totalRatings,
        distribution,
      ];
}
