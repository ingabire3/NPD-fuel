import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/user_model.dart';

class UsersRepository {
  final SupabaseClient _supabase;
  UsersRepository(this._supabase);

  Future<List<UserModel>> getAll({String? role}) async {
    var query = _supabase.from('users').select();
    if (role != null) query = query.eq('role', role);
    final data = await query.order('created_at', ascending: false);
    return (data as List).map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> create({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
  }) async {
    await _supabase.rpc('admin_create_user', params: {
      'p_name':     name,
      'p_email':    email,
      'p_password': password,
      'p_role':     role,
      'p_phone':    phone,
    });
  }

  Future<void> approveUser(String id) async {
    await _supabase.from('users').update({'status': 'ACTIVE'}).eq('id', id);
  }

  Future<void> rejectUser(String id) async {
    await _supabase.from('users').update({'status': 'PENDING'}).eq('id', id);
  }

  Future<void> activate(String id) async {
    await _supabase.from('users').update({'status': 'ACTIVE'}).eq('id', id);
  }

  Future<void> deactivate(String id) async {
    await _supabase.from('users').update({'status': 'PENDING'}).eq('id', id);
  }
}
