import 'dart:async';
import 'dart:io' show Platform;
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
  // Listener to handle application-level exit requests
  late final AppLifecycleListener _appLifecycleListener;

  // Debounce timer to avoid excessive saves
  Timer? _debounceTimer;

  // Cache to avoid unnecessary saves
  Rect? _lastSavedRect;

  @override
  void initState() {
    super.initState();

    // Listen to window events to save the state
    windowManager.addListener(this);

    // Listen to application-level exit requests
    _appLifecycleListener = AppLifecycleListener(
      onExitRequested: _onExitRequested,
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  Future<void> onWindowClose() async {
    _debounceTimer?.cancel();

    if (Platform.isMacOS) {
      // Needed to save the window state before when using close button
      await _saveWindowState();
    }
  }

  @override
  void onWindowMove() {
    _scheduleSave();
    super.onWindowMove();
  }

  @override
  void onWindowResize() {
    _scheduleSave();
    super.onWindowResize();
  }

  @override
  void onWindowMaximize() {
    _scheduleSave();
    super.onWindowMaximize();
  }

  @override
  void onWindowUnmaximize() {
    _scheduleSave();
    super.onWindowUnmaximize();
  }

  /// Handles application exit requests (e.g. CMD+Q on macOS)
  Future<AppExitResponse> _onExitRequested() async {
    _debounceTimer?.cancel();
    await _saveWindowState();
    // Return exit to allow the application to close
    return AppExitResponse.exit;
  }

  void _scheduleSave() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 750), _saveWindowState);
  }

  Future<void> _saveWindowState() async {
    try {
      if (!mounted) return;

      final position = await windowManager.getPosition();
      final size = await windowManager.getSize();

      final currentRect = position & size;

      if (_lastSavedRect == currentRect) return;

      final prefs = await SharedPreferences.getInstance();

      if (!mounted) return;

      await saveWindowRect(prefs, widget.preferencesPrefix, position, size);

      _lastSavedRect = currentRect;

      debugPrint('Window state saved: $position, $size');
    } on Exception catch (e) {
      debugPrint('Error saving window state: $e');
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    windowManager.removeListener(this);
    _appLifecycleListener.dispose();
    super.dispose();
  }
}

Future<({Size size, Offset? position, bool shouldCenter})>
_validateWindowBounds({
  required Rect? savedRect,
  required Size standardSize,
}) async {
  final displays = await screenRetriever.getAllDisplays();
  return computeValidatedWindowConfig(
    savedRect: savedRect,
    standardSize: standardSize,

    displays: displays,
  );
}
