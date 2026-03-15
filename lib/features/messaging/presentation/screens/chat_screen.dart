// ✅ chat_screen.dart — متوافق مع messaging_provider الجديد + Realtime
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../providers/messaging_provider.dart';
import '../../../../providers/auth_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  const ChatScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController  = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ✅ جلب الرسائل ثم تشغيل Realtime
      ref.read(messagingProvider.notifier).fetchMessages(widget.conversationId);
      ref.read(messagingProvider.notifier).setActiveConversation(widget.conversationId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    // ✅ إيقاف Realtime عند مغادرة الشاشة
    ref.read(messagingProvider.notifier).setActiveConversation(null);
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    _messageController.clear();

    await ref.read(messagingProvider.notifier)
        .sendMessage(widget.conversationId, content);

    // انتقل إلى آخر رسالة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme         = Theme.of(context);
    final msgState      = ref.watch(messagingProvider);
    final currentUser   = ref.watch(currentUserProvider);
    // ✅ استخدام getMessages من الـ state
    final messages      = msgState.getMessages(widget.conversationId);

    final conversation  = msgState.conversations.where(
        (c) => c.id == widget.conversationId).firstOrNull;
    final otherUser     = conversation?.otherParticipant;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              backgroundImage: otherUser?.avatar != null
                  ? NetworkImage(otherUser!.avatar!) : null,
              child: otherUser?.avatar == null
                  ? Text(
                      otherUser?.name.isNotEmpty == true
                          ? otherUser!.name[0].toUpperCase() : '?',
                      style: TextStyle(fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(otherUser?.name ?? 'Loading...',
                      style: theme.textTheme.titleMedium),
                  Text(
                    otherUser?.userType == 'investor'
                        ? 'Investor' : 'Entrepreneur',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: msgState.isLoading && messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? Center(
                        child: Text(
                          'No messages yet.\nSend the first message!',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[500]),
                        ))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg    = messages[index];
                          final isMe   = msg.senderId == currentUser?.id;
                          final showDate = index == 0 ||
                              !_isSameDay(messages[index - 1].createdAt,
                                  msg.createdAt);
                          return Column(
                            children: [
                              if (showDate)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                  child: Text(
                                    _formatDate(msg.createdAt),
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(color: Colors.grey[500]),
                                  ),
                                ),
                              _MessageBubble(
                                message: msg.content,
                                time: DateFormat('HH:mm')
                                    .format(msg.createdAt),
                                isMe:   isMe,
                                isRead: msg.isRead,
                              ),
                            ],
                          );
                        },
                      ),
          ),

          // Input
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2))
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 4, minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.primary,
                    child: IconButton(
                      // ✅ استخدام isSending من الـ state الجديد
                      icon: msgState.isSending
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(Colors.white)))
                          : const Icon(Icons.send, color: Colors.white),
                      onPressed: msgState.isSending ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool   _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return 'Today';
    if (_isSameDay(date, now.subtract(const Duration(days: 1))))
      return 'Yesterday';
    return DateFormat('MMMM d, yyyy').format(date);
  }
}

// ────────────────────────────────────────────────────────────
// Bubble widget (لا تغيير)
// ────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final String message;
  final String time;
  final bool   isMe;
  final bool   isRead;

  const _MessageBubble({
    required this.message,
    required this.time,
    required this.isMe,
    this.isRead = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
            bottom: 8,
            left: isMe ? 64 : 0,
            right: isMe ? 0 : 64),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? theme.colorScheme.primary : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(16),
            topRight:    const Radius.circular(16),
            bottomLeft:  Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(message,
                style: TextStyle(color: isMe ? Colors.white : Colors.black87)),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(time,
                    style: TextStyle(
                        fontSize: 11,
                        color: isMe
                            ? Colors.white.withOpacity(0.7)
                            : Colors.grey[500])),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(isRead ? Icons.done_all : Icons.done,
                      size: 14,
                      color: isRead
                          ? Colors.lightBlue[200]
                          : Colors.white.withOpacity(0.7)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
