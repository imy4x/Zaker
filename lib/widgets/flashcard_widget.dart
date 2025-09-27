import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaker/models/flashcard.dart';
import 'package:zaker/utils/responsive_utils.dart';

class FlashcardWidget extends StatefulWidget {
  final List<Flashcard> flashcards;
  const FlashcardWidget({super.key, required this.flashcards});

  @override
  State<FlashcardWidget> createState() => _FlashcardWidgetState();
}

class _FlashcardWidgetState extends State<FlashcardWidget> with TickerProviderStateMixin {
  final CardSwiperController _controller = CardSwiperController();
  int _currentIndex = 0;
  String _currentLanguage = 'ar'; // Default to Arabic
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

  void _navigateToCard(int index) {
    if (index >= 0 && index < widget.flashcards.length) {
      setState(() {
        _currentIndex = index;
      });
    }
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
  
  @override
  Widget build(BuildContext context) {
    if (widget.flashcards.isEmpty) {
      return const Center(child: Text('لم يتم إنشاء بطاقات تعليمية.'));
    }

    return Column(
      children: [
        // Card counter and language toggle
        Container(
          margin: EdgeInsets.only(bottom: ResponsiveUtils.getResponsiveSpacing(context) * 2),
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.getResponsivePadding(context),
            vertical: 12,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                Theme.of(context).colorScheme.secondary.withOpacity(0.08),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Card counter
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentIndex + 1}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'من ${widget.flashcards.length} بطاقة',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              
              // Language toggle button
              AnimatedBuilder(
                animation: _languageToggleAnimation,
                builder: (context, child) {
                  return GestureDetector(
                    onTap: _toggleLanguage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.secondary,
                            Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Transform.rotate(
                            angle: _languageToggleAnimation.value * 3.14159,
                            child: Icon(
                              Icons.translate_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _currentLanguage == 'ar' ? 'English' : 'عربي',
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
            constraints: BoxConstraints(
              maxHeight: ResponsiveUtils.getFlashcardHeight(context),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOut,
                  )),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: _FlashcardContent(
                key: ValueKey('${_currentIndex}_$_currentLanguage'),
                flashcard: widget.flashcards[_currentIndex],
                languageCode: _currentLanguage,
              ),
            ),
          ),
        ),
        // Navigation buttons - moved to center and more prominent
        Container(
          margin: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Previous button
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: _currentIndex > 0
                        ? LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.secondary,
                              Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                            ],
                          )
                        : null,
                    color: _currentIndex == 0 ? Colors.grey.shade300 : null,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _currentIndex > 0
                        ? [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.arrow_back_rounded, size: 24),
                    label: Text(
                      'السابق',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: _currentIndex > 0 ? () => _navigateToCard(_currentIndex - 1) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      foregroundColor: _currentIndex > 0 ? Colors.white : Colors.grey.shade600,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 20),
              
              // Next button
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: _currentIndex < widget.flashcards.length - 1
                        ? LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.primary.withOpacity(0.8),
                            ],
                          )
                        : null,
                    color: _currentIndex == widget.flashcards.length - 1 ? Colors.grey.shade300 : null,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _currentIndex < widget.flashcards.length - 1
                        ? [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.arrow_forward_rounded, size: 24),
                    label: Text(
                      'التالي',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: _currentIndex < widget.flashcards.length - 1 
                        ? () => _navigateToCard(_currentIndex + 1) 
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      foregroundColor: _currentIndex < widget.flashcards.length - 1 
                          ? Colors.white 
                          : Colors.grey.shade600,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FlashcardContent extends StatefulWidget {
  final Flashcard flashcard;
  final String languageCode;
  const _FlashcardContent({super.key, required this.flashcard, required this.languageCode});

  @override
  State<_FlashcardContent> createState() => _FlashcardContentState();
}

// --- تعديل: تم إعادة كتابة آلية القلب بالكامل لتكون أكثر استقراراً ---
class _FlashcardContentState extends State<_FlashcardContent> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  void _flipCard() {
    if (!mounted || _animationController.isAnimating) return;
    if (_animationController.status == AnimationStatus.completed) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flipCard,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          final angle = _animationController.value * pi;
          final isShowingBack = _animationController.value >= 0.5;

          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle);

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: isShowingBack
                ? Transform(
                    transform: Matrix4.identity()..rotateY(pi),
                    alignment: Alignment.center,
                    child: _buildCardSide(
                      label: widget.languageCode == 'en' ? "Answer" : "الإجابة",
                      text: widget.flashcard.getAnswer(widget.languageCode),
                    ),
                  )
                : _buildCardSide(
                    label: widget.languageCode == 'en' ? "Question" : "السؤال",
                    text: widget.flashcard.getQuestion(widget.languageCode),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildCardSide({required String label, required String text}) {
    final isQuestion = label == "السؤال" || label == "Question";
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isQuestion 
              ? [
                  Colors.white,
                  const Color(0xFFF8FAFC),
                ]
              : [
                  const Color(0xFFF0F9FF),
                  const Color(0xFFE0F2FE),
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isQuestion 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
              : Theme.of(context).colorScheme.secondary.withOpacity(0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isQuestion 
                ? Theme.of(context).colorScheme.primary 
                : Theme.of(context).colorScheme.secondary).withOpacity(0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            // Header with label and icon
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isQuestion 
                      ? [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withOpacity(0.8)]
                      : [Theme.of(context).colorScheme.secondary, Theme.of(context).colorScheme.secondary.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: (isQuestion ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isQuestion ? Icons.help_outline_rounded : Icons.lightbulb_outline_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Content area
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: _UnifiedTextWidget(
                    text: text,
                    isAnswer: !isQuestion,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Footer hint
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app_rounded,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.languageCode == 'en' ? "Tap to flip" : "انقر للقلب",
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Unified text widget with consistent formatting for all content
class _UnifiedTextWidget extends StatelessWidget {
  final String text;
  final bool isAnswer;

  const _UnifiedTextWidget({
    required this.text,
    required this.isAnswer,
  });

  @override
  Widget build(BuildContext context) {
    // Clean and normalize the text
    String cleanText = text.trim();
    
    // Check if text contains numbered lists
    if (cleanText.contains(RegExp(r'^\d+[-\.)\s]', multiLine: true))) {
      return _buildNumberedList(context);
    }
    
    // Check if text contains bullet points
    if (cleanText.contains(RegExp(r'^[•\-\*]\s', multiLine: true))) {
      return _buildBulletList(context);
    }
    
    // Regular paragraph text
    return _buildParagraph(context);
  }

  Widget _buildNumberedList(BuildContext context) {
    final lines = text.split('\n').where((line) => line.trim().isNotEmpty).toList();
    final items = <Widget>[];
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final numberedMatch = RegExp(r'^(\d+)[-\.)\s]+(.*)').firstMatch(line);
      
      if (numberedMatch != null) {
        final number = numberedMatch.group(1)!;
        final content = numberedMatch.group(2)!.trim();
        
        items.add(_buildListItem(
          context: context,
          number: number,
          content: content,
          isLast: i == lines.length - 1,
        ));
      } else {
        // Handle non-numbered lines as regular text
        items.add(_buildRegularLine(context, line));
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items,
    );
  }

  Widget _buildBulletList(BuildContext context) {
    final lines = text.split('\n').where((line) => line.trim().isNotEmpty).toList();
    final items = <Widget>[];
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final bulletMatch = RegExp(r'^[•\-\*]\s+(.*)').firstMatch(line);
      
      if (bulletMatch != null) {
        final content = bulletMatch.group(1)!.trim();
        items.add(_buildBulletItem(
          context: context,
          content: content,
          isLast: i == lines.length - 1,
        ));
      } else {
        items.add(_buildRegularLine(context, line));
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items,
    );
  }

  Widget _buildParagraph(BuildContext context) {
    final hasArabic = text.contains(RegExp(r'[\u0600-\u06FF]'));
    final paragraphs = text.split('\n\n').where((p) => p.trim().isNotEmpty).toList();
    
    if (paragraphs.length > 1) {
      return Column(
        children: paragraphs.asMap().entries.map((entry) {
          final index = entry.key;
          final paragraph = entry.value.trim();
          
          return Container(
            margin: EdgeInsets.only(bottom: index < paragraphs.length - 1 ? 16 : 0),
            child: _buildTextBlock(context, paragraph, hasArabic),
          );
        }).toList(),
      );
    }
    
    return _buildTextBlock(context, text, hasArabic);
  }

  Widget _buildTextBlock(BuildContext context, String text, bool hasArabic) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isAnswer 
            ? Theme.of(context).colorScheme.secondary.withOpacity(0.05)
            : Theme.of(context).colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAnswer 
              ? Theme.of(context).colorScheme.secondary.withOpacity(0.2)
              : Theme.of(context).colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface,
          height: 1.8,
          letterSpacing: 0.3,
        ),
        textAlign: TextAlign.center,
        textDirection: hasArabic ? TextDirection.rtl : TextDirection.ltr,
      ),
    );
  }

  Widget _buildListItem({required BuildContext context, required String number, required String content, required bool isLast}) {
    final hasArabic = content.contains(RegExp(r'[\u0600-\u06FF]'));
    
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAnswer 
            ? const Color(0xFFF0F9FF)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAnswer 
              ? Theme.of(context).colorScheme.secondary.withOpacity(0.3)
              : Theme.of(context).colorScheme.primary.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isAnswer 
                ? Theme.of(context).colorScheme.secondary 
                : Theme.of(context).colorScheme.primary).withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: hasArabic ? TextDirection.rtl : TextDirection.ltr,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isAnswer 
                    ? [Theme.of(context).colorScheme.secondary, Theme.of(context).colorScheme.secondary.withOpacity(0.8)]
                    : [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: (isAnswer ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.primary).withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              number,
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                content,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.7,
                  letterSpacing: 0.2,
                ),
                textDirection: hasArabic ? TextDirection.rtl : TextDirection.ltr,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletItem({required BuildContext context, required String content, required bool isLast}) {
    final hasArabic = content.contains(RegExp(r'[\u0600-\u06FF]'));
    
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: hasArabic ? TextDirection.rtl : TextDirection.ltr,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isAnswer 
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              content,
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.7,
              ),
              textDirection: hasArabic ? TextDirection.rtl : TextDirection.ltr,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegularLine(BuildContext context, String line) {
    if (line.trim().isEmpty) return const SizedBox(height: 12);
    
    final hasArabic = line.contains(RegExp(r'[\u0600-\u06FF]'));
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        line,
        style: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface,
          height: 1.7,
        ),
        textAlign: TextAlign.center,
        textDirection: hasArabic ? TextDirection.rtl : TextDirection.ltr,
      ),
    );
  }
}
