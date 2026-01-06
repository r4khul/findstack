import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/device_app.dart';
import 'customizable_share_poster.dart';
import 'share_options_config.dart';

/// A premium share preview dialog with real-time customization.
/// Features butter-smooth animations, glassmorphism, and advanced optimizations.
class SharePreviewDialog extends StatefulWidget {
  final DeviceApp app;

  const SharePreviewDialog({super.key, required this.app});

  /// Shows the dialog with a smooth slide-up animation
  static Future<void> show(BuildContext context, DeviceApp app) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      enableDrag: true,
      useSafeArea: true,
      builder: (context) => SharePreviewDialog(app: app),
    );
  }

  @override
  State<SharePreviewDialog> createState() => _SharePreviewDialogState();
}

class _SharePreviewDialogState extends State<SharePreviewDialog>
    with SingleTickerProviderStateMixin {
  final GlobalKey _posterKey = GlobalKey();

  ShareOptionsConfig _config = const ShareOptionsConfig();
  bool _isSharing = false;

  // Animation controller for entrance animation
  late final AnimationController _entranceController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  void _updateConfig(ShareOptionsConfig newConfig) {
    if (_config != newConfig) {
      setState(() => _config = newConfig);
    }
  }

  Future<void> _handleShare() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    // Capture navigator before async gap
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    try {
      // Wait for render
      await Future.delayed(const Duration(milliseconds: 100));
      await _waitForFrame();

      final posterContext = _posterKey.currentContext;
      if (posterContext == null) throw Exception("Poster not found");

      final boundary =
          posterContext.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception("Boundary not found");

      // Additional frame waits for safety
      for (int i = 0; i < 3; i++) {
        await _waitForFrame();
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) throw Exception("Failed to encode image");

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/unfilter_custom_${widget.app.packageName.hashCode}_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(pngBytes);

      if (mounted) navigator.pop();

      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: _buildShareText()),
      );
    } catch (e) {
      debugPrint("Share error: $e");
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text("Failed to share: ${e.toString()}"),
            backgroundColor: errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _waitForFrame() async {
    await WidgetsBinding.instance.endOfFrame;
  }

  String _buildShareText() {
    final buffer = StringBuffer();
    buffer.writeln("${widget.app.appName} exposed by Unfilter 🔍");
    buffer.writeln();
    buffer.writeln("Built with: ${widget.app.stack}");

    if (_config.showVersion) {
      buffer.writeln("Version: ${widget.app.version}");
    }
    if (_config.showSize) {
      buffer.writeln("Size on device: ${_formatBytes(widget.app.size)}");
    }

    buffer.writeln();
    buffer.writeln("See what YOUR apps are really made of →");
    buffer.writeln("https://github.com/r4khul/unfilter/releases/latest");
    buffer.writeln();
    buffer.writeln("#UnfilterApp #TheRealTruthOfApps");

    return buffer.toString();
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    if (bytes < 1024 * 1024 * 1024) {
      return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
    }
    return "${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            alignment: Alignment.bottomCenter,
            child: child,
          ),
        );
      },
      child: Container(
        height: screenHeight * 0.88,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F8F8),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            // Drag Handle
            _buildDragHandle(theme),

            // Header
            _buildHeader(theme, isDark),

            // Preview Section (Scrollable)
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    // Live Preview
                    _buildPreviewSection(theme, isDark),
                    const SizedBox(height: 24),
                    // Options Grid
                    _buildOptionsSection(theme, isDark),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Share Button
            _buildShareButton(theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withOpacity(0.2),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.close_rounded,
                size: 20,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Customize Share",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "${_config.enabledCount} details selected",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Label
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.visibility_rounded,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "LIVE PREVIEW",
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Preview Container with shadow
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Scaled Preview
                Transform.scale(
                  scale: 0.85,
                  alignment: Alignment.topCenter,
                  child: RepaintBoundary(
                    key: _posterKey,
                    child: CustomizableSharePoster(
                      app: widget.app,
                      config: _config,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Label
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            "INCLUDE IN IMAGE",
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),

        // Options Grid - Responsive Wrap
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _OptionChip(
              label: "Version",
              icon: Icons.info_outline_rounded,
              isEnabled: _config.showVersion,
              onToggle: () => _updateConfig(
                _config.copyWith(showVersion: !_config.showVersion),
              ),
              theme: theme,
              isDark: isDark,
            ),
            _OptionChip(
              label: "SDK Range",
              icon: Icons.developer_mode_rounded,
              isEnabled: _config.showSdk,
              onToggle: () =>
                  _updateConfig(_config.copyWith(showSdk: !_config.showSdk)),
              theme: theme,
              isDark: isDark,
            ),
            _OptionChip(
              label: "Usage Time",
              icon: Icons.access_time_rounded,
              isEnabled: _config.showUsage,
              onToggle: () => _updateConfig(
                _config.copyWith(showUsage: !_config.showUsage),
              ),
              theme: theme,
              isDark: isDark,
            ),
            _OptionChip(
              label: "Install Date",
              icon: Icons.calendar_today_rounded,
              isEnabled: _config.showInstallDate,
              onToggle: () => _updateConfig(
                _config.copyWith(showInstallDate: !_config.showInstallDate),
              ),
              theme: theme,
              isDark: isDark,
            ),
            _OptionChip(
              label: "App Size",
              icon: Icons.storage_rounded,
              isEnabled: _config.showSize,
              onToggle: () =>
                  _updateConfig(_config.copyWith(showSize: !_config.showSize)),
              theme: theme,
              isDark: isDark,
            ),
            if (widget.app.installerStore != 'Unknown')
              _OptionChip(
                label: "Source",
                icon: Icons.store_rounded,
                isEnabled: _config.showSource,
                onToggle: () => _updateConfig(
                  _config.copyWith(showSource: !_config.showSource),
                ),
                theme: theme,
                isDark: isDark,
              ),
            if (widget.app.techVersions.isNotEmpty)
              _OptionChip(
                label: "Tech Versions",
                icon: Icons.code_rounded,
                isEnabled: _config.showTechVersions,
                onToggle: () => _updateConfig(
                  _config.copyWith(showTechVersions: !_config.showTechVersions),
                ),
                theme: theme,
                isDark: isDark,
              ),
            _OptionChip(
              label: "Components",
              icon: Icons.widgets_rounded,
              isEnabled: _config.showComponents,
              onToggle: () => _updateConfig(
                _config.copyWith(showComponents: !_config.showComponents),
              ),
              theme: theme,
              isDark: isDark,
            ),
            if (widget.app.splitApks.isNotEmpty)
              _OptionChip(
                label: "Split APKs",
                icon: Icons.extension_rounded,
                isEnabled: _config.showSplitApks,
                onToggle: () => _updateConfig(
                  _config.copyWith(showSplitApks: !_config.showSplitApks),
                ),
                theme: theme,
                isDark: isDark,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildShareButton(ThemeData theme, bool isDark) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: GestureDetector(
          onTap: _isSharing ? null : _handleShare,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: _isSharing
                  ? null
                  : LinearGradient(
                      colors: isDark
                          ? [const Color(0xFFFFFFFF), const Color(0xFFE0E0E0)]
                          : [const Color(0xFF1A1A1A), const Color(0xFF000000)],
                    ),
              color: _isSharing
                  ? theme.colorScheme.onSurface.withOpacity(0.1)
                  : null,
              borderRadius: BorderRadius.circular(16),
              boxShadow: _isSharing
                  ? null
                  : [
                      BoxShadow(
                        color: (isDark ? Colors.white : Colors.black)
                            .withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: Center(
              child: _isSharing
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: theme.colorScheme.onSurface,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.ios_share_rounded,
                          size: 20,
                          color: isDark ? Colors.black : Colors.white,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Share Image",
                          style: TextStyle(
                            color: isDark ? Colors.black : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Individual option chip with smooth toggle animation
class _OptionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isEnabled;
  final VoidCallback onToggle;
  final ThemeData theme;
  final bool isDark;

  const _OptionChip({
    required this.label,
    required this.icon,
    required this.isEnabled,
    required this.onToggle,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isEnabled
              ? theme.colorScheme.primary.withOpacity(isDark ? 0.15 : 0.08)
              : theme.colorScheme.onSurface.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEnabled
                ? theme.colorScheme.primary.withOpacity(0.3)
                : theme.colorScheme.onSurface.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated check indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isEnabled ? 18 : 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: isEnabled ? 1.0 : 0.0,
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            Icon(
              icon,
              size: 16,
              color: isEnabled
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isEnabled
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: 13,
                fontWeight: isEnabled ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
