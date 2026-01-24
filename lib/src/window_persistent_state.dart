import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:window_persistent_state/src/window_state_logic.dart';

/// {@template window_persistent_state}
/// Persists the window's position and size into shared preferences
/// {@endtemplate}
class WindowPersistentState extends StatefulWidget {
  /// {@macro window_persistent_state}
  const WindowPersistentState({
    required this.child,
    this.preferencesPrefix,
    super.key,
  });

  /// The child widget to be wrapped by the PersistentWindowManager.
  final Widget child;

  /// The prefix to use for the SharedPreferences keys.
  /// If null, the default prefix will be used.
  final String? preferencesPrefix;

  /// Initializes and restores window state from SharedPreferences.
  /// Call this before [runApp] in main.
  static Future<void> initializeWindowState({
    bool center = true,
    Size defaultSize = const Size(1280, 720),
    String? preferencesPrefix,
    Size? minSize,
    WindowOptions? windowOptionsForWin,
    WindowOptions? windowOptionsForMac,
    WindowOptions? windowOptionsForLinux,
  }) async {
    await windowManager.ensureInitialized();

    final prefs = await SharedPreferences.getInstance();
    final standardSize = defaultSize;

    // Retrieve saved rectangle from preferences
    final savedRect = getSavedRect(prefs, preferencesPrefix);

    // Calculate final position and size based on screen availability
    final windowConfig = await _validateWindowBounds(
      savedRect: savedRect,
      standardSize: standardSize,
      forceCenter: center,
    );

    // Apply configuration and show window
    await showWindow(
      size: windowConfig.size,
      position: windowConfig.position,
      center: windowConfig.shouldCenter,
      windowOptionsForWindows: windowOptionsForWin,
      windowOptionsForMac: windowOptionsForMac,
      windowOptionsForLinux: windowOptionsForLinux,
      minSize: minSize,
    );
  }

  @override
  State<WindowPersistentState> createState() => _WindowPersistentStateState();
}

class _WindowPersistentStateState extends State<WindowPersistentState>
    with WindowListener {
  late final AppLifecycleListener _appLifecycleListener;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    // Prevent default close to handle "X" button manually
    unawaited(windowManager.setPreventClose(true));

    // Listen to application-level exit requests (CMD+Q on macOS)
    _appLifecycleListener = AppLifecycleListener(
      onExitRequested: _onExitRequested,
    );
  }

  @override
  void dispose() {
    _appLifecycleListener.dispose();
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _saveWindowState() async {
    try {
      final position = await windowManager.getPosition();
      final size = await windowManager.getSize();
      final prefs = await SharedPreferences.getInstance();
      await saveWindowRect(prefs, widget.preferencesPrefix, position, size);
      debugPrint('Window state saved: $position, $size');
    } on Exception catch (e) {
      debugPrint('Error saving window state: $e');
    }
  }

  /// Handles application exit requests (e.g. CMD+Q on macOS)
  Future<AppExitResponse> _onExitRequested() async {
    await _saveWindowState();
    // Return exit to allow the application to close
    return AppExitResponse.exit;
  }

  @override
  Future<void> onWindowClose() async {
    // Handles the "X" button on the window
    await _saveWindowState();
    await windowManager.destroy();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

Future<({Size size, Offset? position, bool shouldCenter})>
_validateWindowBounds({
  required Rect? savedRect,
  required Size standardSize,
  required bool forceCenter,
}) async {
  final displays = await screenRetriever.getAllDisplays();
  return computeValidatedWindowConfig(
    savedRect: savedRect,
    standardSize: standardSize,
    forceCenter: forceCenter,
    displays: displays,
  );
}
