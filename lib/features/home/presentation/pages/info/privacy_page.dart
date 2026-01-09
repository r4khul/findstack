import 'package:flutter/material.dart';
import '../../widgets/external_link_tile.dart';
import '../../widgets/premium_sliver_app_bar.dart';
import '../../widgets/github_cta_card.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const PremiumSliverAppBar(title: "Privacy Policy"),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Your Data,\nYour Device",
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "We believe privacy is a fundamental right. UnFilter is designed from the ground up to be offline-first and respectful of your data.",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                      height: 1.6,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const ExternalLinkTile(
                    label: "Detailed Policy",
                    value: "Check Here",
                    url: "https://github.com/r4khul/unfilter",
                  ),
                  const SizedBox(height: 48),

                  // Policy Sections
                  _buildPolicySection(
                    context,
                    title: "Local Processing",
                    content:
                        "All app analysis, scanning, and signature matching happens directly on your device. We do not (and cannot) see your apps or data.",
                    icon: Icons.phonelink_lock_rounded,
                  ),
                  _buildPolicySection(
                    context,
                    title: "Minimal Permissions",
                    content:
                        "We only request permissions strictly necessary for functionality: querying packages to list apps and storage access for deep native scanning.",
                    icon: Icons.verified_user_rounded,
                  ),
                  _buildPolicySection(
                    context,
                    title: "No Tracking",
                    content:
                        "UnFilter contains zero analytics trackers, ad SDKs, or crash reporters. Your usage habits remain private.",
                    icon: Icons.do_not_disturb_on_rounded,
                  ),
                  _buildPolicySection(
                    context,
                    title: "Limited Networking",
                    content:
                        "The app only connects to the internet to check for software updates and to fetch the GitHub star count. No user data is transmitted.",
                    icon: Icons.wifi_rounded,
                  ),

                  const SizedBox(height: 20),
                  const GithubCtaCard(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicySection(
    BuildContext context, {
    required String title,
    required String content,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.2),
              ),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
