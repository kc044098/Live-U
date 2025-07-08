import '../../data/models/user_model.dart';
import '../../data/network/api_client.dart';
import '../../data/network/api_endpoints.dart';

class AuthRepository {
  final ApiClient apiClient;

  AuthRepository(this.apiClient);

  Future<UserModel> login(String email, String password) async {
    final response = await apiClient.post(
      ApiEndpoints.login,
      data: {
        'email': email,
        'password': password,
      },
    );

    final data = response.data;
    return UserModel(
      userId: data['userId'],
      username: data['username'],
      role: UserRole.host, // 這裡暫時寫死，等後端有 role 回傳後再擴充
    );
  }
}