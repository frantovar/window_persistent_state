import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:screen_retriever/screen_retriever.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:window_persistent_state/src/extensions/extensions.dart';

/// The key for the window's x position in SharedPreferences.
const String kPrefWindowX = 'window_x';

/// The key for the window's y position in SharedPreferences.
const String kPrefWindowY = 'window_y';

/// The key for the window's width in SharedPreferences.
const String kPrefWindowWidth = 'window_width';

/// The key for the window's height in SharedPreferences.
const String kPrefWindowHeight = 'window_height';

/// Returns the SharedPreferences key for the given [key] and [prefix].
String _prefsKey(String key, String? prefix) =>
    prefix != null ? '${prefix}_$key' : key;

/// Retrieves the saved window [Rect] from SharedPreferences
Rect? getSavedRect(SharedPreferences prefs, String? prefix) {
  final x = prefs.getDouble(_prefsKey(kPrefWindowX, prefix));
  final y = prefs.getDouble(_prefsKey(kPrefWindowY, prefix));
  final w = prefs.getDouble(_prefsKey(kPrefWindowWidth, prefix));
  final h = prefs.getDouble(_prefsKey(kPrefWindowHeight, prefix));

  if (x != null && y != null && w != null && h != null) {
    return Rect.fromLTWH(x, y, w, h);
  }
  return null;
}

/// Writes the window [position] and [size] into [prefs]
Future<void> saveWindowRect(
  SharedPreferences prefs,
  String? prefix,
  Offset position,
  Size size,
) async {
  await prefs.setDouble(_prefsKey(kPrefWindowX, prefix), position.dx);
  await prefs.setDouble(_prefsKey(kPrefWindowY, prefix), position.dy);
  await prefs.setDouble(_prefsKey(kPrefWindowWidth, prefix), size.width);
  await prefs.setDouble(_prefsKey(kPrefWindowHeight, prefix), size.height);
}

/// Given [displays], computes size, position and shouldCenter.
({Size size, Offset? position, bool shouldCenter})
computeValidatedWindowConfig({
  required Rect? savedRect,
  required Size standardSize,
  required List<Display> displays,
}) {
  var finalSize = standardSize;
  Offset? finalPosition;
  var shouldCenter = true;

  if (savedRect == null) {
    return (size: finalSize, position: finalPosition, shouldCenter: true);
  }

  Display? targetDisplay;

  // Find the display that contains the center of the saved window
  for (final display in displays) {
    final displayRect = Rect.fromLTWH(
      display.visiblePosition?.dx ?? 0,
      display.visiblePosition?.dy ?? 0,
      display.size.width,
      display.size.height,
    );

    if (displayRect.contains(savedRect.center)) {
      targetDisplay = display;
      break;
    }
  }

  if (targetDisplay != null) {
    final screenRect = Rect.fromLTWH(
      targetDisplay.visiblePosition?.dx ?? 0,
      targetDisplay.visiblePosition?.dy ?? 0,
      targetDisplay.size.width,
      targetDisplay.size.height,
    );

    // Calculate intersection to determine visibility percentage
    final intersection = savedRect.intersect(screenRect);

    if (intersection.width > 0 && intersection.height > 0) {
      final savedArea = savedRect.width * savedRect.height;
      final visibleArea = intersection.width * intersection.height;
      final visibilityRatio = visibleArea / savedArea;

      // Tolerance threshold: if more than 85% is visible, accept the position
      // This handles OS borders (negative coordinates)
      // and rejects oversized windows
      if (visibilityRatio > 0.85) {
        finalSize = savedRect.size;
        finalPosition = savedRect.topLeft;
        shouldCenter = false;
      } else {
        debugPrint(
          'Window partially hidden (visibilityRatio: $visibilityRatio).',
        );
        finalSize = standardSize;
        shouldCenter = true;
      }
    } else {
      // No intersection
      shouldCenter = true;
    }
  } else {
    // Target display not found (e.g. monitor disconnected)
    debugPrint('Original display not found. Resetting to main display.');
    shouldCenter = true;
  }

  return (size: finalSize, position: finalPosition, shouldCenter: shouldCenter);
}

/// Configures and shows the window
Future<void> showWindow({
  required Size size,
  required Offset? position,
  required bool center,
  required WindowOptions? windowOptionsForWindows,
  required WindowOptions? windowOptionsForMac,
  required WindowOptions? windowOptionsForLinux,
  Size? minSize,
}) async {
  final defaultMacOptions = getDefaultWindowOptions(
    size: size,
    center: center,
    targetWindowOptions: windowOptionsForMac,
  );

  final defaultLinuxOptions = getDefaultWindowOptions(
    size: size,
    center: center,
    targetWindowOptions: windowOptionsForLinux,
  );

  final defaultWinOptions = getDefaultWindowOptions(
    size: size,
    center: center,
    targetWindowOptions: windowOptionsForWindows,
  );

  final windowOptions = selectWindowOptionsForPlatform(
    win: defaultWinOptions,
    mac: defaultMacOptions,
    linux: defaultLinuxOptions,
    isWindows: Platform.isWindows,
    isMacOS: Platform.isMacOS,
    isLinux: Platform.isLinux,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    if (position != null && !center) {
      await windowManager.setPosition(position);
    }
    await windowManager.show();
    await windowManager.focus();
    if (minSize != null) {
      await windowManager.setMinimumSize(minSize);
    }
  });
}

/// Returns the default window options for the given platform.
WindowOptions getDefaultWindowOptions({
  required Size size,
  required bool center,
  required WindowOptions? targetWindowOptions,
}) {
  return targetWindowOptions?.copyWith(size: size, center: center) ??
      WindowOptions(size: size, center: center);
}

/// Chooses Win/Mac/Linux [WindowOptions] based on platform flags.
/// When no flag is true, returns [win] as fallback.
WindowOptions selectWindowOptionsForPlatform({
  required WindowOptions win,
  required WindowOptions mac,
  required WindowOptions linux,
  required bool isWindows,
  required bool isMacOS,
  required bool isLinux,
}) {
  if (isWindows) return win;
  if (isMacOS) return mac;
  if (isLinux) return linux;
  return win;
}
