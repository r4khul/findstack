import 'package:flutter/material.dart';

class OnboardingPageContent extends StatelessWidget {
  final String title;
  final String description;
  final Widget visual;
  final Widget? extraContent;

  const OnboardingPageContent({
    super.key,
    required this.title,
    required this.description,
    required this.visual,
    this.extraContent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 3),
          // Visual with Glow
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withOpacity(0.05),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.05),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: visual,
          ),
          const Spacer(flex: 2),

          // Text Content
          Text(
            title,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -1.0,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              height: 1.5,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          if (extraContent != null) ...[
            const SizedBox(height: 32),
            extraContent!,
          ],
          const Spacer(flex: 4),
        ],
      ),
    );
  }
}
