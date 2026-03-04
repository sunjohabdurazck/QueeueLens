import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_inbox_repo.dart';
import 'notification_item.dart';

final notificationInboxProvider =
    StateNotifierProvider<NotificationInboxNotifier, List<NotificationItem>>(
      (ref) => NotificationInboxNotifier(),
    );

class NotificationInboxNotifier extends StateNotifier<List<NotificationItem>> {
  NotificationInboxNotifier() : super(NotificationInboxRepo.instance.getAll());

  void refresh() {
    state = NotificationInboxRepo.instance.getAll();
  }

  void add(String title, String message, String type) {
    NotificationInboxRepo.instance.add(
      title: title,
      message: message,
      type: type,
    );
    refresh();
  }

  void markRead(String id) {
    NotificationInboxRepo.instance.markRead(id);
    refresh();
  }

  void markAllRead() {
    NotificationInboxRepo.instance.markAllRead();
    refresh();
  }

  int unreadCount() => NotificationInboxRepo.instance.unreadCount();
}
