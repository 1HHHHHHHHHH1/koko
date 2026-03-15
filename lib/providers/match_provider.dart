// ✅ match_provider.dart — مُحدَّث لـ SupabaseService
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase/supabase_service.dart';
import '../models/match.dart';

class MatchesState {
  final List<Match> matchedInvestors;
  final List<Match> matchedProjects;
  final bool        isLoading;
  final String?     error;

  const MatchesState({
    this.matchedInvestors = const [],
    this.matchedProjects  = const [],
    this.isLoading        = false,
    this.error,
  });

  MatchesState copyWith({
    List<Match>? matchedInvestors,
    List<Match>? matchedProjects,
    bool?        isLoading,
    String?      error,
  }) => MatchesState(
    matchedInvestors: matchedInvestors ?? this.matchedInvestors,
    matchedProjects:  matchedProjects  ?? this.matchedProjects,
    isLoading:        isLoading        ?? this.isLoading,
    error:            error,
  );
}

class MatchesNotifier extends StateNotifier<MatchesState> {
  final SupabaseService _service;
  MatchesNotifier(this._service) : super(const MatchesState());

  Future<void> fetchMatchedInvestors() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final m = await _service.getMatchedInvestors();
      state = state.copyWith(matchedInvestors: m, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchMatchedProjects() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final m = await _service.getMatchedProjects();
      state = state.copyWith(matchedProjects: m, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final matchesProvider =
    StateNotifierProvider<MatchesNotifier, MatchesState>((ref) {
  return MatchesNotifier(ref.watch(supabaseServiceProvider));
});
