import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  // Điều chỉnh baseUrl này nếu API của bạn được host ở nơi khác
  // Ví dụ: Nếu Django chạy trên http://127.0.0.1:8000/
  // Android Emulator: 'http://10.0.2.2:8000'
  // iOS Simulator: 'http://localhost:8000'
  final String _baseUrl = 'http://127.0.0.1:8000'; // Hoặc 'http://10.0.2.2:8000' cho Android emulator
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userFirstNameKey = 'user_first_name';
  static const String _userLastNameKey = 'user_last_name';

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String password2,
    required String firstName,
    required String lastName,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/users/auth/register/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'username': username,
        'email': email,
        'password': password,
        'password2': password2,
        'first_name': firstName,
        'last_name': lastName,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) { // Django REST framework thường trả về 201 cho tạo mới
      // Giả sử API trả về access và refresh token ngay sau khi đăng ký
      // Nếu không, bạn có thể cần phải gọi API đăng nhập sau khi đăng ký thành công
      // Và API cũng trả về thông tin người dùng như first_name, last_name
      final data = jsonDecode(response.body);
      if (data['access'] != null && data['refresh'] != null) {
        // Giả sử API trả về first_name và last_name trong object 'user' hoặc ở root
        String? respFirstName = data['user']?['first_name'] ?? data['first_name'];
        String? respLastName = data['user']?['last_name'] ?? data['last_name'];
        await _saveAuthData(
          data['access'],
          data['refresh'],
          respFirstName,
          respLastName,
        );
        return true;
      }
      // Nếu API đăng ký không trả token, chỉ cần trả về true và yêu cầu người dùng đăng nhập
      return true; 
    } else {
      // Xử lý lỗi, ví dụ: hiển thị thông báo lỗi từ server
      // final errorData = jsonDecode(response.body);
      // throw Exception('Failed to register: ${errorData.toString()}');
      throw Exception('Failed to register. Status code: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<bool> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/users/auth/login/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'username': username, // Hoặc 'email' tùy theo cấu hình Django của bạn
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Giả sử API trả về first_name và last_name trong object 'user' hoặc ở root
      String? respFirstName = data['user']?['first_name'] ?? data['first_name'];
      String? respLastName = data['user']?['last_name'] ?? data['last_name'];
      await _saveAuthData(
        data['access'],
        data['refresh'],
        respFirstName,
        respLastName,
      );
      return true;
    } else {
      // final errorData = jsonDecode(response.body);
      // throw Exception('Failed to login: ${errorData.toString()}');
      throw Exception('Failed to login. Status code: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<void> _saveAuthData(String accessToken, String refreshToken, String? firstName, String? lastName) async {
    await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
    if (firstName != null) {
      await _secureStorage.write(key: _userFirstNameKey, value: firstName);
    }
    if (lastName != null) {
      await _secureStorage.write(key: _userLastNameKey, value: lastName);
    }
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  Future<Map<String, String?>> getUserDetails() async {
    final firstName = await _secureStorage.read(key: _userFirstNameKey);
    final lastName = await _secureStorage.read(key: _userLastNameKey);
    return {'firstName': firstName, 'lastName': lastName};
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _userFirstNameKey);
    await _secureStorage.delete(key: _userLastNameKey);
  }

  Future<bool> isLoggedIn() async {
    final accessToken = await getAccessToken();
    return accessToken != null;
  }

  Future<int> getHighScore(String difficultyLevel) async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('User not logged in. Cannot fetch high score.');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/api/users/auth/highscore/$difficultyLevel/'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Giả sử API trả về {"high_score": 10} hoặc một trường tương tự
      return (data['high_score'] ?? data['score'] ?? 0) as int;
    } else if (response.statusCode == 404) {
      // Không có high score nào được ghi lại cho người dùng này ở độ khó này
      return 0;
    } else {
      throw Exception('Failed to load high score for $difficultyLevel. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<bool> updateHighScore(String difficultyLevel, int score) async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('User not logged in. Cannot update high score.');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/api/users/auth/highscore/$difficultyLevel/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, int>{
        'score': score,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      // Backend đã cập nhật thành công (200 OK hoặc 201 Created nếu bản ghi mới được tạo)
      return true;
    } else {
      // In ra lỗi để debug nếu cần
      // print('Failed to update high score. Status: ${response.statusCode}, Body: ${response.body}');
      return false;
    }
  }
}