import 'package:supabase_flutter/supabase_flutter.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  factory ApiException.fromError(dynamic e) {
    if (e is PostgrestException) return ApiException(e.message, statusCode: int.tryParse(e.code ?? ''));
    if (e is AuthException) return ApiException(e.message);
    if (e is StorageException) return ApiException(e.message);
    return ApiException(e.toString());
  }

  @override
  String toString() => message;
}
