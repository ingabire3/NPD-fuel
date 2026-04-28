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

  // Creates a user via Supabase Edge Function (requires service role key server-side)
  // Deploy the 'admin-create-user' Edge Function in your Supabase project.
  Future<UserModel> create({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? phone,
    String? department,
  }) async {
    final res = await _supabase.functions.invoke('admin-create-user', body: {
      'full_name': fullName,
      'email': email,
      'password': password,
      'role': role,
      if (phone != null) 'phone': phone,
      if (department != null) 'department': department,
    });
    if (res.status != 200) throw Exception(res.data?['error'] ?? 'Failed to create user');
    return UserModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> approveUser(String id) async {
    await _supabase
        .from('users')
        .update({'approval_status': 'APPROVED', 'is_active': true})
        .eq('id', id);
  }

  Future<void> deactivate(String id) async {
    await _supabase.from('users').update({'is_active': false}).eq('id', id);
  }

  Future<UserModel> update(String id, Map<String, dynamic> data) async {
    // Convert any camelCase keys to snake_case
    final snakeData = <String, dynamic>{};
    data.forEach((k, v) {
      final snake = k.replaceAllMapped(RegExp(r'[A-Z]'), (m) => '_${m.group(0)!.toLowerCase()}');
      snakeData[snake] = v;
    });
    final result = await _supabase.from('users').update(snakeData).eq('id', id).select().single();
    return UserModel.fromJson(result as Map<String, dynamic>);
  }
}
