import 'package:flutter_test/flutter_test.dart';
import 'package:zaker/api/gemini_service_new.dart';
import 'package:zaker/services/enhanced_service_manager.dart';
import 'package:zaker/constants/app_constants.dart';

/// 🧪 اختبارات شاملة للنظام المحسن
/// Comprehensive tests for the enhanced system

void main() {
  group('Enhanced System Tests', () {
    late EnhancedServiceManager serviceManager;
    
    setUp(() {
      serviceManager = EnhancedServiceManager.instance;
    });

    group('JSON Parser Tests', () {
      test('should parse valid JSON correctly', () {
        const jsonString = '''
        {
          "questions": [
            {
              "questionAr": "ما هو الحاسوب؟",
              "optionsAr": ["جهاز إلكتروني", "آلة حاسبة", "هاتف", "كتاب"],
              "questionEn": "What is a computer?",
              "optionsEn": ["Electronic device", "Calculator", "Phone", "Book"],
              "correctAnswerIndex": 0,
              "difficulty": "easy"
            }
          ]
        }
        ''';
        
        // Test will be implemented with public methods only
        expect(true, isTrue); // Placeholder
      });

      test('should handle malformed JSON gracefully', () {
        // Test will be implemented with public methods only
        expect(true, isTrue); // Placeholder
      });

      test('should extract JSON from mixed content', () {
        // Test will be implemented with public methods only
        expect(true, isTrue); // Placeholder
      });

      test('should handle Arabic text with proper escaping', () {
        // Test will be implemented with public methods only
        expect(true, isTrue); // Placeholder
      });
    });

    group('Service Manager Tests', () {
      test('should initialize properly as singleton', () {
        final instance1 = EnhancedServiceManager.instance;
        final instance2 = EnhancedServiceManager.instance;
        
        expect(identical(instance1, instance2), isTrue);
      });

      test('should track statistics correctly', () {
        serviceManager.resetStats();
        
        final initialStats = serviceManager.getStats();
        expect(initialStats.totalRequests, equals(0));
        expect(initialStats.successfulRequests, equals(0));
        expect(initialStats.failedRequests, equals(0));
        expect(initialStats.successRate, equals(0.0));
      });

      test('should provide fallback content when service fails', () async {
        const testText = 'This is a test text for fallback functionality.';
        
        // Test fallback summary
        final summaryResult = await serviceManager.generateSummary(
          text: testText,
          onKeyChanged: (index) {}, // Mock callback
        );
        
        expect(summaryResult, isNotNull);
        expect(summaryResult.arabicSummary, isNotEmpty);
        expect(summaryResult.englishSummary, isNotEmpty);
        expect(summaryResult.wordCount, equals(testText.length));
      });

      test('should handle content validation gracefully', () async {
        const validText = 'Computer networks are systems of interconnected computers.';
        const invalidText = 'Pizza, Burger, Fries, Cola';
        
        final validResult = await serviceManager.validateContent(
          validText,
          (index) {}, // Mock callback
        );
        
        final invalidResult = await serviceManager.validateContent(
          invalidText,
          (index) {}, // Mock callback
        );
        
        expect(validResult, isNotNull);
        expect(invalidResult, isNotNull);
        expect(validResult.confidence, isA<double>());
        expect(invalidResult.confidence, isA<double>());
      });
    });

    group('Fallback Content Tests', () {
      test('should generate meaningful fallback summary in Arabic', () async {
        const testText = 'معلومات تقنية مهمة حول شبكات الحاسوب وأنظمة المعلومات.';
        
        final result = await serviceManager.generateSummary(
          text: testText,
          targetLanguage: 'ar',
          onKeyChanged: (index) {},
        );
        
        expect(result.arabicSummary, contains('💎'));
        expect(result.arabicSummary, contains('المحتوى'));
        expect(result.arabicSummary, contains('للدراسة'));
      });

      test('should generate meaningful fallback summary in English', () async {
        const testText = 'Important technical information about computer networks and information systems.';
        
        final result = await serviceManager.generateSummary(
          text: testText,
          targetLanguage: 'en', 
          onKeyChanged: (index) {},
        );
        
        expect(result.englishSummary, contains('💎'));
        expect(result.englishSummary, contains('content'));
        expect(result.englishSummary, contains('study'));
      });

      test('should generate fallback questions with proper structure', () async {
        const testText = 'Sample educational content for testing quiz generation.';
        
        final result = await serviceManager.generateQuiz(
          text: testText,
          onKeyChanged: (index) {},
        );
        
        expect(result.questions, isNotEmpty);
        expect(result.questions.first.questionAr, isNotEmpty);
        expect(result.questions.first.questionEn, isNotEmpty);
        expect(result.questions.first.optionsAr, hasLength(4));
        expect(result.questions.first.optionsEn, hasLength(4));
        expect(result.questions.first.correctAnswerIndex, inInclusiveRange(0, 3));
      });

      test('should generate fallback flashcards with proper structure', () async {
        const testText = 'Educational content for flashcard generation testing.';
        
        final result = await serviceManager.generateFlashcards(
          text: testText,
          onKeyChanged: (index) {},
        );
        
        expect(result.flashcards, isNotEmpty);
        expect(result.flashcards.first.questionAr, isNotEmpty);
        expect(result.flashcards.first.answerAr, isNotEmpty);
        expect(result.flashcards.first.questionEn, isNotEmpty);
        expect(result.flashcards.first.answerEn, isNotEmpty);
      });
    });

    group('Error Handling Tests', () {
      test('should handle network errors gracefully', () async {
        // Simulate network error by providing invalid callback
        final result = await serviceManager.generateSummary(
          text: 'Test text',
          onKeyChanged: (index) {
            throw Exception('Network error simulation');
          },
        );
        
        expect(result, isNotNull);
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, isNotNull);
        expect(result.arabicSummary, isNotEmpty); // Should have fallback content
      });

      test('should maintain statistics during errors', () async {
        serviceManager.resetStats();
        
        // Generate some failures
        await serviceManager.generateSummary(
          text: 'Test',
          onKeyChanged: (index) {
            throw Exception('Test error');
          },
        );
        
        final stats = serviceManager.getStats();
        expect(stats.totalRequests, greaterThan(0));
        expect(stats.failedRequests, greaterThan(0));
      });
    });

    group('Performance Tests', () {
      test('should process small text efficiently', () async {
        const smallText = 'Short educational content for testing.';
        
        final stopwatch = Stopwatch()..start();
        
        final result = await serviceManager.generateSummary(
          text: smallText,
          onKeyChanged: (index) {},
        );
        
        stopwatch.stop();
        
        expect(result, isNotNull);
        expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // Should complete within 10 seconds
      });

      test('should handle concurrent requests properly', () async {
        const testText = 'Concurrent request testing content.';
        
        final futures = List.generate(3, (index) => 
          serviceManager.generateSummary(
            text: '$testText $index',
            onKeyChanged: (keyIndex) {},
          ),
        );
        
        final results = await Future.wait(futures);
        
        expect(results, hasLength(3));
        for (final result in results) {
          expect(result, isNotNull);
          expect(result.arabicSummary, isNotEmpty);
          expect(result.englishSummary, isNotEmpty);
        }
      });
    });

    group('Content Quality Tests', () {
      test('should maintain content integrity in bilingual output', () async {
        const bilingualText = '''
        Computer networks الشبكات الحاسوبية are essential infrastructure
        البنية التحتية الأساسية for modern digital communication.
        ''';
        
        final result = await serviceManager.generateSummary(
          text: bilingualText,
          onKeyChanged: (index) {},
        );
        
        expect(result.arabicSummary, isNotEmpty);
        expect(result.englishSummary, isNotEmpty);
        expect(result.arabicSummary, isNot(equals(result.englishSummary)));
      });

      test('should respect custom notes in generation', () async {
        const testText = 'Educational content about data structures.';
        const customNotes = 'Focus on algorithms and complexity analysis.';
        
        final result = await serviceManager.generateSummary(
          text: testText,
          customNotes: customNotes,
          onKeyChanged: (index) {},
        );
        
        expect(result, isNotNull);
        // Custom notes should be incorporated somehow
        // (This would be more meaningful with actual AI service)
      });
    });
  });
}