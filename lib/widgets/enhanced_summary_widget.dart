import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
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
  }) : summaryAr = summary,
       summaryEn = summary;

  @override
  State<EnhancedSummaryWidget> createState() => _EnhancedSummaryWidgetState();
}

class _EnhancedSummaryWidgetState extends State<EnhancedSummaryWidget> with SingleTickerProviderStateMixin {
  String _currentLanguage = 'ar';
  late AnimationController _languageToggleController;
  late Animation<double> _languageToggleAnimation;

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
  }

  @override
  void dispose() {
    _languageToggleController.dispose();
    super.dispose();
  }

  void _toggleLanguage() {
    setState(() {
      _currentLanguage = _currentLanguage == 'ar' ? 'en' : 'ar';
    });
    
    if (_currentLanguage == 'en') {
      _languageToggleController.forward();
    } else {
      _languageToggleController.reverse();
    }
  }

  String get _currentSummary => _currentLanguage == 'en' ? widget.summaryEn : widget.summaryAr;

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
        borderRadius: BorderRadius.circular(ResponsiveUtils.getCardBorderRadius(context)),
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
                topLeft: Radius.circular(ResponsiveUtils.getCardBorderRadius(context)),
                topRight: Radius.circular(ResponsiveUtils.getCardBorderRadius(context)),
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
                        _currentLanguage == 'en' ? 'Study Summary' : 'الملخص التعليمي',
                        style: GoogleFonts.cairo(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 22),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentLanguage == 'en' ? 'Enhanced for studying and review' : 'مُحسَّن للدراسة والمراجعة',
                        style: GoogleFonts.cairo(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
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
                bottomLeft: Radius.circular(ResponsiveUtils.getCardBorderRadius(context)),
                bottomRight: Radius.circular(ResponsiveUtils.getCardBorderRadius(context)),
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
    // Enhanced formatting for better readability
    String formatted = originalSummary;
    
    // Add special formatting for better visual hierarchy
    formatted = formatted.replaceAllMapped(
      RegExp(r'^##\s+(.+)$', multiLine: true),
      (match) => '\n\n## 📚 ${match.group(1)}\n',
    );
    
    formatted = formatted.replaceAllMapped(
      RegExp(r'^###\s+(.+)$', multiLine: true),
      (match) => '\n### ✨ ${match.group(1)}\n',
    );
    
    // Enhanced bullet points
    formatted = formatted.replaceAllMapped(
      RegExp(r'^-\s+(.+)$', multiLine: true),
      (match) => '• ${match.group(1)}',
    );
    
    // Number formatting
    formatted = formatted.replaceAllMapped(
      RegExp(r'^(\d+)[-\.\)]\s+(.+)$', multiLine: true),
      (match) => '**${match.group(1)}.** ${match.group(2)}',
    );
    
    // Bold key terms (words that are likely important concepts)
    formatted = formatted.replaceAllMapped(
      RegExp(r'\b([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)\b'),
      (match) => '**${match.group(1)}**',
    );
    
    return formatted;
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
    
    return MarkdownBody(
      data: data,
      styleSheet: MarkdownStyleSheet(
        // Headers
        h1: fontFamily(
          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 24),
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          height: 1.4,
        ),
        h2: fontFamily(
          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          height: 1.4,
        ),
        h3: fontFamily(
          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 18),
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.secondary,
          height: 1.4,
        ),
        
        // Body text
        p: fontFamily(
          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
          color: Theme.of(context).colorScheme.onSurface,
          height: 1.8,
        ),
        
        // Lists
        listBullet: fontFamily(
          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
          color: Theme.of(context).colorScheme.onSurface,
          height: 1.7,
        ),
        
        // Emphasis
        strong: fontFamily(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
        
        em: fontFamily(
          fontStyle: FontStyle.italic,
          color: Theme.of(context).colorScheme.secondary,
        ),
        
        // Code (for highlighting key terms)
        code: GoogleFonts.jetBrainsMono(
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
        ),
        
        // Spacing
        h1Padding: const EdgeInsets.symmetric(vertical: 16),
        h2Padding: const EdgeInsets.symmetric(vertical: 12),
        h3Padding: const EdgeInsets.symmetric(vertical: 8),
        pPadding: const EdgeInsets.symmetric(vertical: 4),
        listBulletPadding: const EdgeInsets.symmetric(vertical: 2),
      ),
      selectable: true,
    );
  }
}