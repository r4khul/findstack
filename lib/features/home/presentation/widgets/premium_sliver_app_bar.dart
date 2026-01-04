import 'dart:ui';
import 'package:flutter/material.dart';

class PremiumSliverAppBar extends StatefulWidget {
  final String title;
  final VoidCallback? onResync;

  const PremiumSliverAppBar({super.key, required this.title, this.onResync});

  @override
  State<PremiumSliverAppBar> createState() => _PremiumSliverAppBarState();
}

class _PremiumSliverAppBarState extends State<PremiumSliverAppBar> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  bool _isMenuOpen = false;

  @override
  void dispose() {
    _removeOverlay(fromDispose: true);
    super.dispose();
  }

  void _removeOverlay({bool fromDispose = false}) {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isMenuOpen = false;
    if (!fromDispose && mounted) setState(() {});
  }

  void _toggleMenu() {
    if (_isMenuOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    // Don't create overlay if widget is already disposed
    if (!mounted) return;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: 160,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            // Align top-right of menu to bottom-right of button
            offset: const Offset(-120, 45),
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  // Glass/Premium styling
                  color: isDark
                      ? const Color(0xFF1A1A1A).withOpacity(0.92)
                      : const Color(0xFFF0F0F0).withOpacity(0.92),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: InkWell(
                      onTap: () {
                        widget.onResync?.call();
                        _removeOverlay();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(
                                  0.1,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.sync,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Resync App",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.9),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    // Double-check we're still mounted before inserting overlay
    if (!mounted) {
      _overlayEntry = null;
      return;
    }

    Overlay.of(context).insert(_overlayEntry!);
    _isMenuOpen = true;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;

    // Compact height settings
    const contentHeight = 46.0;
    const marginV = 8.0;
    final totalHeight = contentHeight + (marginV * 2) + topPadding;

    return SliverAppBar(
      floating: true,
      pinned: true,
      snap: true,
      automaticallyImplyLeading:
          false, // Removes the redundant default back button
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: totalHeight,
      collapsedHeight: totalHeight,
      expandedHeight: totalHeight,
      flexibleSpace: Container(
        margin: EdgeInsets.only(
          top: marginV + topPadding,
          left: 16,
          right: 16,
          bottom: marginV,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                // Greyish tint with transparency for legibility
                color: isDark
                    ? Colors.grey[900]!.withOpacity(0.65)
                    : Colors.grey[100]!.withOpacity(0.65),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.onSurface.withOpacity(0.08),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (Navigator.canPop(context))
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          size: 20,
                          color: theme.colorScheme.onSurface,
                        ),
                        onPressed: () => Navigator.pop(context),
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).backButtonTooltip,
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(left: 8, right: 12),
                      child: Icon(
                        Icons.layers_outlined,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),

                  if (Navigator.canPop(context)) const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center, // Center the text
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  if (widget.onResync != null) ...[
                    const SizedBox(width: 8),
                    CompositedTransformTarget(
                      link: _layerLink,
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            _isMenuOpen
                                ? Icons.close_rounded
                                : Icons.more_vert_rounded,
                            color: theme.colorScheme.onSurface,
                            size: 22,
                          ),
                          onPressed: _toggleMenu,
                          tooltip: "Menu",
                        ),
                      ),
                    ),
                  ] else if (Navigator.canPop(context)) ...[
                    const SizedBox(width: 36), // Balance the leading icon width
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
