library;

import 'package:flutter/material.dart';

import 'constants.dart';

class TaskManagerSearchBar extends StatelessWidget {
  final TextEditingController controller;

  final ValueChanged<String> onChanged;

  final String searchQuery;

  const TaskManagerSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: TaskManagerSizes.searchBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: TaskManagerSpacing.lg),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? theme.colorScheme.surface
            : Colors.white,
        borderRadius: BorderRadius.circular(TaskManagerBorderRadius.lg),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(
            TaskManagerOpacity.mediumLight,
          ),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(TaskManagerOpacity.verySubtle),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            size: TaskManagerSizes.iconSize,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: TaskManagerSpacing.md),
          Expanded(
            child: TextField(
              controller: controller,
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                hintText: "Search processes...",
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                fillColor: theme.colorScheme.surface,
                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: TaskManagerFontSizes.standard,
              ),
              onChanged: onChanged,
            ),
          ),
          if (searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                onChanged("");
              },
              child: Icon(
                Icons.close,
                size: TaskManagerSizes.iconSize,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
