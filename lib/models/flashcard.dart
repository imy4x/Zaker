class Flashcard {
  final String questionAr;
  final String answerAr;
  final String questionEn;
  final String answerEn;

  Flashcard({
    required this.questionAr, 
    required this.answerAr,
    required this.questionEn,
    required this.answerEn,
  });

  // Legacy support for old single-language flashcards
  Flashcard.legacy({required String question, required String answer})
    : questionAr = question,
      answerAr = answer,
      questionEn = question, // Fallback to same content
      answerEn = answer;

  // Get content based on language
  String getQuestion(String languageCode) {
    return languageCode == 'en' ? questionEn : questionAr;
  }

  String getAnswer(String languageCode) {
    return languageCode == 'en' ? answerEn : answerAr;
  }

  // For backward compatibility
  String get question => questionAr;
  String get answer => answerAr;

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    // Handle both new bilingual format and legacy format
    if (json.containsKey('questionAr') && json.containsKey('questionEn')) {
      return Flashcard(
        questionAr: json['questionAr'] ?? 'لا يوجد سؤال',
        answerAr: json['answerAr'] ?? 'لا توجد إجابة',
        questionEn: json['questionEn'] ?? 'No question',
        answerEn: json['answerEn'] ?? 'No answer',
      );
    } else {
      // Legacy format - assume it's Arabic and duplicate for English
      final question = json['question'] ?? 'لا يوجد سؤال';
      final answer = json['answer'] ?? 'لا توجد إجابة';
      return Flashcard.legacy(question: question, answer: answer);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'questionAr': questionAr,
      'answerAr': answerAr,
      'questionEn': questionEn,
      'answerEn': answerEn,
      // Keep legacy fields for backward compatibility
      'question': questionAr,
      'answer': answerAr,
    };
  }
}
