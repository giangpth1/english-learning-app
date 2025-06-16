import 'package:flutter/material.dart';
import '../models/english_word.dart';
import '../services/word_service.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({Key? key}) : super(key: key);

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final WordService _wordService = WordService();
  late Future<EnglishWord> _wordFuture;
  final TextEditingController _translationController = TextEditingController();
  int _correctStreak = 0;

  @override
  void initState() {
    super.initState();
    _wordFuture = _wordService.fetchRandomWord();
  }

  void _checkAnswer() async {
    try {
      final currentWord = await _wordFuture; // Lấy từ hiện tại từ Future
      final userTranslation = _translationController.text.trim();

      if (userTranslation.isEmpty) {
        if (!mounted) return; // Kiểm tra mounted trước khi dùng context
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a translation.')),
        );
        return;
      }

      final result = await _wordService.checkTranslation(
          currentWord.id, userTranslation);

      String message;
      if (result['is_correct']) {
        setState(() {
          _correctStreak++;
        });
        message = currentWord.getFormattedTranslations();
      } else {
        setState(() {
          _correctStreak = 0;
        });
        message = currentWord.getFormattedTranslations();
      }

      if (!mounted) return; // Kiểm tra mounted trước khi dùng context
      // Hiển thị kết quả dưới dạng modal
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog( // Dialog thông báo kết quả
            title: Text(result['is_correct'] ? 'Correct!' : 'Incorrect'),
            content: Text(message),
            actions: <Widget>[
              TextButton(
                child: const Text('Next Word'),
                onPressed: () {
                  Navigator.of(context).pop(); // Đóng dialog
                  // Lấy từ mới sau khi kiểm tra
                  setState(() {
                    _wordFuture = _wordService.fetchRandomWord();
                    _translationController.clear();
                  });
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      // Xử lý lỗi khi gọi API
      if (!mounted) return; // Kiểm tra mounted trước khi dùng context
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('Error checking answer: $e'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    }
  }

  void _skipWord() async {
    try {
      final currentWord = await _wordFuture; // Lấy từ hiện tại từ Future

      setState(() {
        _correctStreak = 0; // Reset streak
      });

      if (!mounted) return;
      // Hiển thị nghĩa của từ và thông báo reset streak
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Word Skipped'),
            content: Text('"${currentWord.englishWord}" is "${currentWord.getFormattedTranslations()}".'),
            actions: <Widget>[
              TextButton(
                child: const Text('Next Word'),
                onPressed: () {
                  Navigator.of(context).pop(); // Đóng dialog
                  // Lấy từ mới
                  setState(() {
                    _wordFuture = _wordService.fetchRandomWord();
                    _translationController.clear();
                  });
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      // Xử lý lỗi (tương tự như _checkAnswer, nhưng ít khả năng xảy ra ở đây nếu _wordFuture đã resolve)
      // Bạn có thể thêm xử lý lỗi chi tiết hơn nếu cần
      print('Error skipping word: $e');
    }
  }

  @override
  void dispose() {
    _translationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('English Quiz'),
        // actions: [ // Không cần hiển thị streak trên AppBar nữa
        // ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center( // Canh giữa nội dung
          child: FutureBuilder<EnglishWord>(
            future: _wordFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator(); // Hiển thị loading
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}'); // Hiển thị lỗi
              } else if (snapshot.hasData) {
                final word = snapshot.data!;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center, // Canh giữa theo chiều dọc
                  crossAxisAlignment: CrossAxisAlignment.center, // Canh giữa các widget con theo chiều ngang
                  children: <Widget>[
                    Text(
                      'Streak: $_correctStreak',
                      style: const TextStyle(fontSize: 20, color: Colors.blueAccent),
                    ),
                    const SizedBox(height: 10), // Khoảng cách giữa streak và từ tiếng Anh
                    Text(
                      word.englishWord,
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _translationController,
                      decoration: const InputDecoration(
                        labelText: 'Enter Vietnamese Translation',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: _skipWord,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                          child: const Text('Skip Word'),
                        ),
                        ElevatedButton(
                          onPressed: _checkAnswer,
                          child: const Text('Check Answer'),
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                return const Text('No word available.'); // Trường hợp không có dữ liệu
              }
            },
          ),
        ),
      ),
    );
  }
}