import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/notification_model.dart';

class NotificationsRepository {
  final SupabaseClient _supabase;
  NotificationsRepository(this._supabase);

  Future<List<NotificationModel>> getNotifications() async {
    final data = await _supabase
        .from('notifications')
        .select()
        .order('created_at', ascending: false);
    return (data as List).map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> markRead(String id) async {
    await _supabase.from('notifications').update({'is_read': true}).eq('id', id);
  }

  Future<void> markAllRead() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    await _supabase.from('notifications').update({'is_read': true}).eq('user_id', userId);
  }
}
