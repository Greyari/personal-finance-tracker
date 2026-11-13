import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handles notifications received when app is backgrounded or killed
  try {
    await NotificationService().init();
    final senderName =
        message.data['senderName'] ?? message.notification?.title ?? 'Pesan Obrolan';
    final messageText =
        message.data['text'] ?? message.notification?.body ?? 'Pesan baru masuk';
    final chatId = message.data['chatId'];

    await NotificationService().showChatNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      senderName: senderName,
      messageText: messageText,
      chatId: chatId,
    );
  } catch (e) {
    debugPrint('[FCM] Background handler error: $e');
  }
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _projectId = 'personal-finance-tracker-18573';
  static const String _clientEmail =
      'firebase-adminsdk-fbsvc@personal-finance-tracker-18573.iam.gserviceaccount.com';

  static const String _privateKeyPem = '''-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDNm/rHiG0p96D9
2X8uTvtEXQWJ9xBVSG/ZCgekq1WqKNyn4llJwdeRQYE0+jOqvaMrCOuYggf4O1Zm
i0R2vbONCy5iNHjVLPXYf2d3FG8KH3+fMRva/5VrCpT1pvHWF/spcTbOqM0HbULc
TL/20vc9XVG8de+alE1Hcqz0BmXSH+IwQ3tj4vc+YefSdx1RAFO+hSqhjUV3AqTZ
bGlVteC51dyYsZXefML3XT9DAY9KK1yzC/VV5DI5lMriE/P3GjcC4YpmA51EQH3i
ba4//jKfZ/WVf+/CfwxdNmp9VE7356kFxA++Sdk1OZsCCF1cgFUPyjRqLCv0Ta6V
+T5/354lAgMBAAECggEALtvVk5PsDRx6fGANNCib60Cn+oFsH4OaugQnKchChb06
TKixYLXkwx4CrGg5TjhZ73zg9Kjt2Azt7ADhYY5qVUKvF4KN50eP3/9pPSJTDCOR
ml4+0vJcw0BuIm4hv4FHpHJA42hlEcQ88KgtN7tszXdvIVxfdwNFeXsRH6w1mGVy
s1p1OKrfFy6bHMPDfWqZbWuOgBlQVySnmVNXhdMg42nvV9e7JUuEr2E7gOHqH6Ge
W4q3Ls8JZJViAbi/lhFM+vZIH/nsYi5dUJpTHjMPr9dLDoBr20XaT9GnNqp3L++f
n5fTviom3WYhIpS5q6xEeNfo8jSVEjc+XUyIvceHAQKBgQD90o+LJ/JxmxeoRPeC
VICEYI5MPHe7goqym38Vd8AuKQPH69kIhRokrATokR9GMzuYqJxdvYPjA15WUqqV
nHIvAPGX3h4Rg7TcRFpzkMU7Jw2PixSSf7Uv4KVVCSsd/XTFDZBVUiZ63dexq0XQ
+14gXPZ//XmjNN5yGnmoHmwxzQKBgQDPX4i8fKhm410hmmgnYBR3VjNFTt/H7LRM
xk83MHWmqVEBT58MXyrG+ANGnaJ5VCoTWAbJeu0gZHFNokllx2BEIST1k8p1d/Z0
hfLONwA8ZBO7o+6u641L3dpSVC78se79fKr2yfaU7BH/IOi7RF/E/yB13MP16iQ4
+gJLeXEluQKBgGbplKHLVJWTWIg1TlVdha4mqAtpCPLR/wJj4acGorkUkB/jFGBL
90mfJW5WSOPhqew/kQbA7FSC7SD664c1o2ZDb7EvselQCWi1nib1L8LIFst4jKLJ
fOEoqGBOE1lZhprO4RJ2+Hsgr2+uDeSpxoRArQE/+K2fpgGFkoYDr8KRAoGAOie1
hf6Dj48VkBXoPZqhQrJG4Jn1AfEswxceIgESDXIQSIjWtrZ9nZzx9jzA0ru6rQAT
ry8tDtd8OuRXJxbZtWGCJuiSb4z77cOeyxv7kfQS4J1hk2Z1kqAd2NbI8o7H0gjD
PUB4SV1G0sCc49+R6AIQTV1jCzTlgaEDQb1F8OkCgYEA0rZEf/YT21HLLxmHAAqR
xurmj2/F0o7DuOUhSwBDw4lCZpeNma9gYEPsYmpXi3Xad/a93bCL15Dvp8yx8b/Z
v1lKi7cUtGm9WbQJrj49KUt1g1KA5CZEErxee1HFa1KDSvrbIC/Ea47TycZmhWcY
nm9oAKyMiu6NznDeeWPnHx0=
-----END PRIVATE KEY-----''';

  String? _cachedAccessToken;
  DateTime? _tokenExpiry;

  /// Initializes FCM listeners and requests permission.
  Future<void> init() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM] Foreground message received: ${message.messageId}');
        final senderName =
            message.data['senderName'] ?? message.notification?.title ?? 'Pesan Obrolan';
        final messageText =
            message.data['text'] ?? message.notification?.body ?? 'Pesan baru masuk';
        final chatId = message.data['chatId'];

        NotificationService().showChatNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          senderName: senderName,
          messageText: messageText,
          chatId: chatId,
        );
      });
    } catch (e) {
      debugPrint('[FCM] Initialization error: $e');
    }
  }

  /// Saves or updates the device FCM token for the given user in Firestore.
  Future<void> saveUserFcmToken(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;

      debugPrint('[FCM] Device token acquired');

      await _firestore.collection(FirestoreCollections.userDirectory).doc(userId).set({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Listen for token updates
      _messaging.onTokenRefresh.listen((newToken) async {
        debugPrint('[FCM] Token refreshed');
        await _firestore.collection(FirestoreCollections.userDirectory).doc(userId).set({
          'fcmToken': newToken,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    } catch (e) {
      debugPrint('[FCM] Error saving token: $e');
    }
  }

  /// Retrieves an OAuth2 access token for Google FCM v1 using RS256 JWT.
  Future<String?> _getAccessToken() async {
    if (_cachedAccessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _cachedAccessToken;
    }

    try {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final jwt = JWT(
        {
          'iss': _clientEmail,
          'scope': 'https://www.googleapis.com/auth/firebase.messaging',
          'aud': 'https://oauth2.googleapis.com/token',
          'exp': now + 3600,
          'iat': now,
        },
      );

      final signedJwt = jwt.sign(
        RSAPrivateKey(_privateKeyPem),
        algorithm: JWTAlgorithm.RS256,
      );

      final client = HttpClient();
      final req = await client.postUrl(Uri.parse('https://oauth2.googleapis.com/token'));
      req.headers.contentType =
          ContentType.parse('application/x-www-form-urlencoded');

      final body =
          'grant_type=${Uri.encodeQueryComponent('urn:ietf:params:oauth:grant-type:jwt-bearer')}&assertion=${Uri.encodeQueryComponent(signedJwt)}';
      req.write(body);

      final res = await req.close();
      final resBody = await res.transform(utf8.decoder).join();
      client.close();

      if (res.statusCode == 200) {
        final data = jsonDecode(resBody) as Map<String, dynamic>;
        _cachedAccessToken = data['access_token'] as String?;
        _tokenExpiry = DateTime.now().add(const Duration(minutes: 50));
        return _cachedAccessToken;
      } else {
        debugPrint('[FCM] OAuth error: ${res.statusCode} $resBody');
        return null;
      }
    } catch (e) {
      debugPrint('[FCM] Failed to get OAuth2 token: $e');
      return null;
    }
  }

  /// Sends a push notification to the target device via FCM v1.
  Future<void> sendPushNotification({
    required String targetFcmToken,
    required String senderName,
    required String messageText,
    required String chatId,
    required String senderId,
  }) async {
    if (targetFcmToken.isEmpty) return;

    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) return;

      final client = HttpClient();
      final req = await client.postUrl(
        Uri.parse('https://fcm.googleapis.com/v1/projects/$_projectId/messages:send'),
      );
      req.headers.set('Authorization', 'Bearer $accessToken');
      req.headers.contentType = ContentType.json;

      final payload = {
        'message': {
          'token': targetFcmToken,
          'notification': {
            'title': senderName,
            'body': messageText,
          },
          'data': {
            'chatId': chatId,
            'senderId': senderId,
            'senderName': senderName,
            'text': messageText,
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          },
          'android': {
            'priority': 'HIGH',
            'notification': {
              'channel_id': 'chat_messages_channel',
              'sound': 'default',
              'default_vibrate_timings': true,
              'notification_priority': 'PRIORITY_MAX',
            },
          },
        },
      };

      req.write(jsonEncode(payload));
      final res = await req.close();
      final resBody = await res.transform(utf8.decoder).join();
      client.close();

      if (res.statusCode == 200) {
        debugPrint('[FCM] Push sent successfully to partner!');
      } else {
        debugPrint('[FCM] Push send returned ${res.statusCode}: $resBody');
      }
    } catch (e) {
      debugPrint('[FCM] Error sending push: $e');
    }
  }
}
