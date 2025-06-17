import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/english_word.dart';
import '../models/easy_quiz_choice.dart'; // Thêm import cho model mới

class WordService {
  // Thay thế bằng URL của backend Django của bạn
  // Nếu chạy local, dùng địa chỉ IP của máy tính hoặc 10.0.2.2 cho Android emulator
  // và localhost cho iOS simulator.
  // Ví dụ: Nếu chạy Django trên http://127.0.0.1:8000/
  // Android Emulator: 'http://10.0.2.2:8000/random-english-word/api/words'
  // iOS Simulator: 'http://localhost:8000/random-english-word/api/words'
  // Khi deploy lên server, dùng URL của server: 'https://your-django-app.com/random-english-word/api/words'
  // final String baseUrl = 'http://13.215.176.86:8000/random-english-word/api/words';
  final String baseUrl = 'http://127.0.0.1:8000/api/words';
  
  Future<EnglishWord> fetchMediumQuizWord() async {
    final response = await http.get(Uri.parse('$baseUrl/medium-quiz-choices/'));

    if (response.statusCode == 200) {
      // If the server returned a 200 OK response, parse the JSON.
      return EnglishWord.fromJson(jsonDecode(response.body));
    } else {
      // If the server did not return a 200 OK response,
      // throw an exception.
      throw Exception('Failed to load random word');
    }
  }

  Future<EasyQuizChoice> fetchEasyQuizChoices() async {
    // Giả sử endpoint cho easy là /easy-quiz-choices/
    // Bạn cần đảm bảo API backend của bạn có endpoint này
    final response = await http.get(Uri.parse('$baseUrl/easy-quiz-choices/'));

    if (response.statusCode == 200) {
      return EasyQuizChoice.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load easy quiz choices');
    }
  }

  Future<Map<String, dynamic>> checkTranslation(int wordId, String translation) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$wordId/check_translation/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{'translation': translation}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to check translation');
    }
  }

  // Hàm kiểm tra cho độ khó easy
  // API backend của bạn cần hỗ trợ việc kiểm tra này.
  // Ví dụ: POST /random-english-word/api/words/check-easy-translation/
  // Body: { "english_word": "information", "selected_translation": "thông tin" }
  // Response: { "is_correct": true }
  Future<Map<String, dynamic>> checkEasyTranslation(String englishWord, String selectedTranslation) async {
    // Điều chỉnh endpoint và body cho phù hợp với API của bạn
    final response = await http.post(
      Uri.parse('$baseUrl/check-easy-translation/'), // Endpoint ví dụ
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'english_word': englishWord,
        'selected_translation': selectedTranslation,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to check easy translation: ${response.body}');
    }
  }
}