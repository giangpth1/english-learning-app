import 'package:flutter/material.dart';
import 'quiz_screen.dart'; 
import '../services/auth_service.dart'; // Import AuthService
import 'login_screen.dart'; // Import LoginScreen

// Enum để xác định độ khó của quiz
enum QuizDifficulty { easy, medium }

class DifficultySelectionScreen extends StatefulWidget {
  const DifficultySelectionScreen({Key? key}) : super(key: key);

  @override
  State<DifficultySelectionScreen> createState() => _DifficultySelectionScreenState();
}

class _DifficultySelectionScreenState extends State<DifficultySelectionScreen> {
  final AuthService _authService = AuthService();
  String? _firstName;
  String? _lastName;
  int? _easyHighScore;
  int? _mediumHighScore;
  bool _isLoadingUserDetails = true;
  bool _isLoadingHighScores = true;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
    _loadHighScores();
  }

  Future<void> _loadUserDetails() async {
    setState(() => _isLoadingUserDetails = true);
    final userDetails = await _authService.getUserDetails();
    if (!mounted) return;
    setState(() {
      _firstName = userDetails['firstName'];
      _lastName = userDetails['lastName'];
      _isLoadingUserDetails = false;
    });
  }

  Future<void> _loadHighScores() async {
    setState(() => _isLoadingHighScores = true);
    try {
      final easyScore = await _authService.getHighScore(QuizDifficulty.easy.name);
      final mediumScore = await _authService.getHighScore(QuizDifficulty.medium.name);
      if (mounted) {
        setState(() {
          _easyHighScore = easyScore;
          _mediumHighScore = mediumScore;
        });
      }
    } catch (e) {
      // Xử lý lỗi, ví dụ: hiển thị SnackBar hoặc log
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load high scores: $e')));
    } finally {
      if (mounted) setState(() => _isLoadingHighScores = false);
    }
  }

  void _navigateToQuiz(BuildContext context, QuizDifficulty difficulty) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(difficulty: difficulty),
      ),
    ).then((_) {
      // Tải lại điểm cao khi quay lại từ QuizScreen
      _loadHighScores();
    });
  }

  void _logout(BuildContext context) async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false, // Xóa tất cả các route trước đó
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Quiz Difficulty'),
        actions: [
          if (_isLoadingUserDetails)
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else if (_firstName != null || _lastName != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                child: Text(
                  'Hi ${_firstName ?? ''} ${_lastName ?? ''}'.trim(),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_isLoadingHighScores)
              const CircularProgressIndicator()
            else ...[
            ElevatedButton(
              onPressed: () => _navigateToQuiz(context, QuizDifficulty.easy),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(220, 80), 
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Easy',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'High Score: ${_easyHighScore ?? "-"}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40), // Khoảng cách lớn hơn
            ElevatedButton(
              onPressed: () => _navigateToQuiz(context, QuizDifficulty.medium),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(220, 80),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Medium',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'High Score: ${_mediumHighScore ?? "-"}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            ],
          ],
        ),
      ),
    );
  }
}

// Extension capitalize vẫn nằm trong quiz_screen.dart vì chỉ QuizScreen sử dụng nó.
// Nếu cần ở nơi khác, bạn có thể di chuyển nó đến một file tiện ích chung.