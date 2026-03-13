import '../api/mobile_api.dart';
import 'notification_unread_store.dart';
import '../session/app_session.dart';
import '../../features/shared/models/app_models.dart';
import 'local_notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (defaultTargetPlatform != TargetPlatform.android) {
    return;
  }
  await Firebase.initializeApp();
}

class PushMessagingService {
  PushMessagingService._();

  static final PushMessagingService instance = PushMessagingService._();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await FirebaseMessaging.instance.requestPermission();

    await syncCurrentToken();

    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      if (AppSession.instance.isLoggedIn) {
        await MobileApi.instance.registerPushToken(
          tokenValue: token,
          platform: 'android',
        );
      }
    });

    FirebaseMessaging.onMessage.listen((message) async {
      final data = message.data;
      final profile = AppSession.instance.profile;
      final targetRole = (data['target_role'] ?? '').trim();
      final targetRef = (data['target_ref'] ?? '').trim();
      if (profile == null) {
        return;
      }
      if (targetRole.isNotEmpty && targetRole != profile.role.name) {
        return;
      }
      if (targetRef.isNotEmpty && targetRef != profile.ref) {
        return;
      }
      await NotificationUnreadStore.instance.markUnread(
        profile: profile,
        ids: [data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString()],
      );
      await LocalNotificationService.instance.showDispatchNotification(
        role: profile.role,
        record: DispatchRecord(
          id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          supplierRef: data['supplier_ref'] ?? '',
          supplierName: data['supplier_name'] ?? '',
          itemCode: data['item_code'] ?? '',
          itemName: data['item_name'] ?? '',
          uom: data['uom'] ?? '',
          sentQty: double.tryParse('${data['sent_qty'] ?? 0}') ?? 0,
          acceptedQty: double.tryParse('${data['accepted_qty'] ?? 0}') ?? 0,
          amount: double.tryParse('${data['amount'] ?? 0}') ?? 0,
          currency: data['currency'] ?? '',
          note: data['note'] ?? '',
          eventType: data['event_type'] ?? '',
          highlight: data['highlight'] ?? '',
          status: parseDispatchStatus(data['status'] ?? 'pending'),
          createdLabel: data['created_label'] ?? '',
        ),
      );
    });

    _initialized = true;
  }

  Future<void> syncCurrentToken() async {
    if (defaultTargetPlatform != TargetPlatform.android ||
        !AppSession.instance.isLoggedIn) {
      return;
    }
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.trim().isEmpty) {
      return;
    }
    await MobileApi.instance.registerPushToken(
      tokenValue: token,
      platform: 'android',
    );
  }
}
