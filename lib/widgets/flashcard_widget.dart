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
            cardBuilder: (context, index, horizontalThresholdPercentage, verticalThresholdPercentage) {
              // إضافة مفتاح فريد لإصلاح مشكلة إعادة الاستخدام
              return _FlashcardContent(
                key: ValueKey(widget.flashcards[index].question),
                flashcard: widget.flashcards[index]
              );
            },
            onSwipe: (prev, curr, dir) => true,
            padding: const EdgeInsets.all(24.0),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.indigo, size: 30),
              onPressed: () => _controller.swipe(CardSwiperDirection.left),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward, color: Colors.indigo, size: 30),
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

class _FlashcardContentState extends State<_FlashcardContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  void _flipCard() {
    if (!mounted) return;
    if (_controller.isCompleted) {
      _controller.reverse();
      setState(() => _isFront = true);
    } else {
      _controller.forward();
      setState(() => _isFront = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flipCard,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * pi;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle);
          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: _animation.value > 0.5
                ? _buildCardSide(widget.flashcard.answer, false)
                : _buildCardSide(widget.flashcard.question, true),
          );
        },
      ),
    );
  }

  Widget _buildCardSide(String text, bool isQuestion) {
    return Transform(
      transform: Matrix4.identity()..rotateY(isQuestion ? 0 : pi),
      alignment: Alignment.center,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: isQuestion
                  ? [Colors.indigo.shade400, Colors.indigo.shade600]
                  : [Colors.teal.shade400, Colors.teal.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Text(
                    isQuestion ? 'السؤال' : 'الإجابة',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
