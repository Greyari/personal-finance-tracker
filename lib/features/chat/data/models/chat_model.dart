import 'package:cloud_firestore/cloud_firestore.dart';

/// Lightweight participant profile stored inside chat metadata for fast rendering.
class ChatParticipantInfo {
  final String userId;
  final String displayName;
  final String email;
  final String? photoUrl;

  const ChatParticipantInfo({
    required this.userId,
    required this.displayName,
    required this.email,
    this.photoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
    };
  }

  factory ChatParticipantInfo.fromMap(Map<String, dynamic> map) {
    return ChatParticipantInfo(
      userId: map['userId'] as String? ?? '',
      displayName: map['displayName'] as String? ?? 'Pengguna',
      email: map['email'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
    );
  }
}

/// Represents a 1-on-1 chat room between two users.
class ChatRoomModel {
  final String id;
  final List<String> participantIds;
  final Map<String, ChatParticipantInfo> participants;
  final String lastMessage;
  final String lastMessageSenderId;
  final DateTime? lastMessageTime;
  final Map<String, int> unreadCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ChatRoomModel({
    required this.id,
    required this.participantIds,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageSenderId,
    this.lastMessageTime,
    required this.unreadCount,
    this.createdAt,
    this.updatedAt,
  });

  ChatParticipantInfo? getOtherParticipant(String myUid) {
    for (final entry in participants.entries) {
      if (entry.key != myUid) return entry.value;
    }
    // Fallback if not found
    for (final id in participantIds) {
      if (id != myUid && participants.containsKey(id)) {
        return participants[id];
      }
    }
    return null;
  }

  int getUnreadFor(String myUid) => unreadCount[myUid] ?? 0;

  Map<String, dynamic> toMap() {
    return {
      'participantIds': participantIds,
      'participants': participants.map((key, val) => MapEntry(key, val.toMap())),
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageTime': lastMessageTime != null ? Timestamp.fromDate(lastMessageTime!) : FieldValue.serverTimestamp(),
      'unreadCount': unreadCount,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  factory ChatRoomModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawParticipants = data['participants'] as Map<String, dynamic>? ?? {};
    final parsedParticipants = <String, ChatParticipantInfo>{};
    rawParticipants.forEach((key, val) {
      if (val is Map<String, dynamic>) {
        parsedParticipants[key] = ChatParticipantInfo.fromMap(val);
      }
    });

    final rawUnread = data['unreadCount'] as Map<String, dynamic>? ?? {};
    final parsedUnread = <String, int>{};
    rawUnread.forEach((key, val) {
      if (val is num) parsedUnread[key] = val.toInt();
    });

    DateTime? parseTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      return null;
    }

    return ChatRoomModel(
      id: doc.id,
      participantIds: List<String>.from(data['participantIds'] as List? ?? []),
      participants: parsedParticipants,
      lastMessage: data['lastMessage'] as String? ?? '',
      lastMessageSenderId: data['lastMessageSenderId'] as String? ?? '',
      lastMessageTime: parseTimestamp(data['lastMessageTime']),
      unreadCount: parsedUnread,
      createdAt: parseTimestamp(data['createdAt']),
      updatedAt: parseTimestamp(data['updatedAt']),
    );
  }
}

/// Represents an individual message in a chat room.
class ChatMessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String text;
  final String? imageUrl;
  final Map<String, String> reactions;
  final DateTime createdAt;
  final bool isRead;
  final String type;
  final bool isEdited;
  final DateTime? updatedAt;

  const ChatMessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.imageUrl,
    this.reactions = const {},
    required this.createdAt,
    this.isRead = false,
    this.type = 'text',
    this.isEdited = false,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'type': type,
      'isEdited': isEdited,
    };
    if (imageUrl != null) {
      map['imageUrl'] = imageUrl;
    }
    if (reactions.isNotEmpty) {
      map['reactions'] = reactions;
    }
    if (updatedAt != null) {
      map['updatedAt'] = Timestamp.fromDate(updatedAt!);
    }
    return map;
  }

  factory ChatMessageModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      return DateTime.now();
    }

    DateTime? parseOptionalDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      return null;
    }

    Map<String, String> parsedReactions = {};
    if (data['reactions'] is Map) {
      (data['reactions'] as Map).forEach((k, v) {
        if (k != null && v != null) {
          parsedReactions[k.toString()] = v.toString();
        }
      });
    }

    return ChatMessageModel(
      id: doc.id,
      chatId: data['chatId'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? 'Sobat',
      text: data['text'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      reactions: parsedReactions,
      createdAt: parseDate(data['createdAt']),
      isRead: data['isRead'] as bool? ?? false,
      type: data['type'] as String? ?? 'text',
      isEdited: data['isEdited'] as bool? ?? false,
      updatedAt: parseOptionalDate(data['updatedAt']),
    );
  }
}
