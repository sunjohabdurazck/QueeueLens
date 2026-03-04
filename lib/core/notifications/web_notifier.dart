import 'web_notifier_stub.dart' if (dart.library.html) 'web_notifier_web.dart';

abstract class WebNotifier {
  static WebNotifier instance = createWebNotifier();

  Future<void> ensurePermission();
  Future<void> show({required String title, required String body});
}
