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
    
    _initializeLanguage();
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
  
  Future<void> _initializeLanguage() async {
    await _languageService.initialize();
    _updateAnimationForCurrentLanguage();
  }
  
  void _onLanguageChanged(String newLanguage) {
    setState(() {});
    _updateAnimationForCurrentLanguage();
  }
  
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius:
            BorderRadius.circular(ResponsiveUtils.getCardBorderRadius(context)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
         border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
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
                  child: const Icon(
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
                              child: const Icon(
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

          Expanded(
            child: Container(
              padding: ResponsiveUtils.getFlashcardPadding(context),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
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

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                        ? 'Tip: Review the summary multiple times to solidify your understanding.'
                        : 'نصيحة: راجع الملخص عدة مرات لترسيخ فهمك للمادة.',
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

  // --- نظام معالجة وتنسيق الملخص المتقدم ---

  /// الدالة الرئيسية التي تدير عملية التنسيق خطوة بخطوة
  String _formatSummary(String originalSummary) {
    if (originalSummary.trim().isEmpty) {
      return _currentLanguage == 'ar'
          ? 'لا يتوفر محتوى للعرض.'
          : 'No content available.';
    }

    String formatted = originalSummary;

    // سلسلة من عمليات التنظيف والتنسيق
    formatted = _preCleanText(formatted);
    formatted = _handleJsonLikeContent(formatted);
    formatted = _standardizeHeadings(formatted);
    formatted = _standardizeLists(formatted);
    formatted = _fixDirectionalityIssues(formatted);
    formatted = _addVisualBreaks(formatted);

    return formatted.trim();
  }

  /// الخطوة 1: التنظيف الأولي للنص
  String _preCleanText(String text) {
    String cleaned = text.trim();
    // إزالة أغلفة الماركداون أو JSON
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(cleaned.indexOf('\n') + 1);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    return cleaned.trim();
  }

  /// الخطوة 2: معالجة التنسيقات غير القياسية مثل JSON
  String _handleJsonLikeContent(String text) {
    text = text.replaceAllMapped(
        RegExp(r'"title"\s*:\s*"([^"]+)"', multiLine: true),
        (match) => '\n## ${match.group(1)!.trim()}\n');
    text = text.replaceAllMapped(
        RegExp(r'"content"\s*:\s*"([^"]+)"', multiLine: true),
        (match) => '\n${match.group(1)!.trim()}\n');
    return text;
  }

  /// الخطوة 3: ضمان أن العناوين مكتوبة بشكل صحيح
  String _standardizeHeadings(String text) {
    // إضافة مسافة بعد علامات # إذا كانت مفقودة (مثل #العنوان)
    return text.replaceAllMapped(
        RegExp(r'^\s*(#+)([^\s#].*)', multiLine: true),
        (match) => '${match.group(1)} ${match.group(2)}');
  }

  /// الخطوة 4: توحيد شكل القوائم النقطية والرقمية
  String _standardizeLists(String text) {
    // توحيد علامات القائمة النقطية إلى "-"
    text = text.replaceAllMapped(RegExp(r'^\s*[\*\-]\s+(.*)', multiLine: true),
        (match) => '- ${match.group(1)!.trim()}');
    // توحيد القوائم الرقمية (مثل 1. أو 1))
    text = text.replaceAllMapped(
        RegExp(r'^\s*(\d+)[\.\)]\s+(.*)', multiLine: true),
        (match) => '${match.group(1)}. ${match.group(2)!.trim()}');
    return text;
  }

  /// الخطوة 5: إصلاح مشاكل اتجاه النص في اللغة العربية (الأهم)
  String _fixDirectionalityIssues(String text) {
    if (_currentLanguage != 'ar') {
      return text; // تطبيق الإصلاحات فقط عند عرض اللغة العربية
    }

    // إصلاح النصوص السميكة **...** بإضافة علامات Unicode للاتجاه
    text = text.replaceAllMapped(RegExp(r'\*\*([^\*]+)\*\*'), (match) {
      final content = match.group(1)!;
      // الرمز U+200F (Right-to-Left Mark) يجبر النص على العرض من اليمين لليسار
      return '**\u200F$content\u200F**';
    });

    // إصلاح القوائم التي تحتوي على نصوص عربية
    text = text.replaceAllMapped(RegExp(r'^\s*([\-\d\.]+\s+)(.*)', multiLine: true),
        (match) {
      final marker = match.group(1)!;
      final content = match.group(2)!;
      if (_containsArabicText(content)) {
        return '$marker\u200F$content\u200F';
      }
      return match.group(0)!; // إرجاع السطر الأصلي إذا لم يكن عربيًا
    });

    return text;
  }

  /// الخطوة 6: إضافة فواصل ومسافات لتحسين القراءة
  String _addVisualBreaks(String text) {
    // إضافة مسافة قبل العناوين
    text = text.replaceAllMapped(
        RegExp(r'([^\n])\n(#+\s)', multiLine: true),
        (match) => '${match.group(1)}\n\n${match.group(2)}');
    // إضافة مسافة بعد العناوين
    text = text.replaceAllMapped(
        RegExp(r'(#+\s.*)\n([^\n])', multiLine: true),
        (match) => '${match.group(1)}\n\n${match.group(2)}');
    // إضافة مسافة حول الاقتباسات
    text = text.replaceAllMapped(
        RegExp(r'([^\n])\n(>\s)', multiLine: true),
        (match) => '${match.group(1)}\n\n${match.group(2)}');
    // إزالة الأسطر الفارغة الزائدة
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text;
  }

  /// دالة مساعدة للتحقق من وجود أحرف عربية في النص
  bool _containsArabicText(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
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
        data: data,
        styleSheet:
            _createAdvancedCardStyleSheet(context, isArabic, fontFamily),
        selectable: true,
      ),
    );
  }

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

    return MarkdownStyleSheet(
      h1: fontFamily(
        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 26),
        fontWeight: FontWeight.w800,
        color: colorScheme.primary,
      ),
      h2: fontFamily(
        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 22),
        fontWeight: FontWeight.w700,
        color: colorScheme.primary,
      ),
      h3: fontFamily(
        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 19),
        fontWeight: FontWeight.w600,
        color: colorScheme.secondary,
      ),
      h4: fontFamily(
        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 17),
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      p: fontFamily(
        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
        color: colorScheme.onSurface,
        height: isArabic ? 1.8 : 1.6,
      ),
      listBullet: fontFamily(
        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
        color: colorScheme.onSurface,
        height: isArabic ? 1.9 : 1.7,
      ),
      listBulletPadding: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
      strong: fontFamily(
        fontWeight: FontWeight.w700,
        color: colorScheme.primary,
      ),
      em: fontFamily(
        fontStyle: FontStyle.italic,
        color: colorScheme.secondary,
        fontWeight: FontWeight.w500,
      ),
      code: GoogleFonts.jetBrainsMono(
        backgroundColor: colorScheme.surfaceContainerHighest,
        color: colorScheme.onSurfaceVariant,
        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
      ),
      blockquoteDecoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: colorScheme.tertiary,
            width: 4,
          ),
        ),
      ),
      blockquote: fontFamily(
        color: colorScheme.onTertiaryContainer,
        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 15),
        fontStyle: FontStyle.italic,
        height: 1.6,
      ),
      a: fontFamily(
        color: colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
      h1Padding: const EdgeInsets.only(top: 24, bottom: 20),
      h2Padding: const EdgeInsets.only(top: 28, bottom: 16),
      h3Padding: const EdgeInsets.only(top: 22, bottom: 12),
      h4Padding: const EdgeInsets.only(top: 18, bottom: 10),
      pPadding: const EdgeInsets.only(bottom: 14, top: 2),
      blockquotePadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      codeblockPadding: const EdgeInsets.all(14),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withOpacity(0.5),
            width: 2,
          ),
        ),
      ),
    );
  }
}

