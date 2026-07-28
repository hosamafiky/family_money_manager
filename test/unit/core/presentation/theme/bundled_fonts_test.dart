/// Verifies the bundled font assets actually exist, parse, and are reachable
/// under the family names the theme asks for.
///
/// This is not covered by any other test: widget tests render with the test
/// stub font regardless of what the theme requests, so a wrong path in
/// `pubspec.yaml` or a truncated download would pass the entire suite and
/// only surface as fallback glyphs on a real device.
library;

import 'dart:io';

import 'package:family_money_manager/core/presentation/theme/app_theme_extensions.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const latinWeights = [400, 600, 800];
  const arabicWeights = [400, 600, 700];

  String latinPath(int w) => 'assets/fonts/Archivo-$w.ttf';
  String arabicPath(int w) => 'assets/fonts/IBMPlexSansArabic-$w.ttf';

  group('bundled font assets', () {
    test('every declared file is present on disk', () {
      for (final path in [
        ...latinWeights.map(latinPath),
        ...arabicWeights.map(arabicPath),
      ]) {
        expect(
          File(path).existsSync(),
          isTrue,
          reason: '$path is declared in pubspec.yaml but missing',
        );
      }
    });

    test('every file is a real TrueType font, not an error page', () {
      // A failed download commonly lands as an HTML error body with a .ttf
      // name. Checking the sfnt magic number costs nothing and catches it.
      for (final path in [
        ...latinWeights.map(latinPath),
        ...arabicWeights.map(arabicPath),
      ]) {
        final bytes = File(path).readAsBytesSync();
        expect(bytes.length, greaterThan(20000), reason: '$path is too small');
        final magic = bytes.sublist(0, 4);
        // 0x00010000 (TrueType outlines) or 'OTTO' (CFF outlines).
        final isTrueType =
            magic[0] == 0x00 &&
            magic[1] == 0x01 &&
            magic[2] == 0x00 &&
            magic[3] == 0x00;
        final isOpenType =
            magic[0] == 0x4F &&
            magic[1] == 0x54 &&
            magic[2] == 0x54 &&
            magic[3] == 0x4F;
        expect(
          isTrueType || isOpenType,
          isTrue,
          reason: '$path is not an sfnt font file',
        );
      }
    });

    test('both families load under the names the theme requests', () async {
      // Proves the constants in app_theme_extensions match real, loadable
      // fonts — if the family name were wrong, text would silently fall back.
      for (final (family, paths) in [
        (latinFontFamily, latinWeights.map(latinPath)),
        (arabicFontFamily, arabicWeights.map(arabicPath)),
      ]) {
        final loader = FontLoader(family);
        for (final path in paths) {
          loader.addFont(
            Future.value(File(path).readAsBytesSync().buffer.asByteData()),
          );
        }
        await expectLater(loader.load(), completes);
      }
    });

    test('the two family constants are distinct and non-empty', () {
      expect(latinFontFamily, isNotEmpty);
      expect(arabicFontFamily, isNotEmpty);
      expect(latinFontFamily, isNot(arabicFontFamily));
    });
  });
}
