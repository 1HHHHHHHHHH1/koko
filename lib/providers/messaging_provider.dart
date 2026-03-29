import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase/supabase_service.dart';
import '../models/message.dart';

class MessagingState {
  final List<Conversation> conversations;
  final Map<String, List<Message>> messagesMap;
  final bool isLoading;
  final bool isSending;
  final String? activeConversationId;
  final String? error;

  const MessagingState({
    this.conversations = const [],
    this.messagesMap = const {},
    this.isLoading = false,
    this.isSending = false,
    this.activeConversationId,
    this.error,
  });

  MessagingState copyWith({
    List<Conversation>? conversations,
    Map<String, List<Message>>? messagesMap,
    bool? isLoading,
    bool? isSending,
    String? activeConversationId,
    String? error,
    bool clearActive = false,
  }) =>
      MessagingState(
        conversations: conversations ?? this.conversations,
        messagesMap: messagesMap ?? this.messagesMap,
        isLoading: isLoading ?? this.isLoading,
        isSending: isSending ?? this.isSending,
        activeConversationId: clearActive
            ? null
            : (activeConversationId ?? this.activeConversationId),
        error: error,
      );

  List<Message> getMessages(String conversationId) =>
      messagesMap[conversationId] ?? [];
}

class MessagingNotifier extends StateNotifier<MessagingState> {
  final SupabaseService _service;
  StreamSubscription<List<Message>>? _realtimeSub;
  final Set<String> _hiddenConversationIds = <String>{};
  String? _hiddenConversationOwnerId;

  MessagingNotifier(this._service) : super(const MessagingState());

  void _syncHiddenConversationOwner() {
    final currentUserId = _service.client.auth.currentUser?.id;
    if (_hiddenConversationOwnerId == currentUserId) return;
    _hiddenConversationOwnerId = currentUserId;
    _hiddenConversationIds.clear();
  }

  List<Conversation> _visibleConversations(List<Conversation> conversations) {
    _syncHiddenConversationOwner();
    if (_hiddenConversationIds.isEmpty) return conversations;
    return conversations
        .where((conversation) => !_hiddenConversationIds.contains(conversation.id))
        .toList();
  }

  void _hideConversationLocally(String conversationId) {
    _syncHiddenConversationOwner();
    _hiddenConversationIds.add(conversationId);
  }

  void _unhideConversationLocally(String conversationId) {
    _syncHiddenConversationOwner();
    _hiddenConversationIds.remove(conversationId);
  }

  Future<void> fetchConversations() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final conversations =
          _visibleConversations(await _service.getConversations());
      state = state.copyWith(conversations: conversations, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _refreshConversationsSilently() async {
    try {
      final conversations =
          _visibleConversations(await _service.getConversations());
      state = state.copyWith(conversations: conversations);
    } catch (_) {
      // Keep the current state when a background refresh fails.
    }
  }

  Future<void> setActiveConversation(String? conversationId) async {
    await _realtimeSub?.cancel();
    _realtimeSub = null;

    if (conversationId == null) {
      state = state.copyWith(clearActive: true);
      return;
    }

    state = state.copyWith(activeConversationId: conversationId);

    _realtimeSub =
        _service.messagesStream(conversationId).listen((updatedMessages) {
      final newMap = Map<String, List<Message>>.from(state.messagesMap);
      newMap[conversationId] = _sortMessages(updatedMessages);
      state = state.copyWith(messagesMap: newMap);

      final currentUserId = _service.client.auth.currentUser?.id;
      final hasUnreadIncoming = updatedMessages.any(
        (message) => message.senderId != currentUserId && !message.isRead,
      );
      if (hasUnreadIncoming) {
        unawaited(markConversationAsRead(conversationId));
      }
    });
  }

  Future<void> fetchMessages(String conversationId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final messages = _sortMessages(await _service.getMessages(conversationId));
      final newMap = Map<String, List<Message>>.from(state.messagesMap);
      newMap[conversationId] = messages;
      state = state.copyWith(messagesMap: newMap, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markConversationAsRead(String conversationId) async {
    try {
      await _service.markConversationMessagesAsRead(conversationId);

      final currentUserId = _service.client.auth.currentUser?.id;
      final updatedMessagesMap =
          Map<String, List<Message>>.from(state.messagesMap);
      final existingMessages = updatedMessagesMap[conversationId];
      if (existingMessages != null) {
        updatedMessagesMap[conversationId] = existingMessages
            .map(
              (message) => message.senderId == currentUserId
                  ? message
                  : message.copyWith(isRead: true),
            )
            .toList();
      }

      final updatedConversations = state.conversations
          .map(
            (conversation) => conversation.id == conversationId
                ? Conversation(
                    id: conversation.id,
                    participantIds: conversation.participantIds,
                    otherParticipant: conversation.otherParticipant,
                    lastMessage: conversation.lastMessage,
                    unreadCount: 0,
                    createdAt: conversation.createdAt,
                    updatedAt: conversation.updatedAt,
                  )
                : conversation,
          )
          .toList();

      state = state.copyWith(
        messagesMap: updatedMessagesMap,
        conversations: updatedConversations,
      );

      await _refreshConversationsSilently();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> sendMessage(String conversationId, String content) async {
    if (content.trim().isEmpty) return;
    state = state.copyWith(isSending: true, error: null);
    try {
      await _service.sendMessage(
        conversationId: conversationId,
        content: content,
      );
      await _refreshConversationsSilently();
      state = state.copyWith(isSending: false);
    } catch (e) {
      state = state.copyWith(isSending: false, error: e.toString());
    }
  }

  Future<String?> createConversation(String recipientId) async {
    try {
      final conversationId = await _service.getOrCreateConversation(recipientId);
      _unhideConversationLocally(conversationId);
      unawaited(_refreshConversationsSilently());
      return conversationId;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<String> getOrCreateConversation(String recipientId) async {
    try {
      for (final conversation in state.conversations) {
        if (conversation.otherParticipant?.id == recipientId) {
          return conversation.id;
        }
      }

      final conversationId = await _service.getOrCreateConversation(recipientId);
      _unhideConversationLocally(conversationId);
      unawaited(_refreshConversationsSilently());
      return conversationId;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      if (state.activeConversationId == conversationId) {
        await setActiveConversation(null);
      }

      _hideConversationLocally(conversationId);
      final updatedMessagesMap = Map<String, List<Message>>.from(state.messagesMap)
        ..remove(conversationId);
      final updatedConversations = state.conversations
          .where((conversation) => conversation.id != conversationId)
          .toList();

      state = state.copyWith(
        messagesMap: updatedMessagesMap,
        conversations: updatedConversations,
      );

      try {
        await _service.deleteConversationForCurrentUser(conversationId);
      } catch (_) {
        // Keep the conversation hidden locally even if the server keeps it.
      }
      await _refreshConversationsSilently();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() => state = state.copyWith(error: null);

  List<Message> _sortMessages(List<Message> messages) {
    final sorted = [...messages];
    sorted.sort((a, b) {
      final dateComparison = a.createdAt.compareTo(b.createdAt);
      if (dateComparison != 0) return dateComparison;
      return a.id.compareTo(b.id);
    });
    return sorted;
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }
}

final messagingProvider =
    StateNotifierProvider<MessagingNotifier, MessagingState>((ref) {
  final service = ref.read(supabaseServiceProvider);
  return MessagingNotifier(service);
});
