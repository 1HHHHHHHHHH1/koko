import 'package:equatable/equatable.dart';

class Project extends Equatable {
  final String id;
  final String ownerId;
  final String ownerName;
  final String? ownerAvatar;
  final String title;
  final String description;
  final String industry;
  final String stage;
  final double fundingGoal;
  final double? fundingRaised;
  final String? pitchDeck;
  final String? website;
  final String? videoUrl;
  final List<String>? teamMembers;
  final List<String>? tags;
  final double? averageRating;
  final int? totalRatings;
  final int? totalLikes;
  final bool? isLiked;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Project({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    this.ownerAvatar,
    required this.title,
    required this.description,
    required this.industry,
    required this.stage,
    required this.fundingGoal,
    this.fundingRaised,
    this.pitchDeck,
    this.website,
    this.videoUrl,
    this.teamMembers,
    this.tags,
    this.averageRating,
    this.totalRatings,
    this.totalLikes,
    this.isLiked,
    this.createdAt,
    this.updatedAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] ?? json['_id'] ?? '',
      ownerId: json['owner_id'] ?? json['ownerId'] ?? '',
      ownerName: json['owner_name'] ?? json['ownerName'] ?? '',
      ownerAvatar: json['owner_avatar'] ?? json['ownerAvatar'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      industry: json['industry'] ?? '',
      stage: json['stage'] ?? '',
      fundingGoal: (json['funding_goal'] ?? json['fundingGoal'] ?? 0).toDouble(),
      fundingRaised: json['funding_raised']?.toDouble() ??
          json['fundingRaised']?.toDouble(),
      pitchDeck: json['pitch_deck'] ?? json['pitchDeck'],
      website: json['website'],
      videoUrl: json['video_url'] ?? json['videoUrl'],
      teamMembers: json['team_members'] != null
          ? List<String>.from(json['team_members'])
          : json['teamMembers'] != null
              ? List<String>.from(json['teamMembers'])
              : null,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      averageRating: json['average_rating']?.toDouble() ??
          json['averageRating']?.toDouble(),
      totalRatings: json['total_ratings'] ?? json['totalRatings'],
      totalLikes: json['total_likes'] ?? json['totalLikes'],
      isLiked: json['is_liked'] ?? json['isLiked'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'owner_name': ownerName,
      'owner_avatar': ownerAvatar,
      'title': title,
      'description': description,
      'industry': industry,
      'stage': stage,
      'funding_goal': fundingGoal,
      'funding_raised': fundingRaised,
      'pitch_deck': pitchDeck,
      'website': website,
      'video_url': videoUrl,
      'team_members': teamMembers,
      'tags': tags,
      'average_rating': averageRating,
      'total_ratings': totalRatings,
      'total_likes': totalLikes,
      'is_liked': isLiked,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Project copyWith({
    String? id,
    String? ownerId,
    String? ownerName,
    String? ownerAvatar,
    String? title,
    String? description,
    String? industry,
    String? stage,
    double? fundingGoal,
    double? fundingRaised,
    String? pitchDeck,
    String? website,
    String? videoUrl,
    List<String>? teamMembers,
    List<String>? tags,
    double? averageRating,
    int? totalRatings,
    int? totalLikes,
    bool? isLiked,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerAvatar: ownerAvatar ?? this.ownerAvatar,
      title: title ?? this.title,
      description: description ?? this.description,
      industry: industry ?? this.industry,
      stage: stage ?? this.stage,
      fundingGoal: fundingGoal ?? this.fundingGoal,
      fundingRaised: fundingRaised ?? this.fundingRaised,
      pitchDeck: pitchDeck ?? this.pitchDeck,
      website: website ?? this.website,
      videoUrl: videoUrl ?? this.videoUrl,
      teamMembers: teamMembers ?? this.teamMembers,
      tags: tags ?? this.tags,
      averageRating: averageRating ?? this.averageRating,
      totalRatings: totalRatings ?? this.totalRatings,
      totalLikes: totalLikes ?? this.totalLikes,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double get fundingProgress {
    if (fundingGoal == 0) return 0;
    return ((fundingRaised ?? 0) / fundingGoal) * 100;
  }

  String get formattedFundingGoal {
    if (fundingGoal >= 1000000) {
      return '\$${(fundingGoal / 1000000).toStringAsFixed(1)}M';
    } else if (fundingGoal >= 1000) {
      return '\$${(fundingGoal / 1000).toStringAsFixed(0)}K';
    }
    return '\$${fundingGoal.toStringAsFixed(0)}';
  }

  @override
  List<Object?> get props => [
        id,
        ownerId,
        ownerName,
        ownerAvatar,
        title,
        description,
        industry,
        stage,
        fundingGoal,
        fundingRaised,
        pitchDeck,
        website,
        videoUrl,
        teamMembers,
        tags,
        averageRating,
        totalRatings,
        totalLikes,
        isLiked,
        createdAt,
        updatedAt,
      ];
}
