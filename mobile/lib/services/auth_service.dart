import '../config/api_config.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  }) async {
    final response = await _api.post(
      ApiConfig.register,
      {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        if (phone != null) 'phone': phone,
      },
      withAuth: false,
    );

    if (response['success']) {
      await _api.setToken(response['data']['token']);
      return {
        'success': true,
        'user': User.fromJson(response['data']['user']),
      };
    }

    return response;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post(
      ApiConfig.login,
      {
        'email': email,
        'password': password,
      },
      withAuth: false,
    );

    if (response['success']) {
      await _api.setToken(response['data']['token']);
      return {
        'success': true,
        'user': User.fromJson(response['data']['user']),
      };
    }

    return response;
  }

  Future<void> logout() async {
    await _api.post(ApiConfig.logout, {});
    await _api.removeToken();
  }

  Future<User?> getCurrentUser() async {
    final token = await _api.getToken();
    if (token == null) return null;

    final response = await _api.get(ApiConfig.me);
    if (response['success']) {
      return User.fromJson(response['data']['user']);
    }
    return null;
  }

  Future<bool> isLoggedIn() async {
    final token = await _api.getToken();
    return token != null;
  }

  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
  }) async {
    final response = await _api.put(
      ApiConfig.updateProfile,
      {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
      },
    );

    if (response['success']) {
      return {
        'success': true,
        'user': User.fromJson(response['data']['user']),
      };
    }

    return response;
  }
}
