import 'web_notifier.dart';

WebNotifier createWebNotifier() => _WebNotifierStub();

class _WebNotifierStub implements WebNotifier {
  @override
  Future<void> ensurePermission() async {}

  @override
  Future<void> show({required String title, required String body}) async {}
}
