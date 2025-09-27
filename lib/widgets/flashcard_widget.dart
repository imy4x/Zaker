import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:zaker/models/flashcard.dart';

class FlashcardWidget extends StatefulWidget {
  final List<Flashcard> flashcards;
  const FlashcardWidget({super.key, required this.flashcards});

  @override
  State<FlashcardWidget> createState() => _FlashcardWidgetState();
}

class _FlashcardWidgetState extends State<FlashcardWidget> {
  final CardSwiperController _controller = CardSwiperController();
  int _currentIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    if (widget.flashcards.isEmpty) {
      return const Center(child: Text('لم يتم إنشاء بطاقات تعليمية.'));
    }

    return Column(
      children: [
        // Card counter
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
          child: CardSwiper(
            controller: _controller,
            cardsCount: widget.flashcards.length,
            cardBuilder: (context, index, h, v) => _FlashcardContent(
              key: ValueKey(widget.flashcards[index].question),
              flashcard: widget.flashcards[index]
            ),
            allowedSwipeDirection: const AllowedSwipeDirection.symmetric(horizontal: true),
            onSwipe: (previousIndex, currentIndex, direction) {
              setState(() {
                _currentIndex = currentIndex ?? 0;
              });
              return true;
            },
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('السابق'),
              onPressed: _currentIndex > 0 ? () {
                _controller.swipe(CardSwiperDirection.left);
                setState(() {
                  _currentIndex = (_currentIndex - 1).clamp(0, widget.flashcards.length - 1);
                });
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.black,
              ),
            ),
             ElevatedButton.icon(
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('التالي'),
              onPressed: _currentIndex < widget.flashcards.length - 1 ? () {
                _controller.swipe(CardSwiperDirection.right);
                setState(() {
                  _currentIndex = (_currentIndex + 1).clamp(0, widget.flashcards.length - 1);
                });
              } : null,
            ),
          ],
        )
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
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: 20,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
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
