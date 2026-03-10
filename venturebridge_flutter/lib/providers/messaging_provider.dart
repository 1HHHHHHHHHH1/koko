import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_service.dart';
import '../models/message.dart';

// Messaging State
class MessagingState {
  final List<Conversation> conversations;
  final Map<String, List<Message>> messagesByConversation;
  final String? activeConversationId;
  final bool isLoading;
  final bool isSending;
  final String? error;

  const MessagingState({
    this.conversations = const [],
    this.messagesByConversation = const {},
    this.activeConversationId,
    this.isLoading = false,
    this.isSending = false,
    this.error,
  });

  MessagingState copyWith({
    List<Conversation>? conversations,
    Map<String, List<Message>>? messagesByConversation,
    String? activeConversationId,
    bool? isLoading,
    bool? isSending,
    String? error,
  }) {
    return MessagingState(
      conversations: conversations ?? this.conversations,
      messagesByConversation:
          messagesByConversation ?? this.messagesByConversation,
      activeConversationId: activeConversationId ?? this.activeConversationId,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: error,
    );
  }

  List<Message> getMessages(String conversationId) {
    return messagesByConversation[conversationId] ?? [];
  }

  int get totalUnread =>
      conversations.fold(0, (sum, c) => sum + c.unreadCount);
}

// Messaging Notifier
class MessagingNotifier extends StateNotifier<MessagingState> {
  final ApiService _apiService;

  MessagingNotifier(this._apiService) : super(const MessagingState());

  Future<void> fetchConversations() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final conversations = await _apiService.getConversations();
      state = state.copyWith(
        conversations: conversations,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> fetchMessages(String conversationId) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      activeConversationId: conversationId,
    );

    try {
      final messages = await _apiService.getMessages(conversationId);
      final newMessagesMap =
          Map<String, List<Message>>.from(state.messagesByConversation);
      newMessagesMap[conversationId] = messages;

      state = state.copyWith(
        messagesByConversation: newMessagesMap,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> sendMessage(String conversationId, String content) async {
    if (content.trim().isEmpty) return false;

    state = state.copyWith(isSending: true, error: null);

    try {
      final message = await _apiService.sendMessage(
        conversationId: conversationId,
        content: content,
      );

      // Add message to the conversation
      final newMessagesMap =
          Map<String, List<Message>>.from(state.messagesByConversation);
      final currentMessages = newMessagesMap[conversationId] ?? [];
      newMessagesMap[conversationId] = [...currentMessages, message];

      // Update conversation's last message
      final updatedConversations = state.conversations.map((c) {
        if (c.id == conversationId) {
          return Conversation(
            id: c.id,
            participantIds: c.participantIds,
            otherParticipant: c.otherParticipant,
            lastMessage: message,
            unreadCount: c.unreadCount,
            createdAt: c.createdAt,
            updatedAt: DateTime.now(),
          );
        }
        return c;
      }).toList();

      state = state.copyWith(
        messagesByConversation: newMessagesMap,
        conversations: updatedConversations,
        isSending: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<Conversation?> createOrGetConversation(String recipientId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final conversation = await _apiService.createConversation(recipientId);

      // Add to conversations if not exists
      final exists = state.conversations.any((c) => c.id == conversation.id);
      if (!exists) {
        state = state.copyWith(
          conversations: [conversation, ...state.conversations],
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }

      return conversation;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  void setActiveConversation(String? conversationId) {
    state = state.copyWith(activeConversationId: conversationId);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final messagingProvider =
    StateNotifierProvider<MessagingNotifier, MessagingState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return MessagingNotifier(apiService);
});

// Helper provider for total unread count
final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(messagingProvider).totalUnread;
});
