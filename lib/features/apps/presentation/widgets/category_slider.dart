import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/device_app.dart';
import '../../../search/presentation/providers/search_provider.dart';

class CategorySlider extends ConsumerWidget {
  final bool isCompact;
  final EdgeInsetsGeometry? contentPadding;

  const CategorySlider({
    super.key,
    this.isCompact = false,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(categoryFilterProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildCategoryChip(
              context,
              ref,
              label: "All Apps",
              category: null,
              isSelected: selectedCategory == null,
            ),
            ...AppCategory.values.where((c) => c != AppCategory.unknown).map((
              cat,
            ) {
              return _buildCategoryChip(
                context,
                ref,
                label: cat.name.toUpperCase(),
                category: cat,
                isSelected: selectedCategory == cat,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required AppCategory? category,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);

    final horizontalPadding = isCompact ? 12.0 : 16.0;
    final verticalPadding = isCompact ? 8.0 : 10.0;
    final borderRadius = isCompact ? 12.0 : 16.0;
    final iconSize = isCompact ? 16.0 : 18.0;
    final fontSize = isCompact ? 11.0 : 13.0;
    final gap = isCompact ? 6.0 : 8.0;

    return Padding(
      padding: EdgeInsets.only(right: isCompact ? 8 : 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ref.read(categoryFilterProvider.notifier).setCategory(category);
          },
          borderRadius: BorderRadius.circular(borderRadius),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary
                  : (theme.brightness == Brightness.dark
                        ? theme.colorScheme.surface
                        : Colors
                              .grey
                              .shade100),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getCategoryIcon(category),
                  size: iconSize,
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                SizedBox(width: gap),
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: fontSize,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(AppCategory? category) {
    if (category == null) return Icons.grid_view_rounded;
    switch (category) {
      case AppCategory.game:
        return Icons.sports_esports_rounded;
      case AppCategory.audio:
        return Icons.headphones_rounded;
      case AppCategory.video:
        return Icons.play_circle_filled_rounded;
      case AppCategory.image:
        return Icons.image_rounded;
      case AppCategory.social:
        return Icons.people_alt_rounded;
      case AppCategory.news:
        return Icons.newspaper_rounded;
      case AppCategory.maps:
        return Icons.map_rounded;
      case AppCategory.productivity:
        return Icons.check_circle_outline_rounded;
      case AppCategory.tools:
        return Icons.build_rounded;
      case AppCategory.unknown:
        return Icons.category_rounded;
    }
  }
}
