import 'dart:math';

class EasyQuizChoice {
  final String englishWord;
  final String correctTranslation;
  final List<String> otherRandomTranslations;
  late final List<String> allChoices; // Sẽ chứa cả đáp án đúng và sai, đã xáo trộn

  EasyQuizChoice({
    required this.englishWord,
    required this.correctTranslation,
    required this.otherRandomTranslations,
  }) {
    allChoices = ([correctTranslation] + otherRandomTranslations)..shuffle(Random());
  }

  factory EasyQuizChoice.fromJson(Map<String, dynamic> json) {
    return EasyQuizChoice(
      englishWord: json['english_word'],
      correctTranslation: json['correct_translation'],
      otherRandomTranslations: List<String>.from(json['other_random_translations']),
    );
  }
}