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
  
  @override
  Widget build(BuildContext context) {
    if (widget.flashcards.isEmpty) {
      return const Center(child: Text('لم يتم إنشاء بطاقات تعليمية.'));
    }

    return Column(
      children: [
        Expanded(
          child: CardSwiper(
            controller: _controller,
            cardsCount: widget.flashcards.length,
            cardBuilder: (context, index, h, v) => _FlashcardContent(
              key: ValueKey(widget.flashcards[index].question),
              flashcard: widget.flashcards[index]
            ),
            allowedSwipeDirection: const AllowedSwipeDirection.symmetric(horizontal: true),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('السابق'),
              onPressed: () => _controller.swipe(CardSwiperDirection.left),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.black,
              ),
            ),
             ElevatedButton.icon(
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('التالي'),
              onPressed: () => _controller.swipe(CardSwiperDirection.right),
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
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              label, 
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor
              )
            ),
            const Spacer(),
            Center(
              child: SingleChildScrollView(
                child: Text(text, textAlign: TextAlign.center, style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 22)),
              ),
            ),
            const Spacer(),
            Text(
              "انقر للقلب",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
            )
          ],
        ),
      ),
    );
  }
}
