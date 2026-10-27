import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

typedef Json = Map<String, dynamic>;

class AppUser {
  AppUser.fromJson(Map j)
      : id = j['id'],
        nama = j['nama'],
        role = j['role'],
        username = j['username'];
  final int id;
  final String nama, role, username;
  bool get isAdmin => role == 'ADMIN';
}

class AuthState {
  const AuthState({this.user, this.booting = false});
  final AppUser? user;
  final bool booting;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this.api) : super(const AuthState(booting: true)) {
    api.onUnauthorized = logout;
    _restore();
  }
  final ApiClient api;

  Future<void> _restore() async {
    final t = await api.loadToken();
    if (t == null) {
      state = const AuthState();
      return;
    }
    try {
      final r = await api.dio.get('/auth/me');
      state = AuthState(user: AppUser.fromJson(r.data));
    } catch (_) {
      await api.clearToken();
      state = const AuthState();
    }
  }

  Future<void> login(String username, String password) async {
    final r = await api.dio.post('/auth/login', data: {'username': username, 'password': password});
    await api.saveToken(r.data['token']);
    state = AuthState(user: AppUser.fromJson(r.data['user']));
  }

  Future<void> logout() async {
    await api.clearToken();
    state = const AuthState();
  }
}

final apiProvider = Provider<ApiClient>((ref) => ApiClient());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
    (ref) => AuthNotifier(ref.read(apiProvider)));

List<Json> _list(dynamic d) => (d as List).map((e) => Json.from(e)).toList();

final dashboardProvider = FutureProvider.autoDispose<Json>((ref) async {
  final r = await ref.read(apiProvider).dio.get('/dashboard');
  return Json.from(r.data);
});

final medicinesProvider = FutureProvider.autoDispose.family<List<Json>, String>((ref, q) async {
  final r = await ref.read(apiProvider).dio.get('/medicines', queryParameters: {if (q.isNotEmpty) 'q': q});
  return _list(r.data);
});

final categoriesProvider = FutureProvider.autoDispose<List<Json>>((ref) async {
  final r = await ref.read(apiProvider).dio.get('/categories');
  return _list(r.data);
});

final unitsProvider = FutureProvider.autoDispose<List<Json>>((ref) async {
  final r = await ref.read(apiProvider).dio.get('/units');
  return _list(r.data);
});
