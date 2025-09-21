// ملف جديد لتنظيم النماذج (Enums) والثوابت المستخدمة في التطبيق

// أولاً: نماذج التحليل الثلاثة
enum AnalysisDepth {
  deep, // النموذج العميق
  medium, // النموذج المتوسط
  light, // النموذج الخفيف
}

extension AnalysisDepthExtension on AnalysisDepth {
  String get nameAr {
    switch (this) {
      case AnalysisDepth.deep:
        return 'تحليل عميق';
      case AnalysisDepth.medium:
        return 'تحليل متوسط';
      case AnalysisDepth.light:
        return 'تحليل خفيف';
    }
  }

  String get descriptionAr {
    switch (this) {
      case AnalysisDepth.deep:
        return 'شرح تفصيلي شبيه بالمنهج الجامعي مع أمثلة وتشبيهات لترسيخ الفهم.';
      case AnalysisDepth.medium:
        return 'تحليل متوازن يجمع بين الشرح والنقاط الأساسية.';
      case AnalysisDepth.light:
        return 'ملخص سريع يركز على المفاهيم والنقاط الهامة فقط.';
    }
  }
}


// ثانياً: مستويات صعوبة الاختبار
enum QuizDifficulty {
  easy,
  medium,
  hard,
  veryHard,
  mixed, // خيار جديد لمزيج من كل المستويات
}


extension QuizDifficultyExtension on QuizDifficulty {
  String get nameAr {
    switch (this) {
      case QuizDifficulty.easy: return 'سهل';
      case QuizDifficulty.medium: return 'متوسط';
      case QuizDifficulty.hard: return 'صعب';
      case QuizDifficulty.veryHard: return 'صعب جداً';
      case QuizDifficulty.mixed: return 'متنوع';
    }
  }
}
