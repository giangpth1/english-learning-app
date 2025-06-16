class EnglishWord {
  final int id;
  final String englishWord;
  final List<String> vietnameseTranslations;

  EnglishWord({
    required this.id,
    required this.englishWord,
    required this.vietnameseTranslations,
  });

  factory EnglishWord.fromJson(Map<String, dynamic> json) {
    List<String> translations = [];
    for (int i = 1; i <= 5; i++) {
      if (json['vietnamese_translation_$i'] != null &&
          (json['vietnamese_translation_$i'] as String).isNotEmpty) {
        translations.add(json['vietnamese_translation_$i'] as String);
      }
    }
    return EnglishWord(
      id: json['id'],
      englishWord: json['english_word'],
      vietnameseTranslations: translations,
    );
  }

  String getFormattedTranslations() {
    return vietnameseTranslations.join(' / ');
  }
}