import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/device_app.dart';
import 'customizable_share_poster.dart';
import 'share_options_config.dart';

class SharePreviewDialog extends StatefulWidget {
  final DeviceApp app;

  const SharePreviewDialog({super.key, required this.app});

  static Future<void> show(BuildContext context, DeviceApp app) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.7),
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

  late final AnimationController _entranceController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
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

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    try {
      await Future.delayed(const Duration(milliseconds: 100));
      await _waitForFrame();

      final posterContext = _posterKey.currentContext;
      if (posterContext == null) throw Exception("Poster not found");

      final boundary =
          posterContext.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception("Boundary not found");

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
    buffer.writeln("Love open source? Give a ⭐ on GitHub!");
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
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: isDark ? 30 : 15,
            sigmaY: isDark ? 30 : 15,
          ),
          child: Container(
            height: screenHeight * 0.85,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0D0D0D).withOpacity(0.95)
                  : const Color(0xFFF8F8F8).withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.05),
              ),
            ),
            child: Column(
              children: [
                _buildHeader(theme, isDark),

                _buildOptionsRow(theme, isDark),

                Expanded(child: _buildPreviewSection(theme, isDark)),

                _buildShareButton(theme, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Customize & Share",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              _buildThemeToggle(theme, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeToggle(ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () => _updateConfig(
        _config.copyWith(posterDarkMode: !_config.posterDarkMode),
      ),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _config.posterDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.onSurface.withOpacity(0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _config.posterDarkMode
                  ? Icons.dark_mode_rounded
                  : Icons.light_mode_rounded,
              size: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            const SizedBox(width: 6),
            Text(
              _config.posterDarkMode ? "Dark" : "Light",
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsRow(ThemeData theme, bool isDark) {
    final options = <_OptionData>[
      _OptionData(
        "Version",
        Icons.info_outline_rounded,
        _config.showVersion,
        () => _config.copyWith(showVersion: !_config.showVersion),
      ),
      _OptionData(
        "SDK",
        Icons.developer_mode_rounded,
        _config.showSdk,
        () => _config.copyWith(showSdk: !_config.showSdk),
      ),
      _OptionData(
        "Usage",
        Icons.access_time_rounded,
        _config.showUsage,
        () => _config.copyWith(showUsage: !_config.showUsage),
      ),
      _OptionData(
        "Install Date",
        Icons.calendar_today_rounded,
        _config.showInstallDate,
        () => _config.copyWith(showInstallDate: !_config.showInstallDate),
      ),
      _OptionData(
        "Size",
        Icons.storage_rounded,
        _config.showSize,
        () => _config.copyWith(showSize: !_config.showSize),
      ),
      if (widget.app.installerStore != 'Unknown')
        _OptionData(
          "Source",
          Icons.store_rounded,
          _config.showSource,
          () => _config.copyWith(showSource: !_config.showSource),
        ),
      if (widget.app.techVersions.isNotEmpty)
        _OptionData(
          "Tech",
          Icons.code_rounded,
          _config.showTechVersions,
          () => _config.copyWith(showTechVersions: !_config.showTechVersions),
        ),
      _OptionData(
        "Components",
        Icons.widgets_rounded,
        _config.showComponents,
        () => _config.copyWith(showComponents: !_config.showComponents),
      ),
      if (widget.app.splitApks.isNotEmpty)
        _OptionData(
          "Splits",
          Icons.extension_rounded,
          _config.showSplitApks,
          () => _config.copyWith(showSplitApks: !_config.showSplitApks),
        ),
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final opt = options[index];
          return _buildOptionChip(opt, theme, isDark);
        },
      ),
    );
  }

  Widget _buildOptionChip(_OptionData opt, ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () => _updateConfig(opt.toggle()),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: opt.isEnabled
              ? theme.colorScheme.primary.withOpacity(isDark ? 0.2 : 0.1)
              : theme.colorScheme.onSurface.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: opt.isEnabled
                ? theme.colorScheme.primary.withOpacity(0.4)
                : theme.colorScheme.onSurface.withOpacity(0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (opt.isEnabled) ...[
              Icon(
                Icons.check_rounded,
                size: 14,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 4),
            ],
            Icon(
              opt.icon,
              size: 14,
              color: opt.isEnabled
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(width: 6),
            Text(
              opt.label,
              style: TextStyle(
                color: opt.isEnabled
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: 12,
                fontWeight: opt.isEnabled ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection(ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: RepaintBoundary(
                key: _posterKey,
                child: CustomizableSharePoster(
                  app: widget.app,
                  config: _config,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShareButton(ThemeData theme, bool isDark) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
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
                          ? [const Color(0xFFFFFFFF), const Color(0xFFE8E8E8)]
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
                            .withOpacity(0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
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

class _OptionData {
  final String label;
  final IconData icon;
  final bool isEnabled;
  final ShareOptionsConfig Function() toggle;

  const _OptionData(this.label, this.icon, this.isEnabled, this.toggle);
}
