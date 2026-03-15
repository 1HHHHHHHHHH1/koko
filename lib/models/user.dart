import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final String userType; // 'entrepreneur' or 'investor'
  final String? avatar;
  final String? bio;
  final String? company;
  final String? position;
  final String? location;
  final String? website;
  final String? linkedIn;
  final List<String>? industries;
  final double? averageRating;
  final int? totalRatings;
  final int? totalLikes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.userType,
    this.avatar,
    this.bio,
    this.company,
    this.position,
    this.location,
    this.website,
    this.linkedIn,
    this.industries,
    this.averageRating,
    this.totalRatings,
    this.totalLikes,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      userType: json['user_type'] ?? json['userType'] ?? 'entrepreneur',
      avatar: json['avatar'],
      bio: json['bio'],
      company: json['company'],
      position: json['position'],
      location: json['location'],
      website: json['website'],
      linkedIn: json['linkedin'] ?? json['linkedIn'],
      industries: json['industries'] != null
          ? List<String>.from(json['industries'])
          : null,
      averageRating: json['average_rating']?.toDouble() ??
          json['averageRating']?.toDouble(),
      totalRatings: json['total_ratings'] ?? json['totalRatings'],
      totalLikes: json['total_likes'] ?? json['totalLikes'],
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
      'email': email,
      'name': name,
      'user_type': userType,
      'avatar': avatar,
      'bio': bio,
      'company': company,
      'position': position,
      'location': location,
      'website': website,
      'linkedin': linkedIn,
      'industries': industries,
      'average_rating': averageRating,
      'total_ratings': totalRatings,
      'total_likes': totalLikes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? userType,
    String? avatar,
    String? bio,
    String? company,
    String? position,
    String? location,
    String? website,
    String? linkedIn,
    List<String>? industries,
    double? averageRating,
    int? totalRatings,
    int? totalLikes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      userType: userType ?? this.userType,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
      company: company ?? this.company,
      position: position ?? this.position,
      location: location ?? this.location,
      website: website ?? this.website,
      linkedIn: linkedIn ?? this.linkedIn,
      industries: industries ?? this.industries,
      averageRating: averageRating ?? this.averageRating,
      totalRatings: totalRatings ?? this.totalRatings,
      totalLikes: totalLikes ?? this.totalLikes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isEntrepreneur => userType == 'entrepreneur';
  bool get isInvestor => userType == 'investor';

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        userType,
        avatar,
        bio,
        company,
        position,
        location,
        website,
        linkedIn,
        industries,
        averageRating,
        totalRatings,
        totalLikes,
        createdAt,
        updatedAt,
      ];
}
