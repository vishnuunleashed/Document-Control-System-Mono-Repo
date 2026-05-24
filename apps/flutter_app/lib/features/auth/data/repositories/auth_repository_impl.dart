import '../../../../core/network/api_client.dart';
import '../../../../shared/services/session_manager.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;

  AuthRepositoryImpl(this._apiClient);

  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _apiClient.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    
    final data = response.data;
    final token = data['token'];
    final user = data['user'] as Map<String, dynamic>;

    await SessionManager.saveSession(token, user);
    return user;
  }

  @override
  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String role,
  ) async {
    final response = await _apiClient.post('/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    });
    
    final data = response.data;
    final token = data['token'];
    final user = data['user'] as Map<String, dynamic>;

    await SessionManager.saveSession(token, user);
    return user;
  }

  @override
  Future<void> logout() async {
    await SessionManager.clearSession();
  }
}
