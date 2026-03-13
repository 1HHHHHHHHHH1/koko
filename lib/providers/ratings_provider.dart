import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_service.dart';
import '../models/rating.dart';

// Ratings State
class RatingsState {
  final Map<String, RatingSummary> summaries;
  final bool isLoading;
  final String? error;
  final bool isSubmitting;

  const RatingsState({
    this.summaries = const {},
    this.isLoading = false,
    this.error,
    this.isSubmitting = false,
  });

  RatingsState copyWith({
    Map<String, RatingSummary>? summaries,
    bool? isLoading,
    String? error,
    bool? isSubmitting,
  }) {
    return RatingsState(
      summaries: summaries ?? this.summaries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  RatingSummary? getSummary(String userId) => summaries[userId];
}

// Ratings Notifier
class RatingsNotifier extends StateNotifier<RatingsState> {
  final ApiService _apiService;

  RatingsNotifier(this._apiService) : super(const RatingsState());

  Future<void> fetchRatingSummary(String userId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final summary = await _apiService.getRatingSummary(userId);
      final newSummaries = Map<String, RatingSummary>.from(state.summaries);
      newSummaries[userId] = summary;
      
      state = state.copyWith(
        summaries: newSummaries,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> submitRating({
    required String targetId,
    required String targetType,
    required int score,
    String? comment,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null);

    try {
      await _apiService.createRating(
        targetId: targetId,
        targetType: targetType,
        score: score,
        comment: comment,
      );

      // Refresh the summary after rating
      await fetchRatingSummary(targetId);

      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: e.toString(),
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final ratingsProvider =
    StateNotifierProvider<RatingsNotifier, RatingsState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return RatingsNotifier(apiService);
});

// Helper provider to get rating summary for specific user
final ratingSummaryProvider =
    Provider.family<RatingSummary?, String>((ref, userId) {
  return ref.watch(ratingsProvider).getSummary(userId);
});
