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

class _FlashcardWidgetState extends State<FlashcardWidget> {
  final CardSwiperController _controller = CardSwiperController();
  int _currentIndex = 0;
  
  void _navigateToCard(int index) {
    setState(() {
      _currentIndex = index;
    });
    _controller.moveTo(index);
  }
  
  @override
  Widget build(BuildContext context) {
    if (widget.flashcards.isEmpty) {
      return const Center(child: Text('لم يتم إنشاء بطاقات تعليمية.'));
    }

    return Column(
      children: [
        // Card counter
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
        ),
        Expanded(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: ResponsiveUtils.getFlashcardHeight(context),
            ),
            child: CardSwiper(
              controller: _controller,
              cardsCount: widget.flashcards.length,
              cardBuilder: (context, index, h, v) => _FlashcardContent(
                key: ValueKey(widget.flashcards[index].question),
                flashcard: widget.flashcards[index]
              ),
              allowedSwipeDirection: const AllowedSwipeDirection.none(), // Disable manual swiping
              onSwipe: (previousIndex, currentIndex, direction) {
                setState(() {
                  _currentIndex = currentIndex ?? 0;
                });
                return true;
              },
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
  const _FlashcardContent({super.key, required this.flashcard});

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
                      label: "الإجابة",
                      text: widget.flashcard.answer,
                    ),
                  )
                : _buildCardSide(
                    label: "السؤال",
                    text: widget.flashcard.question,
                  ),
          );
        },
      ),
    );
  }

  Widget _buildCardSide({required String label, required String text}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 13,
                ),
              ),
            ),
            const Spacer(),
            Center(
              child: SingleChildScrollView(
                child: _MixedTextWidget(
                  text: text,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: 20,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ) ?? const TextStyle(),
                ),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                "انقر للقلب",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget to handle mixed Arabic/English text properly
class _MixedTextWidget extends StatelessWidget {
  final String text;
  final TextStyle style;

  const _MixedTextWidget({
    required this.text,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    // Check if text contains both Arabic and English
    final hasArabic = text.contains(RegExp(r'[\u0600-\u06FF]'));
    final hasEnglish = text.contains(RegExp(r'[a-zA-Z]'));

    if (hasArabic && hasEnglish) {
      // Mixed text - use RichText with different fonts
      return _buildMixedText(context);
    } else {
      // Single language text
      return Text(
        text,
        textAlign: TextAlign.center,
        style: style,
        textDirection: hasArabic ? TextDirection.rtl : TextDirection.ltr,
      );
    }
  }

  Widget _buildMixedText(BuildContext context) {
    // Check if text contains numbered lists and format them specially
    if (text.contains(RegExp(r'^\d+[-\.)\s]', multiLine: true))) {
      return _buildFormattedList(context);
    }
    
    final spans = <TextSpan>[];
    final words = text.split(' ');

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final isArabic = word.contains(RegExp(r'[\u0600-\u06FF]'));
      
      spans.add(
        TextSpan(
          text: word,
          style: isArabic
              ? GoogleFonts.cairo(  // Arabic font
                  fontSize: style.fontSize,
                  fontWeight: style.fontWeight,
                  color: style.color,
                  height: 1.4,
                )
              : GoogleFonts.inter(  // English font
                  fontSize: style.fontSize,
                  fontWeight: style.fontWeight,
                  color: style.color,
                  height: 1.2,
                ),
        ),
      );
      
      // Add space between words except for the last word
      if (i < words.length - 1) {
        spans.add(const TextSpan(text: ' '));
      }
    }

    return RichText(
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
      text: TextSpan(children: spans),
    );
  }
  
  Widget _buildFormattedList(BuildContext context) {
    final lines = text.split('\n');
    return Column(
      children: lines.map((line) {
        if (line.trim().isEmpty) return const SizedBox(height: 8);
        
        // Check if it's a numbered item
        final numberedMatch = RegExp(r'^(\d+)[-\.)\s]+(.*)').firstMatch(line.trim());
        if (numberedMatch != null) {
          final number = numberedMatch.group(1)!;
          final content = numberedMatch.group(2)!;
          
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    number,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    content,
                    style: GoogleFonts.cairo(
                      fontSize: style.fontSize,
                      fontWeight: style.fontWeight,
                      color: style.color,
                      height: 1.5,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ],
            ),
          );
        }
        
        // Regular text line
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            line,
            style: style,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
        );
      }).toList(),
    );
  }
}
