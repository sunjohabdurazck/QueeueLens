import 'dart:math';
import 'notification_item.dart';

class NotificationInboxRepo {
  NotificationInboxRepo._();
  static final instance = NotificationInboxRepo._();

  final List<NotificationItem> _items = [];

  List<NotificationItem> getAll() => List.unmodifiable(_items);

  void add({
    required String title,
    required String message,
    required String type,
  }) {
    final id =
        '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
    _items.insert(
      0,
      NotificationItem(
        id: id,
        title: title,
        message: message,
        createdAt: DateTime.now(),
        type: type,
      ),
    );
  }

  void markRead(String id) {
    final idx = _items.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    _items[idx] = _items[idx].copyWith(read: true);
  }

  void markAllRead() {
    for (int i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(read: true);
    }
  }

  int unreadCount() => _items.where((e) => !e.read).length;
}
