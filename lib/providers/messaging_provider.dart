// ✅ messaging_provider.dart — مُكتمل مع Realtime + isSending + getMessages
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase/supabase_service.dart';
import '../models/message.dart';

// ────────────────────────────────────────────────────────────
// State
// ────────────────────────────────────────────────────────────
class MessagingState {
  final List<Conversation>         conversations;
  final Map<String, List<Message>> messagesMap;   // conversationId → messages
  final bool                       isLoading;
  final bool                       isSending;
  final String?                    activeConversationId;
  final String?                    error;

  const MessagingState({
    this.conversations           = const [],
    this.messagesMap             = const {},
    this.isLoading               = false,
    this.isSending               = false,
    this.activeConversationId,
    this.error,
  });

  MessagingState copyWith({
    List<Conversation>?         conversations,
    Map<String, List<Message>>? messagesMap,
    bool?                       isLoading,
    bool?                       isSending,
    String?                     activeConversationId,
    String?                     error,
    bool                        clearActive = false,
  }) => MessagingState(
    conversations:          conversations          ?? this.conversations,
    messagesMap:            messagesMap            ?? this.messagesMap,
    isLoading:              isLoading              ?? this.isLoading,
    isSending:              isSending              ?? this.isSending,
    activeConversationId:   clearActive ? null     : (activeConversationId ?? this.activeConversationId),
    error:                  error,
  );

  /// الرسائل الخاصة بمحادثة معيّنة
  List<Message> getMessages(String conversationId) =>
      messagesMap[conversationId] ?? [];
}

// ────────────────────────────────────────────────────────────
// Notifier
// ────────────────────────────────────────────────────────────
class MessagingNotifier extends StateNotifier<MessagingState> {
  final SupabaseService _service;
  StreamSubscription<List<Message>>? _realtimeSub;

  MessagingNotifier(this._service) : super(const MessagingState());

  // ---- جلب المحادثات ----
  Future<void> fetchConversations() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final convs = await _service.getConversations();
      state = state.copyWith(conversations: convs, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ---- تحديد المحادثة النشطة + الاشتراك في Realtime ----
  Future<void> setActiveConversation(String? conversationId) async {
    await _realtimeSub?.cancel();
    _realtimeSub = null;

    if (conversationId == null) {
      state = state.copyWith(clearActive: true);
      return;
    }

    state = state.copyWith(activeConversationId: conversationId);

    // ✅ Realtime stream
    _realtimeSub = _service
        .messagesStream(conversationId)
        .listen((updatedMessages) {
      final newMap = Map<String, List<Message>>.from(state.messagesMap);
      newMap[conversationId] = updatedMessages;
      state = state.copyWith(messagesMap: newMap);
    });
  }

  // ---- جلب الرسائل (أوّل مرة) ----
  Future<void> fetchMessages(String conversationId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final msgs = await _service.getMessages(conversationId);
      final newMap = Map<String, List<Message>>.from(state.messagesMap);
      newMap[conversationId] = msgs;
      state = state.copyWith(messagesMap: newMap, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ---- إرسال رسالة ----
  Future<void> sendMessage(
    String conversationId,
    String content,
  ) async {
    if (content.trim().isEmpty) return;
    state = state.copyWith(isSending: true, error: null);
    try {
      await _service.sendMessage(
          conversationId: conversationId, content: content);
      state = state.copyWith(isSending: false);
      // الرسالة ستظهر تلقائياً عبر Realtime ↑
    } catch (e) {
      state = state.copyWith(isSending: false, error: e.toString());
    }
  }

  // ---- إنشاء محادثة جديدة ----
  Future<Conversation?> createConversation(String recipientId) async {
    try {
      return await _service.createConversation(recipientId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  void clearError() => state = state.copyWith(error: null);

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }
}

// ────────────────────────────────────────────────────────────
// Provider
// ────────────────────────────────────────────────────────────
final messagingProvider =
    StateNotifierProvider<MessagingNotifier, MessagingState>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  return MessagingNotifier(service);
});
