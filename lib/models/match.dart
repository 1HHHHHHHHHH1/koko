import 'package:equatable/equatable.dart';
import 'investor.dart';
import 'project.dart';

class Match extends Equatable {
  final String id;
  final String targetId;
  final String targetType; // 'investor' or 'project'
  final double matchPercentage;
  final List<String>? matchingCriteria;
  final Investor? investor;
  final Project? project;
  final DateTime? createdAt;

  const Match({
    required this.id,
    required this.targetId,
    required this.targetType,
    required this.matchPercentage,
    this.matchingCriteria,
    this.investor,
    this.project,
    this.createdAt,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'] ?? json['_id'] ?? '',
      targetId: json['target_id'] ?? json['targetId'] ?? '',
      targetType: json['target_type'] ?? json['targetType'] ?? '',
      matchPercentage:
          (json['match_percentage'] ?? json['matchPercentage'] ?? 0)
              .toDouble(),
      matchingCriteria: json['matching_criteria'] != null
          ? List<String>.from(json['matching_criteria'])
          : json['matchingCriteria'] != null
              ? List<String>.from(json['matchingCriteria'])
              : null,
      investor: json['investor'] != null
          ? Investor.fromJson(json['investor'])
          : null,
      project:
          json['project'] != null ? Project.fromJson(json['project']) : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'target_id': targetId,
      'target_type': targetType,
      'match_percentage': matchPercentage,
      'matching_criteria': matchingCriteria,
      'investor': investor?.toJson(),
      'project': project?.toJson(),
      'created_at': createdAt?.toIso8601String(),
    };
  }

  String get formattedMatchPercentage => '${matchPercentage.toStringAsFixed(0)}%';

  bool get isInvestorMatch => targetType == 'investor';
  bool get isProjectMatch => targetType == 'project';

  @override
  List<Object?> get props => [
        id,
        targetId,
        targetType,
        matchPercentage,
        matchingCriteria,
        investor,
        project,
        createdAt,
      ];
}
