import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase/supabase_service.dart';
import '../models/rating.dart';

class RatingsState {
  final Map<String, RatingSummary> summaries;
  final bool    isLoading;
  final String? error;
  final bool    isSubmitting;

  const RatingsState({
    this.summaries    = const {},
    this.isLoading    = false,
    this.error,
    this.isSubmitting = false,
  });

  RatingsState copyWith({
    Map<String, RatingSummary>? summaries,
    bool?    isLoading,
    String?  error,
    bool?    isSubmitting,
  }) => RatingsState(
    summaries:    summaries    ?? this.summaries,
    isLoading:    isLoading    ?? this.isLoading,
    error:        error,
    isSubmitting: isSubmitting ?? this.isSubmitting,
  );

  RatingSummary? getSummary(String userId) => summaries[userId];
}

class RatingsNotifier extends StateNotifier<RatingsState> {
  final SupabaseService _service;
  RatingsNotifier(this._service) : super(const RatingsState());

  Future<void> fetchRatingSummary(String targetId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final summary = await _service.getRatingSummary(targetId);
      final newMap  = Map<String, RatingSummary>.from(state.summaries);
      newMap[targetId] = summary;
      state = state.copyWith(summaries: newMap, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> submitRating({
    required String targetId,
    required String targetType,
    required int    score,
    String?         comment,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      await _service.createRating(
          targetId: targetId, targetType: targetType,
          score: score, comment: comment);
      await fetchRatingSummary(targetId);
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final ratingsProvider =
    StateNotifierProvider<RatingsNotifier, RatingsState>((ref) {
  return RatingsNotifier(ref.watch(supabaseServiceProvider));
});

final ratingSummaryProvider =
    Provider.family<RatingSummary?, String>((ref, userId) {
  return ref.watch(ratingsProvider).getSummary(userId);
});
