import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_service.dart';
import '../models/like.dart';

// Likes State
class LikesState {
  final List<Like> likes;
  final Set<String> likedIds; // Quick lookup for liked items
  final bool isLoading;
  final String? error;

  const LikesState({
    this.likes = const [],
    this.likedIds = const {},
    this.isLoading = false,
    this.error,
  });

  LikesState copyWith({
    List<Like>? likes,
    Set<String>? likedIds,
    bool? isLoading,
    String? error,
  }) {
    return LikesState(
      likes: likes ?? this.likes,
      likedIds: likedIds ?? this.likedIds,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool isLiked(String targetId) => likedIds.contains(targetId);

  Like? getLikeByTargetId(String targetId) {
    try {
      return likes.firstWhere((like) => like.targetId == targetId);
    } catch (_) {
      return null;
    }
  }
}

// Likes Notifier
class LikesNotifier extends StateNotifier<LikesState> {
  final ApiService _apiService;

  LikesNotifier(this._apiService) : super(const LikesState());

  Future<void> fetchMyLikes() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final likes = await _apiService.getMyLikes();
      final likedIds = likes.map((like) => like.targetId).toSet();
      
      state = state.copyWith(
        likes: likes,
        likedIds: likedIds,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> toggleLike(String targetId, String targetType) async {
    final isCurrentlyLiked = state.isLiked(targetId);

    if (isCurrentlyLiked) {
      return await _unlikeItem(targetId);
    } else {
      return await _likeItem(targetId, targetType);
    }
  }

  Future<bool> _likeItem(String targetId, String targetType) async {
    // Optimistic update
    final newLikedIds = {...state.likedIds, targetId};
    state = state.copyWith(likedIds: newLikedIds);

    try {
      final like = await _apiService.createLike(
        targetId: targetId,
        targetType: targetType,
      );
      
      state = state.copyWith(
        likes: [...state.likes, like],
      );
      return true;
    } catch (e) {
      // Revert on error
      final revertedIds = {...state.likedIds}..remove(targetId);
      state = state.copyWith(
        likedIds: revertedIds,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> _unlikeItem(String targetId) async {
    final like = state.getLikeByTargetId(targetId);
    if (like == null) return false;

    // Optimistic update
    final newLikedIds = {...state.likedIds}..remove(targetId);
    final newLikes = state.likes.where((l) => l.targetId != targetId).toList();
    state = state.copyWith(likedIds: newLikedIds, likes: newLikes);

    try {
      await _apiService.deleteLike(like.id);
      return true;
    } catch (e) {
      // Revert on error
      final revertedIds = {...state.likedIds, targetId};
      final revertedLikes = [...state.likes, like];
      state = state.copyWith(
        likedIds: revertedIds,
        likes: revertedLikes,
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
final likesProvider =
    StateNotifierProvider<LikesNotifier, LikesState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return LikesNotifier(apiService);
});

// Helper provider to check if specific item is liked
final isLikedProvider = Provider.family<bool, String>((ref, targetId) {
  return ref.watch(likesProvider).isLiked(targetId);
});
