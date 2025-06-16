import 'package:flutter/material.dart';
import '../models/english_word.dart';
import '../models/easy_quiz_choice.dart'; // Import model mới
import '../services/word_service.dart';
import 'difficulty_selection_screen.dart'; // Import enum QuizDifficulty và màn hình chọn

class QuizScreen extends StatefulWidget {
  final QuizDifficulty difficulty; // Thêm tham số độ khó

  const QuizScreen({Key? key, required this.difficulty}) : super(key: key);

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final WordService _wordService = WordService();
  // Sử dụng dynamic để _wordFuture có thể giữ Future<EnglishWord> hoặc Future<EasyQuizChoice>
  late Future<dynamic> _wordFuture;
  final TextEditingController _translationController = TextEditingController();
  int _correctStreak = 0;
  String? _selectedEasyChoice; // Lưu lựa chọn của người dùng cho easy quiz

  @override
  void initState() {
    super.initState();
    _loadNextWord();
  }

  void _loadNextWord() {
    setState(() {
      _translationController.clear();
      _selectedEasyChoice = null; // Reset lựa chọn cho easy quiz
      if (widget.difficulty == QuizDifficulty.medium) {
        _wordFuture = _wordService.fetchMediumQuizWord();
      } else {
        _wordFuture = _wordService.fetchEasyQuizChoices();
      }
    });
  }

  void _checkAnswer() async {
    try {
      final currentData = await _wordFuture;

      if (widget.difficulty == QuizDifficulty.medium) {
        final currentWord = currentData as EnglishWord;
        final userTranslation = _translationController.text.trim();

        if (userTranslation.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a translation.')),
          );
          return;
        }
        final result = await _wordService.checkTranslation(currentWord.id, userTranslation);
        _showResultDialog(result['is_correct'], currentWord.getFormattedTranslations(), currentWord.getFormattedTranslations());

      } else { // Difficulty.easy
        final currentChoiceData = currentData as EasyQuizChoice;
        if (_selectedEasyChoice == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select an answer.')),
          );
          return;
        }
        final result = await _wordService.checkEasyTranslation(
            currentChoiceData.englishWord, _selectedEasyChoice!);
        _showResultDialog(result['is_correct'], _selectedEasyChoice!, currentChoiceData.correctTranslation);
      }
    } catch (e) {
      _showErrorDialog('Error checking answer: $e');
    }
  }

  void _showResultDialog(bool isCorrect, String userAnswer, String correctAnswer) {
    if (isCorrect) {
      setState(() {
        _correctStreak++;
      });
    } else {
      setState(() {
        _correctStreak = 0;
      });
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isCorrect ? 'Correct!' : 'Incorrect'),
          content: Text(isCorrect
              ? 'Your answer: "$userAnswer" is correct.'
              : 'Your answer: "$userAnswer".\nThe correct meaning is: "$correctAnswer"'),
          actions: <Widget>[
            TextButton(
              child: const Text('Next Word'),
              onPressed: () {
                Navigator.of(context).pop();
                _loadNextWord();
              },
            ),
          ],
        );
      },
    );
  }

  void _skipWord() async {
    try {
      final currentData = await _wordFuture;
      String wordToSkip = "";
      String meaning = "";

      if (widget.difficulty == QuizDifficulty.medium) {
        final currentWord = currentData as EnglishWord;
        wordToSkip = currentWord.englishWord;
        meaning = currentWord.getFormattedTranslations();
      } else {
        final currentChoiceData = currentData as EasyQuizChoice;
        wordToSkip = currentChoiceData.englishWord;
        meaning = currentChoiceData.correctTranslation;
      }

      setState(() {
        _correctStreak = 0;
      });

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Word Skipped'),
            content: Text('The word was "$wordToSkip".\nMeaning: "$meaning".'),
            actions: <Widget>[
              TextButton(
                child: const Text('Next Word'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _loadNextWord();
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      _showErrorDialog('Error skipping word: $e');
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                 // Có thể load lại từ mới hoặc quay về màn hình chọn độ khó
              }
            ),
          ],
        );
      },
    );
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
        title: Text('English Quiz - ${widget.difficulty.toString().split('.').last.capitalize()}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: FutureBuilder<dynamic>(
            future: _wordFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${snapshot.error}'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _loadNextWord,
                      child: const Text('Try Again'),
                    )
                  ],
                );
              } else if (snapshot.hasData) {
                if (widget.difficulty == QuizDifficulty.medium) {
                  final word = snapshot.data as EnglishWord;
                  return _buildMediumQuizUI(word);
                } else {
                  final choiceData = snapshot.data as EasyQuizChoice;
                  return _buildEasyQuizUI(choiceData);
                }
              } else {
                return const Text('No word available.');
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMediumQuizUI(EnglishWord word) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          'Streak: $_correctStreak',
          style: const TextStyle(fontSize: 20, color: Colors.blueAccent),
        ),
        const SizedBox(height: 10),
        Text(
          word.englishWord,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _translationController,
          decoration: const InputDecoration(
            labelText: 'Enter Vietnamese Translation',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _checkAnswer(),
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
  }

  Widget _buildEasyQuizUI(EasyQuizChoice choiceData) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          'Streak: $_correctStreak',
          style: const TextStyle(fontSize: 20, color: Colors.blueAccent),
        ),
        const SizedBox(height: 10),
        Text(
          choiceData.englishWord,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        ...choiceData.allChoices.map((choice) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedEasyChoice = choice;
                  });
                   _checkAnswer(); // Tự động kiểm tra khi chọn
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedEasyChoice == choice ? Theme.of(context).primaryColorLight : Colors.grey[200],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: Text(choice, style: TextStyle(color: _selectedEasyChoice == choice ? Theme.of(context).primaryColorDark : Colors.black87)),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}

// Helper extension cho String để viết hoa chữ cái đầu
extension StringExtension on String {
    String capitalize() {
      if (isEmpty) return "";
      return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
    }
}