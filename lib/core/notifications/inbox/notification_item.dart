class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final String type; // queue/update/alert/etc
  final bool read;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.type,
    this.read = false,
  });

  NotificationItem copyWith({bool? read}) => NotificationItem(
    id: id,
    title: title,
    message: message,
    createdAt: createdAt,
    type: type,
    read: read ?? this.read,
  );
}
