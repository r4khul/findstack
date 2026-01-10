import 'dart:ui';
import 'package:flutter/material.dart';

class PremiumSliverAppBar extends StatefulWidget {
  final String title;

  final VoidCallback? onResync;

  final VoidCallback? onShare;

  final List<Widget>? actions;

  const PremiumSliverAppBar({
    super.key,
    required this.title,
    this.onResync,
    this.onShare,
    this.actions,
  });

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
    if (!mounted) return;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasResync = widget.onResync != null;
    final hasShare = widget.onShare != null;

    _overlayEntry = OverlayEntry(
      builder: (context) =>
          _buildOverlayMenu(theme, isDark, hasResync, hasShare),
    );

    if (!mounted) {
      _overlayEntry = null;
      return;
    }

    Overlay.of(context).insert(_overlayEntry!);
    _isMenuOpen = true;
    if (mounted) setState(() {});
  }

  Widget _buildOverlayMenu(
    ThemeData theme,
    bool isDark,
    bool hasResync,
    bool hasShare,
  ) {
    return Positioned(
      width: 160,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        offset: const Offset(-120, 45),
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasResync)
                      _OverlayMenuItem(
                        icon: Icons.sync,
                        label: 'Resync App',
                        onTap: () {
                          widget.onResync?.call();
                          _removeOverlay();
                        },
                      ),
                    if (hasResync && hasShare)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: theme.colorScheme.onSurface.withOpacity(0.08),
                      ),
                    if (hasShare)
                      _OverlayMenuItem(
                        icon: Icons.ios_share_rounded,
                        label: 'Share',
                        onTap: () {
                          widget.onShare?.call();
                          _removeOverlay();
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;

    const contentHeight = 46.0;
    const marginV = 8.0;
    final totalHeight = contentHeight + (marginV * 2) + topPadding;

    return SliverAppBar(
      floating: true,
      pinned: true,
      snap: true,
      automaticallyImplyLeading: false,
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
            child: _buildAppBarContent(theme, isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBarContent(ThemeData theme, bool isDark) {
    final canPop = Navigator.canPop(context);
    final hasMenu = widget.onResync != null || widget.onShare != null;
    final hasActions = widget.actions != null && widget.actions!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
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
          if (canPop) _buildBackButton(theme) else _buildLeadingIcon(theme),
          if (canPop) const SizedBox(width: 8),
          Expanded(child: _buildTitle(theme)),
          if (widget.actions != null) ...widget.actions!,
          if (hasMenu) ...[
            const SizedBox(width: 8),
            _buildMenuButton(theme),
          ] else if (canPop && !hasActions) ...[
            const SizedBox(width: 36),
          ],
        ],
      ),
    );
  }

  Widget _buildBackButton(ThemeData theme) {
    return SizedBox(
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
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      ),
    );
  }

  Widget _buildLeadingIcon(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 12),
      child: Icon(
        Icons.layers_outlined,
        color: theme.colorScheme.primary,
        size: 20,
      ),
    );
  }

  Widget _buildTitle(ThemeData theme) {
    return Text(
      widget.title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: theme.colorScheme.onSurface,
      ),
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMenuButton(ThemeData theme) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: SizedBox(
        width: 36,
        height: 36,
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(
            _isMenuOpen ? Icons.close_rounded : Icons.more_vert_rounded,
            color: theme.colorScheme.onSurface,
            size: 22,
          ),
          onPressed: _toggleMenu,
          tooltip: 'Menu',
        ),
      ),
    );
  }
}

class _OverlayMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OverlayMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withOpacity(0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
