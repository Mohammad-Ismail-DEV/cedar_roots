import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/providers.dart';
import '../core/session.dart';
import '../models/json_helpers.dart';
import '../models/user.dart';
import 'push_service.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    api: ref.watch(apiClientProvider),
    session: ref.read(sessionProvider.notifier),
    push: ref.read(pushServiceProvider),
  ),
);

class AuthRepository {
  AuthRepository({
    required this.api,
    required this.session,
    required this.push,
  });

  final ApiClient api;
  final SessionController session;
  final PushService push;

  Future<void> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    await api.post(
      '/auth/signup',
      body: {'name': name, 'email': email, 'password': password},
    );
  }

  Future<void> resendCode(String email) =>
      api.post('/auth/resend', body: {'email': email});

  Future<void> verify({required String email, required String code}) async {
    final data = await api.post(
      '/auth/verify',
      body: {'email': email, 'code': code},
    );
    await _signIn(data);
  }

  Future<void> login({required String email, required String password}) async {
    final data = await api.post(
      '/auth/login',
      body: {'email': email, 'password': password},
    );
    await _signIn(data);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => api.post(
    '/auth/change-password',
    body: {'current_password': currentPassword, 'new_password': newPassword},
  );

  /// Sends a code to [newEmail]; finish with [confirmEmailChange].
  Future<void> startEmailChange({
    required String newEmail,
    required String password,
  }) => api.post(
    '/auth/email-change',
    body: {'new_email': newEmail, 'password': password},
  );

  Future<String> confirmEmailChange(String code) async {
    final data = await api.post(
      '/auth/email-change/confirm',
      body: {'code': code},
    );
    return asMap(data)?['email']?.toString() ?? '';
  }

  Future<void> logout() async {
    await push.unregister();
    await session.signOut();
  }

  Future<void> _signIn(dynamic data) => session.signIn(
    token: data['token'] as String,
    user: User.fromJson(asMap(data['user'])!),
  );
}
