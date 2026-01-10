import 'package:flutter/material.dart';

import '../../../apps/domain/entities/device_app.dart';

class AnalyticsAppIcon extends StatelessWidget {
  final DeviceApp app;

  final double size;

  final bool addBorder;

  const AnalyticsAppIcon({
    super.key,
    required this.app,
    required this.size,
    this.addBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: addBorder ? Border.all(color: Colors.white, width: 1.5) : null,
        boxShadow: addBorder
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: app.icon != null
            ? Image.memory(
                app.icon!,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.android, size: 16),
              )
            : const Icon(Icons.android, size: 16),
      ),
    );
  }
}
