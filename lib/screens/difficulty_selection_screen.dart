import 'package:flutter/material.dart';
import 'quiz_screen.dart'; 

// Enum để xác định độ khó của quiz
enum QuizDifficulty { easy, medium }

class DifficultySelectionScreen extends StatelessWidget {
  const DifficultySelectionScreen({Key? key}) : super(key: key);

  void _navigateToQuiz(BuildContext context, QuizDifficulty difficulty) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(difficulty: difficulty),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Quiz Difficulty'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () => _navigateToQuiz(context, QuizDifficulty.easy),
              child: const Text('Easy'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 60), // Kích thước nút lớn hơn
                textStyle: const TextStyle(fontSize: 22), // Chữ to hơn
              ),
            ),
            const SizedBox(height: 40), // Khoảng cách lớn hơn
            ElevatedButton(
              onPressed: () => _navigateToQuiz(context, QuizDifficulty.medium),
              child: const Text('Medium'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 60),
                textStyle: const TextStyle(fontSize: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}