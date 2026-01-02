import 'package:flutter/material.dart';
import '../../domain/scan_progress.dart';

class ScanProgressWidget extends StatelessWidget {
  final ScanProgress progress;

  const ScanProgressWidget({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: progress.percent / 100,
                  strokeWidth: 8,
                  backgroundColor: theme.colorScheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "${progress.percent}%",
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            progress.status,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          if (progress.totalCount > 0)
            Text(
              "Analyzed ${progress.processedCount} of ${progress.totalCount} packages",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),

          const SizedBox(height: 24),
          // Terminal like effect for current package
          if (progress.status.startsWith("Scanning"))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                "> ${progress.status.replaceFirst("Scanning ", "")}...",
                style: const TextStyle(
                  fontFamily: 'Courier',
                  color: Colors.greenAccent,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
