// ✅ match_provider.dart — مرتبط بنموذج ML الحقيقي
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase/supabase_service.dart';
import '../core/services/ml_service.dart';
import '../models/match.dart';

class MatchesState {
  final List<Match> matchedInvestors;
  final List<Match> matchedProjects;
  final bool isLoading;
  final String? error;

  const MatchesState({
    this.matchedInvestors = const [],
    this.matchedProjects = const [],
    this.isLoading = false,
    this.error,
  });

  MatchesState copyWith({
    List<Match>? matchedInvestors,
    List<Match>? matchedProjects,
    bool? isLoading,
    String? error,
  }) =>
      MatchesState(
        matchedInvestors: matchedInvestors ?? this.matchedInvestors,
        matchedProjects: matchedProjects ?? this.matchedProjects,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class MatchesNotifier extends StateNotifier<MatchesState> {
  final SupabaseService _supabase;
  final MLService _ml;

  MatchesNotifier(this._supabase, this._ml) : super(const MatchesState());

  // ── مستثمرون مناسبون لرائد الأعمال ──────────────────
  Future<void> fetchMatchedInvestors() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final myProjects = await _supabase.getMyProjects();
      if (myProjects.isEmpty) {
        await _supabase.replaceMatchedInvestors(const []);
        state = state.copyWith(matchedInvestors: [], isLoading: false);
        return;
      }

      final investors = await _supabase.getInvestors(limit: 50);
      if (investors.isEmpty) {
        await _supabase.replaceMatchedInvestors(const []);
        state = state.copyWith(matchedInvestors: [], isLoading: false);
        return;
      }

      // ✅ أرسل وصف المشروع للنموذج
      final project = myProjects.first;
      final results = await _ml.predictBulk(
        project: project,
        investors: investors,
      );

      final matches = results.where((r) => r.decision == 'INVEST').map((r) {
        final investor = investors.firstWhere(
          (inv) => inv.id == r.investorId,
          orElse: () => investors.first,
        );
        return Match(
          id: 'ml_${r.investorId}',
          targetId: r.investorId,
          targetType: 'investor',
          matchPercentage: r.matchPercentage,
          matchingCriteria: [
            '${r.matchPercentage.toStringAsFixed(0)}% match · ${r.confidenceLevel} confidence',
            if (r.positiveSignals.isNotEmpty)
              '🟢 ${r.positiveSignals.take(2).join(', ')}',
            if (r.negativeSignals.isNotEmpty)
              '🔴 ${r.negativeSignals.take(1).join(', ')}',
          ],
          investor: investor,
        );
      }).toList();

      await _supabase.replaceMatchedInvestors(matches);
      final persisted = await _supabase.getMatchedInvestors();
      state = state.copyWith(matchedInvestors: persisted, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── مشاريع مناسبة للمستثمر ───────────────────────────
  Future<void> fetchMatchedProjects() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final uid = _supabase.client.auth.currentUser?.id;
      if (uid == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final allInvestors = await _supabase.getInvestors(limit: 100);
      final myInvestor = allInvestors.where((i) => i.userId == uid).firstOrNull;
      if (myInvestor == null) {
        await _supabase.replaceMatchedProjects(const []);
        state = state.copyWith(matchedProjects: [], isLoading: false);
        return;
      }

      final projects = await _supabase.getProjects(limit: 50);
      final List<Match> matches = [];

      for (final project in projects) {
        final result = await _ml.predict(
          project: project,
          investor: myInvestor,
        );

        if (result.decision == 'INVEST') {
          matches.add(Match(
            id: 'ml_${project.id}',
            targetId: project.id,
            targetType: 'project',
            matchPercentage: result.matchPercentage,
            matchingCriteria: [
              '${result.matchPercentage.toStringAsFixed(0)}% match · ${result.confidenceLevel}',
              if (result.positiveSignals.isNotEmpty)
                '🟢 ${result.positiveSignals.take(3).join(', ')}',
            ],
            project: project,
          ));
        }
      }

      matches.sort((a, b) => b.matchPercentage.compareTo(a.matchPercentage));
      await _supabase.replaceMatchedProjects(matches);
      final persisted = await _supabase.getMatchedProjects();
      state = state.copyWith(matchedProjects: persisted, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final matchesProvider =
    StateNotifierProvider<MatchesNotifier, MatchesState>((ref) {
  return MatchesNotifier(
    ref.watch(supabaseServiceProvider),
    ref.watch(mlServiceProvider),
  );
});
