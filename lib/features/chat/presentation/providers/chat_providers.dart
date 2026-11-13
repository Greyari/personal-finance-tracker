import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/notification_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/models/chat_model.dart';
import '../../data/repositories/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

/// Automatically keeps the user's public directory document up to date
/// so other users can search them by email.
final userDirectorySyncProvider = FutureProvider<void>((ref) async {
  try {
    final userProfile = ref.watch(userProfileProvider).value;
    if (userProfile != null) {
      await ref.read(chatRepositoryProvider).syncUserDirectory(userProfile);
    }
  } catch (_) {}
});

/// Stream of all chat rooms for the currently logged-in user.
final userChatsStreamProvider = StreamProvider<List<ChatRoomModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  // Trigger directory sync quietly
  ref.watch(userDirectorySyncProvider);
  try {
    return ref.watch(chatRepositoryProvider).watchUserChats(user.uid);
  } catch (_) {
    return Stream.value([]);
  }
});

/// Tracks the last notified message identifier to avoid duplicate alerts.
String? _lastNotifiedMessageSignature;

/// Watches chat updates and triggers instant WhatsApp-like notification when partner sends a message.
final chatNotificationWatcherProvider = Provider<void>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return;

  ref.listen<AsyncValue<List<ChatRoomModel>>>(userChatsStreamProvider, (prev, next) {
    final chats = next.valueOrNull;
    if (chats == null) return;

    for (final chat in chats) {
      final unread = chat.getUnreadFor(user.uid);
      if (unread > 0 && chat.lastMessageSenderId.isNotEmpty && chat.lastMessageSenderId != user.uid) {
        final sig = '${chat.id}_${chat.lastMessageTime?.millisecondsSinceEpoch}_${chat.lastMessage}';
        if (_lastNotifiedMessageSignature != sig) {
          _lastNotifiedMessageSignature = sig;
          final partner = chat.getOtherParticipant(user.uid);
          final senderName = partner?.displayName ?? 'Pasangan';
          NotificationService().showChatNotification(
            id: chat.id.hashCode,
            senderName: senderName,
            messageText: chat.lastMessage,
            chatId: chat.id,
          );
        }
      }
    }
  });
});

/// Calculates the total number of unread chat messages across all rooms for current user.
final totalUnreadChatCountProvider = Provider<int>((ref) {
  try {
    final user = ref.watch(currentUserProvider);
    if (user == null) return 0;
    final chats = ref.watch(userChatsStreamProvider).valueOrNull ?? [];
    int sum = 0;
    for (final chat in chats) {
      sum += chat.getUnreadFor(user.uid);
    }
    return sum;
  } catch (_) {
    return 0;
  }
});

/// Stream of messages for a specific chat room.
final chatMessagesStreamProvider = StreamProvider.family<List<ChatMessageModel>, String>((ref, chatId) {
  return ref.watch(chatRepositoryProvider).watchMessages(chatId);
});
