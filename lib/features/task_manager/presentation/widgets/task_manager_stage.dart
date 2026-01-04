import 'dart:async';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// A premium, theme-aware skeleton loading stage for the Task Manager.
///
/// This widget handles the transition between initialization and content display
/// with smooth animations, progress-based status messaging, and high-fidelity skeletons.
class TaskManagerStage extends StatefulWidget {
  final bool isLoading;
  final Widget child;

  const TaskManagerStage({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  State<TaskManagerStage> createState() => _TaskManagerStageState();
}

class _TaskManagerStageState extends State<TaskManagerStage> {
  late final ValueNotifier<int> _stageNotifier;
  Timer? _stageTimer;

  final List<String> _statusMessages = [
    "Initializing system",
    "Preparing secure channels",
    "Scanning environment",
    "Finalizing setup",
  ];

  @override
  void initState() {
    super.initState();
    _stageNotifier = ValueNotifier<int>(0);
    _startStageTimer();
  }

  @override
  void didUpdateWidget(TaskManagerStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _stageNotifier.value = 0;
      _startStageTimer();
    } else if (!widget.isLoading) {
      _stageTimer?.cancel();
    }
  }

  void _startStageTimer() {
    _stageTimer?.cancel();
    _stageTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      if (_stageNotifier.value < _statusMessages.length - 1) {
        _stageNotifier.value++;
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _stageTimer?.cancel();
    _stageNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 800),
      switchInCurve: Curves.easeInOutCubic,
      switchOutCurve: Curves.easeInOutCubic,
      child: widget.isLoading ? _buildLoadingState(context) : widget.child,
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        // High-Fidelity Skeletons
        Opacity(
          opacity: 0.7,
          child: CustomScrollView(
            key: const ValueKey('loading_state'),
            physics: const NeverScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(
                child: SizedBox(height: 60),
              ), // Gap for where AppBar usually is
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverToBoxAdapter(
                  child: _TaskManagerSkeleton(theme: theme),
                ),
              ),
            ],
          ),
        ),

        // Status Message Centered
        Align(
          alignment: const Alignment(
            0,
            -0.1,
          ), // Somewhat in center, slightly above middle for focus
          child: ValueListenableBuilder<int>(
            valueListenable: _stageNotifier,
            builder: (context, stageIndex, _) {
              return _StatusMessage(
                message: _statusMessages[stageIndex],
                theme: theme,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatusMessage extends StatelessWidget {
  final String message;
  final ThemeData theme;

  const _StatusMessage({required this.message, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0.0, 0.4),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutBack,
                    ),
                  ),
              child: child,
            ),
          );
        },
        child: Text(
          message.toUpperCase(),
          key: ValueKey(message),
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 3.0,
            color: theme.colorScheme.primary.withOpacity(0.8),
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _TaskManagerSkeleton extends StatelessWidget {
  final ThemeData theme;

  const _TaskManagerSkeleton({required this.theme});

  @override
  Widget build(BuildContext context) {
    final skeletonColor = theme.brightness == Brightness.light
        ? theme.colorScheme.surfaceVariant.withOpacity(0.4)
        : theme.colorScheme.surfaceVariant.withOpacity(0.15);

    final highlightColor = theme.brightness == Brightness.light
        ? theme.colorScheme.surfaceVariant.withOpacity(0.2)
        : theme.colorScheme.surfaceVariant.withOpacity(0.05);

    return Skeletonizer(
      enabled: true,
      effect: ShimmerEffect(
        baseColor: skeletonColor,
        highlightColor: highlightColor,
        duration: const Duration(milliseconds: 2000), // Slower, elegant shimmer
      ),
      containersColor: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // System Stats Card Skeleton
          Container(
            height: 240,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.1),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Search Bar Skeleton
          Container(
            height: 50,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 32),

          // List Header Skeleton
          Row(
            children: [
              Container(
                height: 12,
                width: 120,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Spacer(),
              Container(
                height: 18,
                width: 60,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // List Items Skeletons
          ...List.generate(4, (index) => _buildListItemSkeleton()),
        ],
      ),
    );
  }

  Widget _buildListItemSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        height: 72,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(height: 14, width: 140, color: Colors.white),
                  const SizedBox(height: 6),
                  Container(height: 10, width: 100, color: Colors.white),
                ],
              ),
            ),
            Container(width: 50, height: 12, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
