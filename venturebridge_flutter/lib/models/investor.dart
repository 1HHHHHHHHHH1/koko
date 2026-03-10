import 'package:equatable/equatable.dart';

class Investor extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String? avatar;
  final String? bio;
  final String? company;
  final String? position;
  final String? location;
  final InvestmentCriteria? criteria;
  final List<String>? portfolio;
  final double? averageRating;
  final int? totalRatings;
  final int? totalLikes;
  final bool? isLiked;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Investor({
    required this.id,
    required this.userId,
    required this.name,
    this.avatar,
    this.bio,
    this.company,
    this.position,
    this.location,
    this.criteria,
    this.portfolio,
    this.averageRating,
    this.totalRatings,
    this.totalLikes,
    this.isLiked,
    this.createdAt,
    this.updatedAt,
  });

  factory Investor.fromJson(Map<String, dynamic> json) {
    return Investor(
      id: json['id'] ?? json['_id'] ?? '',
      userId: json['user_id'] ?? json['userId'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'],
      bio: json['bio'],
      company: json['company'],
      position: json['position'],
      location: json['location'],
      criteria: json['criteria'] != null
          ? InvestmentCriteria.fromJson(json['criteria'])
          : null,
      portfolio: json['portfolio'] != null
          ? List<String>.from(json['portfolio'])
          : null,
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
      'user_id': userId,
      'name': name,
      'avatar': avatar,
      'bio': bio,
      'company': company,
      'position': position,
      'location': location,
      'criteria': criteria?.toJson(),
      'portfolio': portfolio,
      'average_rating': averageRating,
      'total_ratings': totalRatings,
      'total_likes': totalLikes,
      'is_liked': isLiked,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Investor copyWith({
    String? id,
    String? userId,
    String? name,
    String? avatar,
    String? bio,
    String? company,
    String? position,
    String? location,
    InvestmentCriteria? criteria,
    List<String>? portfolio,
    double? averageRating,
    int? totalRatings,
    int? totalLikes,
    bool? isLiked,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Investor(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
      company: company ?? this.company,
      position: position ?? this.position,
      location: location ?? this.location,
      criteria: criteria ?? this.criteria,
      portfolio: portfolio ?? this.portfolio,
      averageRating: averageRating ?? this.averageRating,
      totalRatings: totalRatings ?? this.totalRatings,
      totalLikes: totalLikes ?? this.totalLikes,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        avatar,
        bio,
        company,
        position,
        location,
        criteria,
        portfolio,
        averageRating,
        totalRatings,
        totalLikes,
        isLiked,
        createdAt,
        updatedAt,
      ];
}

class InvestmentCriteria extends Equatable {
  final List<String> industries;
  final List<String> stages;
  final double minInvestment;
  final double maxInvestment;
  final List<String>? preferredLocations;
  final String? additionalNotes;

  const InvestmentCriteria({
    required this.industries,
    required this.stages,
    required this.minInvestment,
    required this.maxInvestment,
    this.preferredLocations,
    this.additionalNotes,
  });

  factory InvestmentCriteria.fromJson(Map<String, dynamic> json) {
    return InvestmentCriteria(
      industries: json['industries'] != null
          ? List<String>.from(json['industries'])
          : [],
      stages:
          json['stages'] != null ? List<String>.from(json['stages']) : [],
      minInvestment:
          (json['min_investment'] ?? json['minInvestment'] ?? 0).toDouble(),
      maxInvestment:
          (json['max_investment'] ?? json['maxInvestment'] ?? 0).toDouble(),
      preferredLocations: json['preferred_locations'] != null
          ? List<String>.from(json['preferred_locations'])
          : json['preferredLocations'] != null
              ? List<String>.from(json['preferredLocations'])
              : null,
      additionalNotes:
          json['additional_notes'] ?? json['additionalNotes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'industries': industries,
      'stages': stages,
      'min_investment': minInvestment,
      'max_investment': maxInvestment,
      'preferred_locations': preferredLocations,
      'additional_notes': additionalNotes,
    };
  }

  InvestmentCriteria copyWith({
    List<String>? industries,
    List<String>? stages,
    double? minInvestment,
    double? maxInvestment,
    List<String>? preferredLocations,
    String? additionalNotes,
  }) {
    return InvestmentCriteria(
      industries: industries ?? this.industries,
      stages: stages ?? this.stages,
      minInvestment: minInvestment ?? this.minInvestment,
      maxInvestment: maxInvestment ?? this.maxInvestment,
      preferredLocations: preferredLocations ?? this.preferredLocations,
      additionalNotes: additionalNotes ?? this.additionalNotes,
    );
  }

  String get investmentRange {
    String formatAmount(double amount) {
      if (amount >= 1000000) {
        return '\$${(amount / 1000000).toStringAsFixed(1)}M';
      } else if (amount >= 1000) {
        return '\$${(amount / 1000).toStringAsFixed(0)}K';
      }
      return '\$${amount.toStringAsFixed(0)}';
    }

    return '${formatAmount(minInvestment)} - ${formatAmount(maxInvestment)}';
  }

  @override
  List<Object?> get props => [
        industries,
        stages,
        minInvestment,
        maxInvestment,
        preferredLocations,
        additionalNotes,
      ];
}
