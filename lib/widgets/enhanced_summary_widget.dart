import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaker/utils/responsive_utils.dart';

class EnhancedSummaryWidget extends StatelessWidget {
  final String summary;

  const EnhancedSummaryWidget({
    super.key,
    required this.summary,
  });

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
                        'الملخص التعليمي',
                        style: GoogleFonts.cairo(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 22),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'مُحسَّن للدراسة والمراجعة',
                        style: GoogleFonts.cairo(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: Container(
              padding: ResponsiveUtils.getFlashcardPadding(context),
              child: SingleChildScrollView(
                child: _SummaryMarkdown(
                  data: _formatSummary(summary),
                  context: context,
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
                    'تذكر: راجع الملخص عدة مرات لضمان الفهم الكامل',
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

  const _SummaryMarkdown({
    required this.data,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: data,
      styleSheet: MarkdownStyleSheet(
        // Headers
        h1: GoogleFonts.cairo(
          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 24),
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          height: 1.4,
        ),
        h2: GoogleFonts.cairo(
          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          height: 1.4,
        ),
        h3: GoogleFonts.cairo(
          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 18),
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.secondary,
          height: 1.4,
        ),
        
        // Body text
        p: GoogleFonts.cairo(
          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
          color: Theme.of(context).colorScheme.onSurface,
          height: 1.8,
        ),
        
        // Lists
        listBullet: GoogleFonts.cairo(
          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
          color: Theme.of(context).colorScheme.onSurface,
          height: 1.7,
        ),
        
        // Emphasis
        strong: GoogleFonts.cairo(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
        
        em: GoogleFonts.cairo(
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