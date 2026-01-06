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

    // Using a more intentional layout structure
    // Bias towards optical center, not mathematical center
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            // Visual
            visual,
            const SizedBox(
              height: 48,
            ), // Intentional gap between visual and text
            // Typography Group
            Text(
              title,
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
                height: 1.1,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                height: 1.5,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),

            if (extraContent != null) ...[
              const SizedBox(height: 48), // Separator for supporting content
              extraContent!,
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
