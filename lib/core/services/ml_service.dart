// ✅ ml_service.dart
// يتصل بسيرفر ML على Render ويحسب نسبة التوافق
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../constants/ml_backend_constants.dart';
import '../../models/project.dart';
import '../../models/investor.dart';

// ══════════════════════════════════════════════════════════
final mlServiceProvider = Provider<MLService>((ref) => MLService());

class MLService {
  // Change the active backend from MLBackendConstants.
  static const String _base = MLBackendConstants.activeBaseUrl;
  static const Duration _timeout = Duration(seconds: 20);

  final _client = http.Client();

  // ── تنبؤ: مستثمر واحد ↔ مشروع واحد ──────────────────
  Future<MLPrediction> predict({
    required Project project,
    required Investor investor,
  }) async {
    try {
      final res = await _client
          .post(
            Uri.parse('$_base/predict'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'project_description': project.description,
              'project_title': project.title,
              'project_category': project.industry,
              'project_stage': project.stage,
              'project_tags': project.tags ?? const <String>[],
              'funding_goal': project.fundingGoal,
              'investor_name': investor.name,
              'investor_description': _investorDescription(investor),
              'investor_bio': _investorDescription(investor),
              'investor_industries': _investorIndustries(investor),
              'investor_stages': investor.criteria?.stages ?? const <String>[],
              'investor_min_investment': investor.criteria?.minInvestment,
              'investor_max_investment': investor.criteria?.maxInvestment,
            }),
          )
          .timeout(_timeout);

      if (res.statusCode == 200) {
        return MLPrediction.fromJson(jsonDecode(res.body));
      }
      throw Exception('HTTP ${res.statusCode}');
    } catch (_) {
      return _fallback(project, investor);
    }
  }

  // ── تنبؤ: مشروع واحد ↔ عدة مستثمرين ────────────────
  Future<List<MLBulkResult>> predictBulk({
    required Project project,
    required List<Investor> investors,
  }) async {
    if (investors.isEmpty) return [];

    try {
      final res = await _client
          .post(
            Uri.parse('$_base/predict/bulk'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'project_description': project.description,
              'project_title': project.title,
              'project_category': project.industry,
              'project_stage': project.stage,
              'project_tags': project.tags ?? const <String>[],
              'funding_goal': project.fundingGoal,
              'investors': investors
                  .map((inv) => {
                        'id': inv.id,
                        'name': inv.name,
                        'description': _investorDescription(inv),
                        'bio': _investorDescription(inv),
                        'industries': _investorIndustries(inv),
                        'stages': inv.criteria?.stages ?? const <String>[],
                        'min_investment': inv.criteria?.minInvestment,
                        'max_investment': inv.criteria?.maxInvestment,
                      })
                  .toList(),
            }),
          )
          .timeout(_timeout);

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((j) => MLBulkResult.fromJson(j)).toList();
      }
      throw Exception('HTTP ${res.statusCode}');
    } catch (_) {
      return investors.map((inv) {
        final r = _fallback(project, inv);
        return MLBulkResult(
          investorId: inv.id,
          investorName: inv.name,
          decision: r.decision,
          probability: r.probability,
          matchPercentage: r.matchPercentage,
          confidenceLevel: r.confidenceLevel,
          positiveSignals: r.positiveSignals,
          negativeSignals: r.negativeSignals,
        );
      }).toList()
        ..sort((a, b) => b.probability.compareTo(a.probability));
    }
  }

  // ── Fallback محلي إذا السيرفر بطيء ──────────────────
  MLPrediction _fallback(Project project, Investor investor) {
    final c = investor.criteria;
    final industries = _investorIndustries(investor);
    final investorText = _investorDescription(investor).toLowerCase();
    double score = 0;
    final pos = <String>[];
    final neg = <String>[];
    final desc = project.description.toLowerCase();

    const pkw = [
      'revenue',
      'patent',
      'retention',
      'growth',
      'margin',
      'profit',
      'traction'
    ];
    const nkw = ['pre-revenue', 'crowded', 'saturated', 'no patent'];
    for (final k in pkw) {
      if (desc.contains(k)) pos.add(k);
    }
    for (final k in nkw) {
      if (desc.contains(k)) neg.add(k);
    }

    if (c != null) {
      if (industries.contains(project.industry)) score += 0.40;
      if (c.stages.contains(project.stage)) score += 0.30;
      if (c.minInvestment <= project.fundingGoal &&
          project.fundingGoal <= c.maxInvestment) score += 0.20;
    }
    final descriptionScore = _descriptionAlignment(project, investor);
    if (descriptionScore >= 0.35) {
      pos.add('description alignment');
    }
    if (investorText.contains(project.industry.toLowerCase())) {
      pos.add('description mentions ${project.industry}');
    }
    score = (score + pos.length * 0.04 - neg.length * 0.08).clamp(0.0, 1.0);
    if (descriptionScore > 0) {
      score = (score > (score * 0.45 + descriptionScore * 0.55)
              ? score
              : (score * 0.45 + descriptionScore * 0.55))
          .clamp(0.0, 1.0);
    }

    return MLPrediction(
      decision: score >= 0.47 ? 'INVEST' : 'SKIP',
      probability: double.parse(score.toStringAsFixed(4)),
      matchPercentage: double.parse((score * 100).toStringAsFixed(1)),
      confidenceLevel: score >= 0.75 || score <= 0.25 ? 'High' : 'Medium',
      positiveSignals: pos,
      negativeSignals: neg,
      explanation: 'Local calculation (server unavailable)',
    );
  }

  double _descriptionAlignment(Project project, Investor investor) {
    final projectText =
        '${project.title} ${project.description} ${project.industry}'
            .toLowerCase();
    final investorText =
        '${_investorDescription(investor)} ${_investorIndustries(investor).join(' ')}'
            .toLowerCase()
            .trim();

    if (investorText.isEmpty) return 0;

    final projectTokens = _tokens(projectText);
    final investorTokens = _tokens(investorText);
    if (projectTokens.isEmpty || investorTokens.isEmpty) return 0;

    final overlap = projectTokens.intersection(investorTokens).length /
        projectTokens.union(investorTokens).length;
    final categoryMention =
        investorText.contains(project.industry.toLowerCase()) ? 1.0 : 0.0;

    var score = (overlap * 0.8) + (categoryMention * 0.2);
    if (overlap >= 0.75) {
      score = score < 0.70 ? 0.70 : score;
    }
    return score.clamp(0.0, 1.0);
  }

  Set<String> _tokens(String text) {
    return text
        .split(RegExp(r'[^a-z0-9]+'))
        .where((token) => token.length > 2)
        .toSet();
  }

  String _investorDescription(Investor investor) {
    return (investor.criteria?.additionalNotes ?? '').trim();
  }

  List<String> _investorIndustries(Investor investor) {
    final criteriaIndustries =
        investor.criteria?.industries ?? const <String>[];
    if (criteriaIndustries.isNotEmpty) {
      return criteriaIndustries;
    }
    return investor.industries ?? const <String>[];
  }
}

// ══════════════════════════════════════════════════════════
// Models
// ══════════════════════════════════════════════════════════

class MLPrediction {
  final String decision;
  final double probability;
  final double matchPercentage;
  final String confidenceLevel;
  final List<String> positiveSignals;
  final List<String> negativeSignals;
  final String explanation;

  MLPrediction({
    required this.decision,
    required this.probability,
    required this.matchPercentage,
    required this.confidenceLevel,
    required this.positiveSignals,
    required this.negativeSignals,
    required this.explanation,
  });

  factory MLPrediction.fromJson(Map<String, dynamic> j) => MLPrediction(
        decision: j['decision'] as String,
        probability: (j['probability'] as num).toDouble(),
        matchPercentage: (j['match_percentage'] as num).toDouble(),
        confidenceLevel: j['confidence_level'] as String,
        positiveSignals: List<String>.from(j['positive_signals']),
        negativeSignals: List<String>.from(j['negative_signals']),
        explanation: j['explanation'] as String,
      );
}

class MLBulkResult {
  final String investorId;
  final String investorName;
  final String decision;
  final double probability;
  final double matchPercentage;
  final String confidenceLevel;
  final List<String> positiveSignals;
  final List<String> negativeSignals;

  MLBulkResult({
    required this.investorId,
    required this.investorName,
    required this.decision,
    required this.probability,
    required this.matchPercentage,
    required this.confidenceLevel,
    required this.positiveSignals,
    required this.negativeSignals,
  });

  factory MLBulkResult.fromJson(Map<String, dynamic> j) => MLBulkResult(
        investorId: j['investor_id'] as String,
        investorName: j['investor_name'] as String,
        decision: j['decision'] as String,
        probability: (j['probability'] as num).toDouble(),
        matchPercentage: (j['match_percentage'] as num).toDouble(),
        confidenceLevel: j['confidence_level'] as String,
        positiveSignals: List<String>.from(j['positive_signals']),
        negativeSignals: List<String>.from(j['negative_signals']),
      );
}
