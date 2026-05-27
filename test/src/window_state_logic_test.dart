import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_persistent_state/src/window_state_logic.dart';

void main() {
  group('getSavedRect', () {
    test('returns null when no window keys are stored', () async {
      SharedPreferences.setMockInitialValues({});

      final prefs = await SharedPreferences.getInstance();
      final rect = getSavedRect(prefs, null);

      expect(rect, isNull);
    });

    test('returns null when only some keys are stored', () async {
      SharedPreferences.setMockInitialValues({
        kPrefWindowX: 10.0,
        kPrefWindowY: 20.0,
      });

      final prefs = await SharedPreferences.getInstance();
      final rect = getSavedRect(prefs, null);

      expect(rect, isNull);
    });

    test('returns Rect when all keys are stored', () async {
      SharedPreferences.setMockInitialValues({
        kPrefWindowX: 10.0,
        kPrefWindowY: 20.0,
        kPrefWindowWidth: 300.0,
        kPrefWindowHeight: 400.0,
      });

      final prefs = await SharedPreferences.getInstance();
      final rect = getSavedRect(prefs, null);

      expect(rect, isNotNull);
      expect(rect!.left, 10.0);
      expect(rect.top, 20.0);
      expect(rect.width, 300.0);
      expect(rect.height, 400.0);
    });

    test(
      'returns rect when all keys are stored with a prefix',
      () async {
        const prefix = 'myapp';
        SharedPreferences.setMockInitialValues({
          '${prefix}_$kPrefWindowX': 1.0,
          '${prefix}_$kPrefWindowY': 2.0,
          '${prefix}_$kPrefWindowWidth': 100.0,
          '${prefix}_$kPrefWindowHeight': 200.0,
        });

        final prefs = await SharedPreferences.getInstance();
        final rect = getSavedRect(prefs, prefix);

        expect(rect, isNotNull);
        expect(rect!.left, 1.0);
        expect(rect.top, 2.0);
        expect(rect.width, 100.0);
        expect(rect.height, 200.0);
      },
    );
  });

  group('saveWindowRect', () {
    test('writes values readable by getSavedRect', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      const position = Offset(10, 20);
      const size = Size(300, 400);
      await saveWindowRect(prefs, null, position, size);

      final rect = getSavedRect(prefs, null);

      expect(rect, isNotNull);
      expect(rect!.left, position.dx);
      expect(rect.top, position.dy);
      expect(rect.width, size.width);
      expect(rect.height, size.height);
    });

    test('writes values readable by getSavedRect with a prefix', () async {
      const prefix = 'myapp';
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      const position = Offset(10, 20);
      const size = Size(300, 400);
      await saveWindowRect(prefs, prefix, position, size);

      final rect = getSavedRect(prefs, prefix);

      expect(rect, isNotNull);
      expect(rect!.left, position.dx);
      expect(rect.top, position.dy);
      expect(rect.width, size.width);
      expect(rect.height, size.height);
    });
  });

  group('computeValidatedWindowConfig', () {
    const standardSize = Size(1280, 720);

    const regularDisplay = Display(
      id: 'primary',
      size: Size(1920, 1080),
      visiblePosition: Offset.zero,
    );

    group('when savedRect is null', () {
      test(
        'uses standard size and centers the window',
        () {
          final result = computeValidatedWindowConfig(
            savedRect: null,
            standardSize: standardSize,
            displays: const [regularDisplay],
          );

          expect(result.size, standardSize);
          expect(result.position, isNull);
          expect(result.shouldCenter, isTrue);
        },
      );
    });

    group('when saved rect is valid', () {
      test('restores saved rect when fully visible on a display', () {
        const saved = Rect.fromLTWH(100, 100, 800, 600);

        final result = computeValidatedWindowConfig(
          savedRect: saved,
          standardSize: standardSize,
          displays: const [regularDisplay],
        );

        expect(result.size, saved.size);
        expect(result.position, saved.topLeft);
        expect(result.shouldCenter, isFalse);
      });
    });

    group('when saved rect is invalid', () {
      test('falls back when saved rect center is not on any display', () {
        // Saved center is (2900, 400), outside a 1920x1080 display.
        // Simulates a window that was on a disconnected external monitor.
        const saved = Rect.fromLTWH(2500, 100, 800, 600);

        final result = computeValidatedWindowConfig(
          savedRect: saved,
          standardSize: standardSize,
          displays: const [regularDisplay],
        );

        expect(result.size, standardSize);
        expect(result.position, isNull);
        expect(result.shouldCenter, isTrue);
      });

      test('falls back when saved rect is mostly off-screen', () {
        // Center (200, 400) is on-screen, but only 75%
        // of the window area is visible.
        const saved = Rect.fromLTWH(-200, 100, 800, 600);

        final result = computeValidatedWindowConfig(
          savedRect: saved,
          standardSize: standardSize,
          displays: const [regularDisplay],
        );

        expect(result.size, standardSize);
        expect(result.position, isNull);
        expect(result.shouldCenter, isTrue);
      });
    });
  });
}
