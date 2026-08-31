import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../cloud.dart';

/// Whether this phone will accept notifications, and its address if it will.
///
/// The permission is asked for once, and deliberately late: iOS gives an app
/// exactly one prompt, and a reader who says no on the first launch can only
/// undo it in the system settings, which nobody does. Asked after a first day
/// is finished, the question has an answer the reader can weigh — they know
/// what the app is by then, and they have a streak to protect.
class Push {
  Push({this.messagingOverride});

  /// Stands in for FirebaseMessaging, which is a singleton and cannot be
  /// faked. Null in the app.
  final FirebaseMessaging? messagingOverride;

  FirebaseMessaging? get _messaging =>
      messagingOverride ?? (Cloud.ready ? FirebaseMessaging.instance : null);

  /// The address to send to, once there is one.
  String? token;

  /// Asks, once. Returns the token if the reader agreed and one came back.
  ///
  /// Never throws: a phone that will not hand over a token is a reader who
  /// gets no notifications, not an app that breaks.
  Future<String?> ask() async {
    final FirebaseMessaging? messaging = _messaging;
    if (messaging == null) return null;
    try {
      final NotificationSettings settings = await messaging.requestPermission();
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        return null;
      }
      return token = await messaging.getToken();
    } catch (error) {
      debugPrint('Could not register for notifications: $error');
      return null;
    }
  }

  /// Picks the token up again on later launches, without asking anything.
  /// A token can be reissued by the system, and one that has changed is one
  /// the server can no longer reach.
  Future<String?> refresh() async {
    final FirebaseMessaging? messaging = _messaging;
    if (messaging == null) return null;
    try {
      final NotificationSettings settings = await messaging
          .getNotificationSettings();
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        return null;
      }
      return token = await messaging.getToken();
    } catch (error) {
      debugPrint('Could not refresh the notification token: $error');
      return null;
    }
  }
}
