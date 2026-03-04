// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'web_notifier.dart';

WebNotifier createWebNotifier() => _WebNotifierWeb();

class _WebNotifierWeb implements WebNotifier {
  @override
  Future<void> ensurePermission() async {
    if (html.Notification.supported) {
      if (html.Notification.permission != 'granted') {
        await html.Notification.requestPermission();
      }
    }
  }

  @override
  Future<void> show({required String title, required String body}) async {
    if (!html.Notification.supported) return;
    if (html.Notification.permission != 'granted') return;

    html.Notification(title, body: body);
  }
}
