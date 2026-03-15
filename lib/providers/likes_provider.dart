// ✅ likes_provider.dart — مُحدَّث لـ SupabaseService
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase/supabase_service.dart';
import '../models/like.dart';

class LikesState {
  final List<Like> likes;
  final Set<String> likedIds;
  final bool        isLoading;
  final String?     error;

  const LikesState({
    this.likes     = const [],
    this.likedIds  = const {},
    this.isLoading = false,
    this.error,
  });

  LikesState copyWith({
    List<Like>? likes,
    Set<String>? likedIds,
    bool?        isLoading,
    String?      error,
  }) => LikesState(
    likes:     likes     ?? this.likes,
    likedIds:  likedIds  ?? this.likedIds,
    isLoading: isLoading ?? this.isLoading,
    error:     error,
  );

  bool  isLiked(String targetId) => likedIds.contains(targetId);
  Like? getLikeByTargetId(String targetId) {
    try { return likes.firstWhere((l) => l.targetId == targetId); }
    catch (_) { return null; }
  }
}

class LikesNotifier extends StateNotifier<LikesState> {
  final SupabaseService _service;
  LikesNotifier(this._service) : super(const LikesState());

  Future<void> fetchMyLikes() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final likes   = await _service.getMyLikes();
      final likedIds = likes.map((l) => l.targetId).toSet();
      state = state.copyWith(likes: likes, likedIds: likedIds, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> toggleLike(String targetId, String targetType) async {
    return state.isLiked(targetId)
        ? await _unlikeItem(targetId)
        : await _likeItem(targetId, targetType);
  }

  Future<bool> _likeItem(String targetId, String targetType) async {
    // optimistic
    state = state.copyWith(likedIds: {...state.likedIds, targetId});
    try {
      final like = await _service.createLike(
          targetId: targetId, targetType: targetType);
      state = state.copyWith(likes: [...state.likes, like]);
      return true;
    } catch (e) {
      state = state.copyWith(
          likedIds: {...state.likedIds}..remove(targetId),
          error: e.toString());
      return false;
    }
  }

  Future<bool> _unlikeItem(String targetId) async {
    final like = state.getLikeByTargetId(targetId);
    if (like == null) return false;
    // optimistic
    state = state.copyWith(
      likedIds: {...state.likedIds}..remove(targetId),
      likes:    state.likes.where((l) => l.targetId != targetId).toList(),
    );
    try {
      await _service.deleteLike(like.id);
      return true;
    } catch (e) {
      state = state.copyWith(
          likedIds: {...state.likedIds, targetId},
          likes:    [...state.likes, like],
          error:    e.toString());
      return false;
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final likesProvider =
    StateNotifierProvider<LikesNotifier, LikesState>((ref) {
  return LikesNotifier(ref.watch(supabaseServiceProvider));
});

final isLikedProvider = Provider.family<bool, String>((ref, targetId) {
  return ref.watch(likesProvider).isLiked(targetId);
});
