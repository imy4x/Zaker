import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaker/services/language_service.dart';
import 'package:zaker/utils/responsive_utils.dart';

class EnhancedSummaryWidget extends StatefulWidget {
  final String summaryAr;
  final String summaryEn;

  const EnhancedSummaryWidget({
    super.key,
    required this.summaryAr,
    required this.summaryEn,
  });

  // Backward compatibility constructor
  const EnhancedSummaryWidget.legacy({
    super.key,
    required String summary,
  })  : summaryAr = summary,
        summaryEn = summary;

  @override
  State<EnhancedSummaryWidget> createState() => _EnhancedSummaryWidgetState();
}

class _EnhancedSummaryWidgetState extends State<EnhancedSummaryWidget>
    with SingleTickerProviderStateMixin {
  final LanguageService _languageService = LanguageService();
  late AnimationController _languageToggleController;
  late Animation<double> _languageToggleAnimation;
  
  String get _currentLanguage => _languageService.currentLanguage;

  @override
  void initState() {
    super.initState();
    _languageToggleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _languageToggleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _languageToggleController,
      curve: Curves.easeInOut,
    ));
    
    // إعداد واستعادة اللغة
    _initializeLanguage();
    
    // إضافة مستمع لتغييرات اللغة
    _languageService.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    _languageToggleController.dispose();
    _languageService.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _toggleLanguage() async {
    await _languageService.toggleLanguage();
  }
  
  /// إعداد اللغة عند بداية التطبيق
  Future<void> _initializeLanguage() async {
    await _languageService.initialize();
    _updateAnimationForCurrentLanguage();
  }
  
  /// معالج تغيير اللغة
  void _onLanguageChanged(String newLanguage) {
    setState(() {
      // التحديث التلقائي للواجهة
    });
    _updateAnimationForCurrentLanguage();
  }
  
  /// تحديث الأنيميشن حسب اللغة الحالية
  void _updateAnimationForCurrentLanguage() {
    if (_currentLanguage == 'en') {
      _languageToggleController.forward();
    } else {
      _languageToggleController.reverse();
    }
  }

  String get _currentSummary =>
      _currentLanguage == 'en' ? widget.summaryEn : widget.summaryAr;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: ResponsiveUtils.getResponsiveMargin(context),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.8),
          ],
        ),
        borderRadius:
            BorderRadius.circular(ResponsiveUtils.getCardBorderRadius(context)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(
                    ResponsiveUtils.getCardBorderRadius(context)),
                topRight: Radius.circular(
                    ResponsiveUtils.getCardBorderRadius(context)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.auto_stories_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentLanguage == 'en'
                            ? 'Study Summary'
                            : 'الملخص التعليمي',
                        style: GoogleFonts.cairo(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                              context, 22),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentLanguage == 'en'
                            ? 'Enhanced for studying and review'
                            : 'مُحسَّن للدراسة والمراجعة',
                        style: GoogleFonts.cairo(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                              context, 14),
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                // Language toggle button
                AnimatedBuilder(
                  animation: _languageToggleAnimation,
                  builder: (context, child) {
                    return GestureDetector(
                      onTap: _toggleLanguage,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Transform.rotate(
                              angle: _languageToggleAnimation.value * 3.14159,
                              child: Icon(
                                Icons.translate_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _currentLanguage == 'ar' ? 'EN' : 'عر',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Container(
              padding: ResponsiveUtils.getFlashcardPadding(context),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.3),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      )),
                      child: child,
                    ),
                  );
                },
                child: SingleChildScrollView(
                  key: ValueKey(_currentLanguage),
                  child: _SummaryMarkdown(
                    data: _formatSummary(_currentSummary),
                    context: context,
                    languageCode: _currentLanguage,
                  ),
                ),
              ),
            ),
          ),

          // Footer with study tip
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(
                    ResponsiveUtils.getCardBorderRadius(context)),
                bottomRight: Radius.circular(
                    ResponsiveUtils.getCardBorderRadius(context)),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentLanguage == 'en'
                        ? 'Remember: Review the summary several times to ensure complete understanding'
                        : 'تذكر: راجع الملخص عدة مرات لضمان الفهم الكامل',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatSummary(String originalSummary) {
    if (originalSummary.trim().isEmpty) {
      return _currentLanguage == 'ar'
          ? 'لا يتوفر محتوى للعرض.\n\nيرجى إضافة محتوى لإنشاء الملخص.'
          : 'No content available.\n\nPlease add content to create the summary.';
    }

    String formatted = originalSummary.trim();

    // معالجة خاصة للنصوص بتنسيق JSON أو القوائم المدمجة
    formatted = _handleSpecialFormats(formatted);
    
    // تطبيق التحسينات الشاملة للتنسيق
    formatted = _applyAdvancedFormatting(formatted);
    formatted = _fixDirectionalityIssues(formatted);
    formatted = _enhanceVisualHierarchy(formatted);
    formatted = _improveListFormatting(formatted);
    formatted = _addVisualBreaks(formatted);

    return formatted;
  }

  /// معالجة التنسيقات الخاصة والقوائم المدمجة
  String _handleSpecialFormats(String text) {
    // معالجة القوائم المدمجة في سطر واحد (فقط إذا لم تكن معالجة مسبقاً)
    // تجنب التطبيق إذا كان النص يحتوي على علامة "**القائمة الرسمية:**" مسبقاً
    if (!text.contains('**القائمة الرسمية:**') && !text.contains('**Official List:**')) {
      text = text.replaceAllMapped(
        RegExp(r'([A-Z][A-Z.#]*(?:[,\s]+[A-Z][A-Z.#]*)+)', multiLine: true),
        (match) {
          final combinedList = match.group(1)!;
          
          // تفادي التعرف على نص عادي غير قائمة والتأكد من عدم وجود عربي
          if ((combinedList.contains('NET') || combinedList.contains('PYTHON') || 
               combinedList.contains('RUBY') || combinedList.contains('JAVA')) &&
              !_containsArabicText(combinedList)) {
            
            // تقسيم القائمة على أساس الفواصل وتنسيقها بشكل منظم
            final items = combinedList
                .replaceAll(RegExp(r'\s+'), ' ') // تنظيف المسافات
                .split(RegExp(r'[,\s]+'))
                .where((item) => item.trim().isNotEmpty && item.length > 1)
                .toList();
            
            if (items.length >= 3) { // فقط إذا كانت قائمة فعلية
              final formattedItems = items.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final item = entry.value.trim();
                return '**$index.** $item';
              }).join('\n\n');
              
              // استخدام عنوان يتناسب مع اللغة الحالية
              final listTitle = _currentLanguage == 'ar' ? '**القائمة الرسمية:**' : '**Official List:**';
              return '\n\n$listTitle \n\n$formattedItems\n\n';
            }
          }
          return combinedList; // إرجاع النص الأصلي إذا لم يكن قائمة
        },
      );
    }

    // معالجة النصوص بتنسيق JSON أو شبه JSON (مشكلة الصورة الثالثة)
    if (text.contains('"title"') || text.contains('"content"') || text.contains('"core_concept"')) {
      text = text.replaceAll(RegExp(r'[{}"\[\]]'), ''); // إزالة رموز JSON
      text = text.replaceAllMapped(
        RegExp(r'title\s*:\s*([^,\n]+)', multiLine: true),
        (match) => '\n\n## 🎯 ${match.group(1)!.trim()}\n\n',
      );
      
      text = text.replaceAllMapped(
        RegExp(r'content\s*:\s*([^,\n]+)', multiLine: true),
        (match) => '\n${match.group(1)!.trim()}\n\n',
      );
      
      text = text.replaceAllMapped(
        RegExp(r'core_concept\s*:\s*([^,\n]+)', multiLine: true),
        (match) => '\n### ✨ **المفهوم الأساسي:** ${match.group(1)!.trim()}\n\n',
      );
    }

    // معالجة القوائم المفصولة بفواصل مختلفة
    text = text.replaceAllMapped(
      RegExp(r'(\d+)\s*[.)]\s*([^\n]+(?:\n(?!\d+\s*[.)]).*)*)', multiLine: true),
      (match) {
        final number = match.group(1)!;
        final content = match.group(2)!.trim();
        return '\n**$number.** $content\n';
      },
    );

    return text;
  }

  /// تطبيق التنسيق المتقدم للملخص
  String _applyAdvancedFormatting(String text) {
    // تحسين العناوين الرئيسية
    text = text.replaceAllMapped(
      RegExp(r'^##\s*([^#].+)$', multiLine: true),
      (match) {
        final title = match.group(1)!.trim();
        return '\n\n## 🎯 $title\n';
      },
    );

    // تحسين العناوين الفرعية
    text = text.replaceAllMapped(
      RegExp(r'^###\s*([^#].+)$', multiLine: true),
      (match) {
        final title = match.group(1)!.trim();
        return '\n### ✨ $title\n';
      },
    );

    // تحسين العناوين التفصيلية
    text = text.replaceAllMapped(
      RegExp(r'^####\s*([^#].+)$', multiLine: true),
      (match) {
        final title = match.group(1)!.trim();
        return '\n#### 💡 $title\n';
      },
    );

    return text;
  }

  /// إصلاح مشاكل الاتجاه في النصوص المختلطة
  String _fixDirectionalityIssues(String text) {
    // إزالة علامات الاتجاه القديمة والمتعارضة أولاً
    text = text
        .replaceAll('\u202D', '')
        .replaceAll('\u202C', '')
        .replaceAll('\u061C', '')
        .replaceAll('\u200F', '');
    
    if (_currentLanguage == 'ar') {
      // إصلاح مشكلة عكس النصوص المميزة (bold) في العربية
      text = text.replaceAllMapped(
        RegExp(r'\*\*([^*]+?)\*\*'),
        (match) {
          final content = match.group(1)!.trim();
          // تطبيق علامة اتجاه بسيطة فقط على النص العربي
          if (_containsArabicText(content)) {
            return '**\u200E$content\u200E**';
          } else {
            return '**$content**';
          }
        },
      );
      
      // إصلاح مشكلة الأرقام والنقاط في العربية
      text = text.replaceAllMapped(
        RegExp(r'^\s*(\d+)([.):]|\u060C)\s*(.+)', multiLine: true),
        (match) {
          final number = match.group(1)!;
          final content = match.group(3)!;
          if (_containsArabicText(content)) {
            return '**$number.** \u200E$content\u200E';
          } else {
            return '**$number.** $content';
          }
        },
      );
    } else {
      // تنسيق عادي للإنجليزية - إزالة علامات الاتجاه الزائدة
      text = text.replaceAllMapped(
        RegExp(r'\*\*([^*]+?)\*\*'),
        (match) {
          final content = match.group(1)!.trim();
          // تنظيف شامل من علامات الاتجاه
          final cleanContent = content
              .replaceAll('\u200E', '')
              .replaceAll('\u200F', '')
              .replaceAll('\u202D', '')
              .replaceAll('\u202C', '')
              .replaceAll('\u061C', '');
          return '**$cleanContent**';
        },
      );
      
      text = text.replaceAllMapped(
        RegExp(r'^\s*(\d+)([.):]|\u060C)\s*(.+)', multiLine: true),
        (match) {
          final number = match.group(1)!;
          final content = match.group(3)!;
          // تنظيف المحتوى من علامات الاتجاه
          final cleanContent = content
              .replaceAll('\u200E', '')
              .replaceAll('\u200F', '')
              .replaceAll('\u202D', '')
              .replaceAll('\u202C', '')
              .replaceAll('\u061C', '');
          return '**$number.** $cleanContent';
        },
      );
    }
    
    return text;
  }
  
  /// فحص إذا كان النص يحتوي على أحرف عربية
  bool _containsArabicText(String text) {
    return RegExp(r'[؀-ۿ]').hasMatch(text);
  }

  /// تحسين التدرج البصري والوضوح
  String _enhanceVisualHierarchy(String text) {
    // إضافة خطوط فاصلة بين الأقسام الرئيسية
    text = text.replaceAllMapped(
      RegExp(r'(## 🎯 .+\n)([^#])', multiLine: true),
      (match) => '${match.group(1)}\n${match.group(2)}',
    );

    // تحسين النصوص المهمة
    if (_currentLanguage == 'ar') {
      // للعربية - معالجة خاصة للكلمات المهمة
      text = text.replaceAllMapped(
        RegExp(r'(\b[أ-ي]+(?:\s+[أ-ي]+){0,2}\b)(?=\s*:)'),
        (match) {
          final content = match.group(1)!;
          return '**\u200E$content\u200E**';
        },
      );
    }

    return text;
  }

  /// تحسين تنسيق القوائم والنقاط
  String _improveListFormatting(String text) {
    // معالجة القوائم المرقمة أولاً (لحل مشكلة عدم الترتيب)
    text = text.replaceAllMapped(
      RegExp(r'^\s*(\d+)[.)]\s*([^\n]+(?:\n(?!\s*\d+[.)])[^\n]*)*)', multiLine: true),
      (match) {
        final number = match.group(1)!;
        final content = match.group(2)!.trim();
        return '\n**$number.** $content\n';
      },
    );
    
    if (_currentLanguage == 'ar') {
      // معالجة خاصة للقوائم العربية (النقطية)
      text = text.replaceAllMapped(
        RegExp(r'^\s*[•‣◦\-]\s*(.+)', multiLine: true),
        (match) {
          final content = match.group(1)!.trim();
          // تطبيق اتجاه فقط على النص العربي
          if (_containsArabicText(content)) {
            return '\n• ‎$content‎\n';
          } else {
            return '\n• $content\n';
          }
        },
      );
      
      // معالجة القوائم الفرعية
      text = text.replaceAllMapped(
        RegExp(r'^\s{2,}[•‣◦\-]\s*(.+)', multiLine: true),
        (match) {
          final content = match.group(1)!.trim();
          if (_containsArabicText(content)) {
            return '\n  • ‎$content‎\n';
          } else {
            return '\n  • $content\n';
          }
        },
      );
    } else {
      // تنسيق عادي للإنجليزية - إزالة علامات الاتجاه
      text = text.replaceAllMapped(
        RegExp(r'^\s*[•‣◦\-]\s*(.+)', multiLine: true),
        (match) {
          final content = match.group(1)!.trim();
          // إزالة علامات الاتجاه
          final cleanContent = content
              .replaceAll('\u202D', '')
              .replaceAll('\u202C', '')
              .replaceAll('\u200E', '')
              .replaceAll('\u200F', '');
          return '\n• $cleanContent\n';
        },
      );
      
      // معالجة القوائم الفرعية
      text = text.replaceAllMapped(
        RegExp(r'^\s{2,}[•‣◦\-]\s*(.+)', multiLine: true),
        (match) {
          final content = match.group(1)!.trim();
          final cleanContent = content
              .replaceAll('\u202D', '')
              .replaceAll('\u202C', '')
              .replaceAll('\u200E', '')
              .replaceAll('\u200F', '');
          return '\n  • $cleanContent\n';
        },
      );
    }
    
    return text;
  }

  /// إضافة فواصل بصرية للوضوح
  String _addVisualBreaks(String text) {
    // تنظيف المسافات الزائدة بشكل تدريجي
    text = text.replaceAll(RegExp(r'\n{5,}'), '\n\n\n');
    text = text.replaceAll(RegExp(r'\n{4}'), '\n\n\n');
    text = text.replaceAll(RegExp(r'\n{3}'), '\n\n');

    // إضافة مسافات حول العناوين بشكل أفضل
    text = text.replaceAllMapped(
      RegExp(r'([^\n])\n(## 🎯|### ✨|#### 💡)', multiLine: true),
      (match) => '${match.group(1)}\n\n${match.group(2)}',
    );

    // إضافة مسافة بعد العناوين
    text = text.replaceAllMapped(
      RegExp(r'(## 🎯|### ✨|#### 💡)(.+)\n([^\n])', multiLine: true),
      (match) => '${match.group(1)}${match.group(2)}\n\n${match.group(3)}',
    );

    // إضافة مسافة قبل وبعد الفواصل
    text = text.replaceAll('\n---\n', '\n\n---\n\n');
    text = text.replaceAll('---\n', '---\n\n');

    // تحسين مسافات القوائم المرقمة
    text = text.replaceAllMapped(
      RegExp(r'(\*\*\d+\.\*\* .+)\n([^\n*])', multiLine: true),
      (match) => '${match.group(1)}\n\n${match.group(2)}',
    );

    // إزالة أي مسافات زائدة في النهاية
    text = text.trim();
    
    // ضمان وجود مسافة في النهاية
    if (!text.endsWith('\n')) {
      text += '\n';
    }

    return text;
  }
}

class _SummaryMarkdown extends StatelessWidget {
  final String data;
  final BuildContext context;
  final String languageCode;

  const _SummaryMarkdown({
    required this.data,
    required this.context,
    required this.languageCode,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = languageCode == 'ar';
    final fontFamily = isArabic ? GoogleFonts.cairo : GoogleFonts.inter;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: MarkdownBody(
        data: _enhanceMarkdownForCards(data),
        styleSheet:
            _createAdvancedCardStyleSheet(context, isArabic, fontFamily),
        selectable: true,
      ),
    );
  }

  /// تحسين Markdown خصيصاً للبطاقات مع حل مشاكل التنسيق
  String _enhanceMarkdownForCards(String data) {
    String enhanced = data;
    final isArabic = languageCode == 'ar';

    // إزالة علامات الاتجاه القديمة أولاً لتجنب التشويش
    enhanced = enhanced
        .replaceAll('\u202D', '')
        .replaceAll('\u202C', '')
        .replaceAll('\u200E', '')
        .replaceAll('\u200F', '');

    if (isArabic) {
      // معالجة خاصة للعربية مع إصلاح مشاكل الاتجاه
      enhanced = _fixArabicDirectionality(enhanced);
    }

    // إصلاح القوائم المرقمة لتظهر بشكل مثالي في الملخصات
    // تحسين تعريف من القوائم المرقمة ليشمل جميع الأشكال
    enhanced = enhanced.replaceAllMapped(
      RegExp(r'^\s*(\d+)\s*[\.\)\u060c:\-]\s*(.+?)(?=\n|$)', multiLine: true, dotAll: true),
      (match) {
        final number = match.group(1)!;
        final content = match.group(2)!.trim();
        
        // تنظيف المحتوى من المسافات الزائدة
        final cleanContent = content.replaceAll(RegExp(r'\s+'), ' ').trim();
        
        if (isArabic && _containsArabicText(cleanContent)) {
          return '\n\n**$number.** $cleanContent\n';
        } else {
          return '\n\n**$number.** $cleanContent\n';
        }
      },
    );

    // إصلاح القوائم ذات النقاط مع معالجة الاتجاه
    enhanced = enhanced.replaceAllMapped(
      RegExp(r'^\s*[•‣◦-]\s*(.+)', multiLine: true),
      (match) {
        final content = match.group(1)!.trim();
        if (isArabic && _containsArabicText(content)) {
          return '• \u200E$content\u200E\n\n';
        } else {
          return '• $content\n\n';
        }
      },
    );

    // إصلاح القوائم الفرعية (بأحرف)
    enhanced = enhanced.replaceAllMapped(
      RegExp(r'^\s*([a-z]|[أ-ي])[.):]\s*(.+)', multiLine: true),
      (match) {
        final letter = match.group(1)!;
        final content = match.group(2)!.trim();
        if (isArabic && (_containsArabicText(content) || _containsArabicText(letter))) {
          return '  • **$letter)** \u200E$content\u200E\n\n';
        } else {
          return '  • **$letter)** $content\n\n';
        }
      },
    );

    // تحسين العناوين مع مسافات مثالية
    enhanced = enhanced.replaceAllMapped(
      RegExp(r'^(#{1,6})\s*([^\n]+)', multiLine: true),
      (match) {
        final hashes = match.group(1)!;
        final title = match.group(2)!.trim();
        if (isArabic && _containsArabicText(title)) {
          return '\n\n$hashes \u200E$title\u200E\n\n';
        } else {
          return '\n\n$hashes $title\n\n';
        }
      },
    );

    // تحسين النصوص المميزة بدون إضافة علامات اتجاه مضاعفة
    if (!isArabic) {
      // في الإنجليزية، تأكد من عدم وجود علامات اتجاه داخل النصوص الغامقة
      enhanced = enhanced.replaceAllMapped(
        RegExp(r'\*\*([^*]+)\*\*'),
        (match) {
          final content = match.group(1)!
              .replaceAll('\u202D', '')
              .replaceAll('\u202C', '')
              .replaceAll('\u200E', '')
              .replaceAll('\u200F', '');
          return '**$content**';
        },
      );
    }

    // تنظيف المسافات الزائدة
    enhanced = enhanced.replaceAll(RegExp(r'\n{4,}'), '\n\n\n');

    return enhanced.trim();
  }

  /// دالة مساعدة للتحقق من وجود نص عربي
  bool _containsArabicText(String text) {
    return RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]')
        .hasMatch(text);
  }

  /// إصلاح مشاكل الاتجاه في العربية
  String _fixArabicDirectionality(String text) {
    // إزالة أي علامات قديمة أولاً
    text = text
        .replaceAll('\u202D', '')
        .replaceAll('\u202C', '')
        .replaceAll('\u200E', '')
        .replaceAll('\u200F', '');
    
    // إضافة علامات اتجاه بسيطة فقط للنص العربي
    if (_containsArabicText(text)) {
      // إضافة علامة اتجاه بسيطة فقط في بداية ونهاية النص
      text = '\u200E' + text + '\u200E';
    }
    
    return text;
  }

  /// معالجة خاصة لإصلاح اتجاه النص العربي
  // String _fixArabicDirectionality(String text) {
  //   // إصلاح مشاكل عرض الأرقام والعلامات الإنجليزية في النص العربي
  //   text = text.replaceAllMapped(
  //     RegExp(r'([\d\w\(\)\[\]\{\}]+)'),
  //     (match) {
  //       final content = match.group(1)!;
  //       // تطبيق اتجاه LTR على الأرقام والنصوص الإنجليزية
  //       return '\u202D$content\u202C';
  //     },
  //   );

  //   return text;
  // }

  /// إنشاء StyleSheet متطور خصيصاً للبطاقات
  MarkdownStyleSheet _createAdvancedCardStyleSheet(
      BuildContext context,
      bool isArabic,
      TextStyle Function(
              {Color? color,
              double? fontSize,
              FontWeight? fontWeight,
              double? height,
              double? letterSpacing,
              FontStyle? fontStyle})
          fontFamily) {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return MarkdownStyleSheet(
      // العنوان الرئيسي - قوي ومهيب ومريح للعين
      h1: fontFamily(
        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 26),
        fontWeight: FontWeight.w800,
        color: colorScheme.primary,
        height: 1.2,
        letterSpacing: isArabic ? 0.3 : 0.5,
      ),

      // العناوين الرئيسية - جذابة وواضحة
      h2: fontFamily(
        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 22),
        fontWeight: FontWeight.w700,
        color:
            isDark ? colorScheme.primary.withOpacity(0.9) : colorScheme.primary,
        height: 1.3,
        letterSpacing: isArabic ? 0.2 : 0.3,
      ),

      // العناوين الفرعية - أنيقة ومنظمة
      h3: fontFamily(
        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 19),
        fontWeight: FontWeight.w600,
        color: isDark
            ? colorScheme.secondary.withOpacity(0.9)
            : colorScheme.secondary,
        height: 1.4,
        letterSpacing: isArabic ? 0.15 : 0.2,
      ),

      // عناوين تفصيلية
      h4: fontFamily(
        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 17),
        fontWeight: FontWeight.w600,
        color: isDark
            ? colorScheme.onSurface.withOpacity(0.8)
            : colorScheme.onSurface,
        height: 1.3,
        letterSpacing: isArabic ? 0.1 : 0.15,
      ),

      // النص الأساسي - محسن للقراءة المريحة والجميلة
      p: fontFamily(
        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
        color: colorScheme.onSurface,
        height: isArabic ? 1.8 : 1.6, // مسافة أكبر للعربية
        fontWeight: FontWeight.w400,
        letterSpacing: isArabic ? 0.2 : 0.1,
      ),

      // القوائم - محسنة وجميلة وواضحة
      listBullet: fontFamily(
        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
        color: colorScheme.onSurface,
        height: isArabic ? 1.9 : 1.7, // مسافة إضافية للوضوح والجمال
        fontWeight: FontWeight.w400,
        letterSpacing: isArabic ? 0.15 : 0.08,
      ),

      // القوائم - تنسيق مثالي وجميل
      listBulletPadding: EdgeInsets.only(
        bottom: 12,
        left: isArabic ? 8 : 4,
        right: isArabic ? 4 : 8,
        top: 4,
      ),
      listIndent: isArabic ? 24 : 20, // مسافة بادئة محسنة

      // النصوص المهمة - بارزة وجذابة وجميلة
      strong: fontFamily(
        fontWeight: FontWeight.w700,
        color: isDark ? colorScheme.primary : colorScheme.primary,
        letterSpacing: isArabic ? 0.15 : 0.2,
      ),

      // التأكيد - رشيق وأنيق وجميل
      em: fontFamily(
        fontStyle: FontStyle.italic,
        color: isDark
            ? colorScheme.secondary.withOpacity(0.9)
            : colorScheme.secondary,
        fontWeight: FontWeight.w500,
        letterSpacing: isArabic ? 0.1 : 0.05,
      ),

      // الكوح والمصطلحات - متميزة وجميلة
      code: GoogleFonts.jetBrainsMono(
        backgroundColor: isDark
            ? colorScheme.surfaceContainerHighest.withOpacity(0.4)
            : colorScheme.surfaceContainerHighest.withOpacity(0.7),
        color: isDark ? colorScheme.onSurfaceVariant : colorScheme.primary,
        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
        fontWeight: FontWeight.w600,
      ),

      // الاقتباسات - أنيقة ومميزة وجميلة
      blockquote: fontFamily(
        color: colorScheme.onSurface.withOpacity(0.8),
        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 15),
        fontStyle: FontStyle.italic,
        height: isArabic ? 1.7 : 1.5,
        letterSpacing: isArabic ? 0.1 : 0.05,
      ),

      // الروابط - واضحة وجميلة
      a: fontFamily(
        color: colorScheme.primary,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.05,
      ),

      // الجداول - إذا كانت موجودة
      tableHead: fontFamily(
        fontWeight: FontWeight.w700,
        color: colorScheme.primary,
        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 15),
        letterSpacing: 0.1,
      ),

      tableBody: fontFamily(
        color: colorScheme.onSurface,
        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 15),
        height: 1.5,
        letterSpacing: isArabic ? 0.1 : 0.05,
      ),

      // مسافات محسوبة بدقة وجمال للبطاقات
      h1Padding: EdgeInsets.only(
        top: 24,
        bottom: 20,
        left: isArabic ? 4 : 0,
        right: isArabic ? 0 : 4,
      ),

      h2Padding: EdgeInsets.only(
        top: 28,
        bottom: 16,
        left: isArabic ? 4 : 0,
        right: isArabic ? 0 : 4,
      ),

      h3Padding: EdgeInsets.only(
        top: 22,
        bottom: 12,
        left: isArabic ? 4 : 0,
        right: isArabic ? 0 : 4,
      ),

      h4Padding: EdgeInsets.only(
        top: 18,
        bottom: 10,
        left: isArabic ? 4 : 0,
        right: isArabic ? 0 : 4,
      ),

      h5Padding: const EdgeInsets.only(top: 14, bottom: 8),
      h6Padding: const EdgeInsets.only(top: 12, bottom: 6),

      pPadding: EdgeInsets.only(
        bottom: isArabic ? 16 : 14,
        top: 2,
      ),

      blockquotePadding: EdgeInsets.symmetric(
        vertical: 16,
        horizontal: isArabic ? 20 : 16,
      ),

      codeblockPadding: const EdgeInsets.all(14),
      tablePadding: const EdgeInsets.symmetric(vertical: 16),

      // خط فاصل أنيق وجميل
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withOpacity(0.3),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
