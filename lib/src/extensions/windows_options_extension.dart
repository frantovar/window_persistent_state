import 'dart:ui';
import 'package:window_manager/window_manager.dart';

/// Extension methods for WindowOptions
extension WindowOptionsExtension on WindowOptions {
  /// Creates a copy of this WindowOptions with the given fields replaced
  /// with the new values, preserving existing values when null is passed.
  WindowOptions copyWith({
    Size? size,
    bool? center,
    Size? minimumSize,
    Size? maximumSize,
    bool? alwaysOnTop,
    bool? fullScreen,
    Color? backgroundColor,
    bool? skipTaskbar,
    String? title,
    TitleBarStyle? titleBarStyle,
    bool? windowButtonVisibility,
  }) {
    return WindowOptions(
      size: size ?? this.size,
      center: center ?? this.center,
      minimumSize: minimumSize ?? this.minimumSize,
      maximumSize: maximumSize ?? this.maximumSize,
      alwaysOnTop: alwaysOnTop ?? this.alwaysOnTop,
      fullScreen: fullScreen ?? this.fullScreen,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      skipTaskbar: skipTaskbar ?? this.skipTaskbar,
      title: title ?? this.title,
      titleBarStyle: titleBarStyle ?? this.titleBarStyle,
      windowButtonVisibility:
          windowButtonVisibility ?? this.windowButtonVisibility,
    );
  }
}
