import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../repositories/notifications_repository.dart';
import '../../../core/models/notification_model.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(ref.read(apiClientProvider)),
);

final notificationsProvider = FutureProvider<List<NotificationModel>>(
  (ref) => ref.read(notificationsRepositoryProvider).getNotifications(),
);

final unreadCountProvider = FutureProvider<int>((ref) async {
  final list = await ref.watch(notificationsProvider.future);
  return list.where((n) => !n.isRead).length;
});
