import 'package:flutter/material.dart';

class OnboardingPageContent extends StatelessWidget {
  final String title;
  final String description;
  final Widget visual;
  final Widget? extraContent;
  final bool isBrandTitle;

  const OnboardingPageContent({
    super.key,
    required this.title,
    required this.description,
    required this.visual,
    this.extraContent,
    this.isBrandTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 32,
      ), // Increased padding for focus
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 3),
          // Visual
          Container(
            // Removed generic glow/shadow/container decoration
            // Keeping it clean and focused
            child: visual,
          ),
          const Spacer(flex: 2),

          // Text Content
          Text(
            title,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight:
                  FontWeight.w600, // Reduced from w900/w800 for elegance
              letterSpacing: -1.0,
              height: 1.1,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(
                0.6,
              ), // Softer contrast
              height: 1.5,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          if (extraContent != null) ...[
            const SizedBox(height: 48), // More whitespace
            extraContent!,
          ],
          const Spacer(flex: 4),
        ],
      ),
    );
  }
}
