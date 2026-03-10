import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_service.dart';
import '../models/match.dart';

// Matches State
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
  }) {
    return MatchesState(
      matchedInvestors: matchedInvestors ?? this.matchedInvestors,
      matchedProjects: matchedProjects ?? this.matchedProjects,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Matches Notifier
class MatchesNotifier extends StateNotifier<MatchesState> {
  final ApiService _apiService;

  MatchesNotifier(this._apiService) : super(const MatchesState());

  Future<void> fetchMatchedInvestors() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final matches = await _apiService.getMatchedInvestors();
      state = state.copyWith(
        matchedInvestors: matches,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> fetchMatchedProjects() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final matches = await _apiService.getMatchedProjects();
      state = state.copyWith(
        matchedProjects: matches,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final matchesProvider =
    StateNotifierProvider<MatchesNotifier, MatchesState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return MatchesNotifier(apiService);
});
