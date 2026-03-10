import 'package:flutter_test/flutter_test.dart';
import 'package:window_persistent_state/window_persistent_state.dart';

void main() {
  test('WindowPersistentState can be instantiated', () {
    expect(WindowPersistentState.initializeWindowState, isNotNull);
  });
}
