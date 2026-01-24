# Window Persistent State

[![License: MIT][license_badge]][license_link]
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
![Status](https://img.shields.io/badge/status-beta-orange)

A Flutter desktop package that persists and restores the window's position and size across app sessions.

Works on:
- **Windows**.
- **macOS** (See ⚠️  [Note on macOS Startup](#note-on-macos-startup)).
- **Linux** (Not tested yet).


## Features

- ✅ Persists window state using [shared_preferences][shared_preferences_link].
- ✅ Restores window state on launch via [window_manager][window_manager_link].
- ✅ Multi-monitor support: Uses [screen_retriever][screen_retriever_link] to detect out-of-bounds or hidden windows, automatically resetting them to default.

## Usage

1. **Initialize** `WindowPersistentState.initializeWindowState` before **runApp**.
2. **Wrap** your **MaterialApp** with a `WindowPersistentState`. 


## Example

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Call to restore the window position before showing the app
  // and optionally pass custom configurations for the window
  await WindowPersistentState.initializeWindowState(
    defaultSize: const Size(1280, 720),
    minSize: const Size(800, 600),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Wrap the MaterialApp with the WindowPersistentState widget
    return WindowPersistentState(
      child: MaterialApp(
        title: 'Window Persistent State Example',
        home: const MyHomePage(),
      ),
    );
  }
}
```

Refer to the [example][example_link] to see the usage of `WindowPersistentState`.

## Note on macOS Startup

On macOS, you might notice two visual glitches during startup:
1.  **Black Screen:** A brief flash of black background while Flutter initializes the rendering engine.
2.  **Position Jump:** The window momentarily appears at the default system position before jumping to its restored coordinates. This happens because `window_manager` needs a few milliseconds to apply the saved position after the window is created.

This is a known behavior in Flutter desktop apps.

### ✅ Recommended Solution: Native Fade-In

To completely hide these artifacts, we recommend implementing a **native fade-in effect**. By starting the window with `alpha: 0` (transparent) and gently animating it to visible **after** the position has been restored, the user never sees the "jump" or the black screen.

See our [MainFlutterWindow.swift][main_flutter_window_link] example for a smooth, drop-in implementation of this fix.

## Roadmap

- [ ] Tests: Unit and Widget tests are currently missing.
- [ ] Linux: Feedback on Linux support is needed.


[shared_preferences_link]: https://pub.dev/packages/shared_preferences
[window_manager_link]: https://pub.dev/packages/window_manager
[screen_retriever_link]: https://pub.dev/packages/screen_retriever
[example_link]: example/lib/main.dart
[main_flutter_window_link]: example/macos/Runner/MainFlutterWindow.swift
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
