import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReceiptsRepository {
  final SupabaseClient _supabase;
  ReceiptsRepository(this._supabase);

  Future<List<Map<String, dynamic>>> getReceipts() async {
    final data = await _supabase
        .from('fuel_receipts')
        .select('*, request:fuel_requests!request_id(driver_id, purpose, status)')
        .order('created_at', ascending: false);
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> uploadReceipt({
    required String requestId,
    required String filePath,
  }) async {
    final userId = _supabase.auth.currentUser!.id;
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = '$userId/receipt_$ts.jpg';
    final bytes = await File(filePath).readAsBytes();

    await _supabase.storage
        .from('receipts')
        .uploadBinary(path, bytes, fileOptions: const FileOptions(contentType: 'image/jpeg'));
    final imageUrl = _supabase.storage.from('receipts').getPublicUrl(path);

    final data = await _supabase.from('fuel_receipts').insert({
      'request_id': requestId,
      'image_url': imageUrl,
    }).select().single();

    return data as Map<String, dynamic>;
  }
}
