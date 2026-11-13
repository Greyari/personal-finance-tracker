import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/fcm_service.dart';
import '../../../auth/data/models/app_user_model.dart';
import '../models/chat_model.dart';

class ChatRepository {
  final FirebaseFirestore _firestore;

  ChatRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Keeps the global user directory updated so users can discover each other by email.
  Future<void> syncUserDirectory(AppUserModel user) async {
    final docRef = _firestore.collection(FirestoreCollections.userDirectory).doc(user.userId);
    await docRef.set({
      'userId': user.userId,
      'email': user.email.toLowerCase().trim(),
      'displayName': user.displayName,
      'photoUrl': null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Searches for an existing user by email in the user directory.
  Future<ChatParticipantInfo?> searchUserByEmail(String email) async {
    final cleanEmail = email.toLowerCase().trim();
    final query = await _firestore
        .collection(FirestoreCollections.userDirectory)
        .where('email', isEqualTo: cleanEmail)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return ChatParticipantInfo.fromMap(query.docs.first.data());
  }

  /// Creates or retrieves a 1-on-1 chat room between current user and a partner.
  Future<ChatRoomModel> getOrCreateChatRoom({
    required AppUserModel currentUser,
    required ChatParticipantInfo partner,
  }) async {
    final uids = [currentUser.userId, partner.userId]..sort();
    final chatId = uids.join('_');
    final docRef = _firestore.collection(FirestoreCollections.chats).doc(chatId);

    final snap = await docRef.get();
    if (snap.exists && snap.data() != null) {
      return ChatRoomModel.fromFirestore(snap);
    }

    final now = DateTime.now();
    final newRoom = ChatRoomModel(
      id: chatId,
      participantIds: uids,
      participants: {
        currentUser.userId: ChatParticipantInfo(
          userId: currentUser.userId,
          displayName: currentUser.displayName,
          email: currentUser.email,
          photoUrl: null,
        ),
        partner.userId: partner,
      },
      lastMessage: 'Obrolan baru dimulai 👋',
      lastMessageSenderId: currentUser.userId,
      lastMessageTime: now,
      unreadCount: {currentUser.userId: 0, partner.userId: 0},
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(newRoom.toMap());
    return newRoom;
  }

  /// Stream of all chats where the user is a participant (sorted newest first in memory).
  Stream<List<ChatRoomModel>> watchUserChats(String userId) {
    return _firestore
        .collection(FirestoreCollections.chats)
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => ChatRoomModel.fromFirestore(d)).toList();
      list.sort((a, b) {
        final tA = a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tB = b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tB.compareTo(tA);
      });
      return list;
    });
  }

  /// Real-time stream of messages in a given chat room (ordered newest first).
  Stream<List<ChatMessageModel>> watchMessages(String chatId) {
    return _firestore
        .collection(FirestoreCollections.chats)
        .doc(chatId)
        .collection(FirestoreCollections.messages)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ChatMessageModel.fromFirestore(d)).toList());
  }

  /// Sends a message and updates the parent chat metadata atomically.
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String partnerId,
    required String text,
  }) async {
    final chatRef = _firestore.collection(FirestoreCollections.chats).doc(chatId);
    final messagesRef = chatRef.collection(FirestoreCollections.messages);

    final batch = _firestore.batch();
    final newMsgRef = messagesRef.doc();
    batch.set(newMsgRef, {
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
      'type': 'text',
    });

    batch.update(chatRef, {
      'lastMessage': text.trim(),
      'lastMessageSenderId': senderId,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'unreadCount.$partnerId': FieldValue.increment(1),
    });

    await batch.commit();

    // Trigger FCM Push to partner asynchronously
    _sendPartnerPushNotification(
      partnerId: partnerId,
      senderName: senderName,
      messageText: text.trim(),
      chatId: chatId,
      senderId: senderId,
    );
  }

  /// Sends a photo message and updates parent chat metadata atomically.
  Future<void> sendImageMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String partnerId,
    required String base64Image,
    String caption = '',
  }) async {
    final chatRef = _firestore.collection(FirestoreCollections.chats).doc(chatId);
    final messagesRef = chatRef.collection(FirestoreCollections.messages);

    final cleanCaption = caption.trim();
    final displayText = cleanCaption.isNotEmpty ? cleanCaption : '📷 Foto';

    final batch = _firestore.batch();
    final newMsgRef = messagesRef.doc();
    batch.set(newMsgRef, {
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'text': displayText,
      'imageUrl': base64Image,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
      'type': 'image',
    });

    batch.update(chatRef, {
      'lastMessage': cleanCaption.isNotEmpty ? '📷 $cleanCaption' : '📷 Foto',
      'lastMessageSenderId': senderId,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'unreadCount.$partnerId': FieldValue.increment(1),
    });

    await batch.commit();

    // Trigger FCM Push to partner asynchronously
    _sendPartnerPushNotification(
      partnerId: partnerId,
      senderName: senderName,
      messageText: cleanCaption.isNotEmpty ? '📷 $cleanCaption' : '📷 Mengirim foto',
      chatId: chatId,
      senderId: senderId,
    );
  }

  /// Sends FCM push notification to partner device token if available.
  Future<void> _sendPartnerPushNotification({
    required String partnerId,
    required String senderName,
    required String messageText,
    required String chatId,
    required String senderId,
  }) async {
    try {
      final doc = await _firestore.collection(FirestoreCollections.userDirectory).doc(partnerId).get();
      if (!doc.exists || doc.data() == null) return;
      final fcmToken = doc.data()?['fcmToken'] as String?;
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await FcmService().sendPushNotification(
          targetFcmToken: fcmToken,
          senderName: senderName,
          messageText: messageText,
          chatId: chatId,
          senderId: senderId,
        );
      }
    } catch (_) {
      // Ignore background push error
    }
  }

  /// Adds, switches, or removes a reaction emoji on a message (WhatsApp style).
  Future<void> toggleReaction({
    required String chatId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    try {
      final msgRef = _firestore
          .collection(FirestoreCollections.chats)
          .doc(chatId)
          .collection(FirestoreCollections.messages)
          .doc(messageId);

      final snap = await msgRef.get();
      if (!snap.exists || snap.data() == null) return;

      final currentReactions = Map<String, dynamic>.from(snap.data()!['reactions'] ?? {});
      if (currentReactions[userId] == emoji) {
        currentReactions.remove(userId);
      } else {
        currentReactions[userId] = emoji;
      }
      await msgRef.update({'reactions': currentReactions});
    } catch (_) {
      // Ignore if network dropped
    }
  }

  /// Resets unread counter for current user in the chat room and marks messages as read.
  Future<void> markAsRead({required String chatId, required String userId}) async {
    try {
      final chatRef = _firestore.collection(FirestoreCollections.chats).doc(chatId);
      final messagesRef = chatRef.collection(FirestoreCollections.messages);

      final batch = _firestore.batch();
      batch.update(chatRef, {
        'unreadCount.$userId': 0,
      });

      // Find partner messages that are unread
      final unreadSnap = await messagesRef
          .where('isRead', isEqualTo: false)
          .limit(50)
          .get();

      for (final doc in unreadSnap.docs) {
        if (doc.data()['senderId'] != userId) {
          batch.update(doc.reference, {
            'isRead': true,
            'isDelivered': true,
          });
        }
      }

      await batch.commit();
    } catch (_) {
      // Ignore if document not yet created or permission denied
    }
  }

  /// Automatically marks incoming messages as delivered when received by partner's device.
  Future<void> markMessagesAsDelivered({required String chatId, required String userId}) async {
    try {
      final messagesRef = _firestore
          .collection(FirestoreCollections.chats)
          .doc(chatId)
          .collection(FirestoreCollections.messages);

      final undeliveredSnap = await messagesRef
          .where('isDelivered', isEqualTo: false)
          .limit(30)
          .get();

      if (undeliveredSnap.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in undeliveredSnap.docs) {
        if (doc.data()['senderId'] != userId) {
          batch.update(doc.reference, {
            'isDelivered': true,
          });
        }
      }
      await batch.commit();
    } catch (_) {
      // Ignore background delivery acknowledge error
    }
  }

  /// Edits an existing message sent by current user.
  Future<void> editMessage({
    required String chatId,
    required String messageId,
    required String newText,
  }) async {
    final cleanText = newText.trim();
    if (cleanText.isEmpty) return;

    final chatRef = _firestore.collection(FirestoreCollections.chats).doc(chatId);
    final msgRef = chatRef.collection(FirestoreCollections.messages).doc(messageId);

    final batch = _firestore.batch();
    batch.update(msgRef, {
      'text': cleanText,
      'isEdited': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.update(chatRef, {
      'lastMessage': cleanText,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Deletes a message permanently.
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  }) async {
    await deleteMultipleMessages(chatId: chatId, messageIds: [messageId]);
  }

  /// Deletes multiple messages at once using a Firestore batch write.
  Future<void> deleteMultipleMessages({
    required String chatId,
    required List<String> messageIds,
  }) async {
    if (messageIds.isEmpty) return;
    final chatRef = _firestore.collection(FirestoreCollections.chats).doc(chatId);
    final messagesRef = chatRef.collection(FirestoreCollections.messages);

    final batch = _firestore.batch();
    for (final id in messageIds) {
      batch.delete(messagesRef.doc(id));
    }
    await batch.commit();

    try {
      final remaining = await messagesRef.orderBy('createdAt', descending: true).limit(1).get();
      if (remaining.docs.isNotEmpty) {
        final latest = ChatMessageModel.fromFirestore(remaining.docs.first);
        await chatRef.update({
          'lastMessage': latest.text.isNotEmpty ? latest.text : '📷 Foto',
          'lastMessageSenderId': latest.senderId,
          'lastMessageTime': Timestamp.fromDate(latest.createdAt),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await chatRef.update({
          'lastMessage': 'Obrolan dibersihkan 👋',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {
      // Ignore if metadata update encounters error
    }
  }

  /// Clears all messages in a chat room while retaining the room connection.
  Future<void> clearChatRoom({required String chatId}) async {
    final chatRef = _firestore.collection(FirestoreCollections.chats).doc(chatId);
    final messagesRef = chatRef.collection(FirestoreCollections.messages);
    final snap = await messagesRef.limit(500).get();

    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    batch.update(chatRef, {
      'lastMessage': 'Obrolan dibersihkan 👋',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  /// Deletes an entire chat room and its messages completely.
  Future<void> deleteChatRoom({required String chatId}) async {
    final chatRef = _firestore.collection(FirestoreCollections.chats).doc(chatId);
    final messagesRef = chatRef.collection(FirestoreCollections.messages);
    final snap = await messagesRef.limit(500).get();

    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(chatRef);
    await batch.commit();
  }
}
