# 0.2.0

### Breaking changes
- Removed the `center` parameter from `WindowPersistentState.initializeWindowState`.
  Window placement is now automatic based on saved bounds validation.

### Added
- Unit tests for window state logic.

### Changed
- Documented startup window placement behavior.
- Updated the README with the new behavior.


# 0.1.3

* feat: saving the state when the window is resized, moved, maximized, etc...

# 0.1.2

* fix: using onWindowClose just in macOS to save the state with close button.

# 0.1.1

* fix: use AppLifecycleListener to prevent windows crash on exit.

# 0.1.0 

* Initial release.
* Features:
  * Persist and restore window position and size.
  * Multi-monitor support with bounds detection.
  * Static initialization API.