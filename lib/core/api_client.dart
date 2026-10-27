import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Ganti saat build: flutter run --dart-define=API_URL=https://api-kamu.com/api
/// 10.0.2.2 = localhost komputer jika pakai emulator Android.
const kBaseUrl = String.fromEnvironment('API_URL',
    defaultValue: 'https://manage-medicine-be.vercel.app/api');

class ApiClient {
  ApiClient()
      : dio = Dio(BaseOptions(
          baseUrl: kBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
        )) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (o, h) {
        if (token != null) o.headers['Authorization'] = 'Bearer $token';
        h.next(o);
      },
      onError: (e, h) {
        if (e.response?.statusCode == 401 &&
            !e.requestOptions.path.contains('/auth/login')) {
          onUnauthorized?.call();
        }
        h.next(e);
      },
    ));
  }

  final Dio dio;
  static const _storage = FlutterSecureStorage();
  String? token;
  void Function()? onUnauthorized;

  Future<String?> loadToken() async =>
      token = await _storage.read(key: 'token');
  Future<void> saveToken(String t) async {
    token = t;
    await _storage.write(key: 'token', value: t);
  }

  Future<void> clearToken() async {
    token = null;
    await _storage.delete(key: 'token');
  }
}

String errMsg(Object e) {
  if (e is DioException) {
    final d = e.response?.data;
    if (d is Map && d['message'] != null) return d['message'].toString();
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Tidak dapat terhubung ke server';
    }
  }
  return e.toString();
}
