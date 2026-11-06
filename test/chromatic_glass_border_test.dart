import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clipit/features/auth/auth_theme.dart';
import 'package:clipit/features/auth/widgets/auth_text_field.dart';
import 'package:clipit/features/auth/widgets/chromatic_glass_border.dart';

/// Behavior tests for the Apple-style chromatic-aberration glass edge.
///
/// The user asked for "a glass ui like apple with chromatic aberration
/// filter". Compiling proves nothing about whether the fringes actually
/// paint, so this renders the painter to a real image, decodes its pixels,
/// and checks the three strokes the design promises:
///
///   * a RED-dominant fringe along the LEFT edge,
///   * a CYAN-dominant fringe along the RIGHT edge,
///   * a NEUTRAL (white) hairline along the top edge.
///
/// That is the "lens dispersion" effect: red on one side, cyan on the
/// other, white hairline on top.
void main() {
  // Picture → Image needs the engine binding to exist, even in a plain test.
  TestWidgetsFlutterBinding.ensureInitialized();

  /// The surface being edged (an auth text field, roughly).
  const Size surface = Size(200, 40);

  /// Raster margin. The fringes are shifted OUTWARD by 0.7 px, so painting
  /// straight into a tight canvas clips each one in half (the picture is
  /// cropped to its own bounds). Rendering into a larger canvas reproduces
  /// what really happens on screen, where the 0.7 px overhang simply paints
  /// over whatever sits behind the field.
  const int margin = 4;
  final Size imageSize = Size(
    surface.width + margin * 2,
    surface.height + margin * 2,
  );

  /// Column bands that isolate each fringe from the others.
  ///
  /// Geometry (margin = 4): the path's left edge is at x = 4.5, so the red
  /// fringe (shifted 0.7 left) is centered at 3.8 and covers columns 3–4,
  /// while the cyan fringe (shifted right) covers 4–5. Sampling columns
  /// 0–4 therefore sees red. Mirrored on the right: cyan is centered at
  /// 204.2 (columns 204–205) and red at 202.8 (202–203), so sampling
  /// 204–207 sees cyan only.
  ///
  /// Rows are kept inside the straight part of the rounded rect (y 10–30 in
  /// surface coordinates) so the corner arcs cannot skew the reading.
  final Rect leftBand = Rect.fromLTWH(
    0,
    (margin + 12).toDouble(),
    (margin + 1).toDouble(),
    (surface.height - 24).toDouble(),
  );
  final Rect rightBand = Rect.fromLTWH(
    (margin + surface.width).toDouble(),
    (margin + 12).toDouble(),
    margin.toDouble(),
    (surface.height - 24).toDouble(),
  );

  /// Renders the painter and returns the decoded RGBA bytes.
  Future<ByteData> renderBorder() async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    // Offset by the margin so the fringes have room outside the surface.
    canvas.save();
    canvas.translate(margin.toDouble(), margin.toDouble());

    const ChromaticGlassBorderPainter painter = ChromaticGlassBorderPainter(
      radius: 10,
      borderColorTop: AuthColors.fieldGlassBorderTop,
      borderColorBottom: AuthColors.fieldGlassBorderBottom,
    );
    painter.paint(canvas, surface);
    canvas.restore();

    final ui.Picture picture = recorder.endRecording();
    // toImageSync (NOT the async toImage) rasterizes synchronously: the
    // async version never completes inside flutter_test's fake-async zone,
    // which hangs the whole run.
    final ui.Image image = picture.toImageSync(
      imageSize.width.toInt(),
      imageSize.height.toInt(),
    );
    final ByteData? bytes = await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    image.dispose();
    expect(bytes, isNotNull, reason: 'Failed to read the painted pixels.');
    return bytes!;
  }

  /// Byte offset of pixel (x, y) in rawRgba data.
  int offsetOf(int x, int y) => (y * imageSize.width.toInt() + x) * 4;

  /// Strongest red dominance (r - max(g, b)) inside a column band.
  int strongestRedDominance(ByteData data, Rect band) {
    int best = -255;
    for (int y = band.top.toInt(); y < band.bottom.toInt(); y++) {
      for (int x = band.left.toInt(); x < band.right.toInt(); x++) {
        final int o = offsetOf(x, y);
        final int r = data.getUint8(o);
        final int g = data.getUint8(o + 1);
        final int b = data.getUint8(o + 2);
        final int dominance = r - (g > b ? g : b);
        if (dominance > best) best = dominance;
      }
    }
    return best;
  }

  /// Strongest blue/cyan dominance (b - max(r, g)) inside a column band.
  int strongestBlueDominance(ByteData data, Rect band) {
    int best = -255;
    for (int y = band.top.toInt(); y < band.bottom.toInt(); y++) {
      for (int x = band.left.toInt(); x < band.right.toInt(); x++) {
        final int o = offsetOf(x, y);
        final int r = data.getUint8(o);
        final int g = data.getUint8(o + 1);
        final int b = data.getUint8(o + 2);
        final int dominance = b - (r > g ? r : g);
        if (dominance > best) best = dominance;
      }
    }
    return best;
  }

  test('glass border: red and cyan fringes flank a neutral hairline', () async {
    final ByteData data = await renderBorder();

    // ── Red fringe on the LEFT edge ─────────────────────────────────────
    final int leftRed = strongestRedDominance(data, leftBand);
    expect(
      leftRed,
      greaterThan(15),
      reason: 'Expected a red-dominant chromatic fringe on the left edge, '
          'but the strongest red dominance there was only $leftRed.',
    );

    // ── Cyan fringe on the RIGHT edge ───────────────────────────────────
    // The threshold is lower than the red one on purpose: cyan is
    // intrinsically less "dominant" because its green channel (#D2) sits
    // close to its blue channel (#FF). Its expected value works out to
    // about (1.0 - 0.82) * 0.30 * 255 ≈ 14 at full coverage.
    final int rightCyan = strongestBlueDominance(data, rightBand);
    expect(
      rightCyan,
      greaterThan(4),
      reason: 'Expected a cyan-dominant chromatic fringe on the right edge, '
          'but the strongest blue dominance there was only $rightCyan.',
    );

    // The effect must be DISPERSION — each edge dominated by ITS color,
    // not the same color smeared on both sides.
    expect(
      strongestBlueDominance(data, leftBand),
      lessThan(leftRed),
      reason: 'The left edge should be red-dominant, not blue-dominant.',
    );
    expect(
      strongestRedDominance(data, rightBand),
      lessThan(rightCyan),
      reason: 'The right edge should be cyan-dominant, not red-dominant.',
    );

    // ── The neutral hairline is still painted ──────────────────────────
    // Sample the top edge in the middle of the surface, where the vertical
    // gradient hairline is at full strength: it must be color-neutral
    // (r ≈ g ≈ b, i.e. white), otherwise the fringes would have swallowed
    // the crisp edge. A 1px stroke centered on the path spans a single row
    // plus antialiasing, so scan a small window and take the strongest
    // pixel rather than betting on one exact row.
    int bestSum = 0;
    int bestSpread = 255 * 3;
    for (int y = margin; y <= margin + 1; y++) {
      for (int x = margin + surface.width ~/ 2 - 2;
          x <= margin + surface.width ~/ 2 + 2;
          x++) {
        final int o = offsetOf(x, y);
        final int r = data.getUint8(o);
        final int g = data.getUint8(o + 1);
        final int b = data.getUint8(o + 2);
        final int sum = r + g + b;
        if (sum > bestSum) {
          bestSum = sum;
          bestSpread = (r - g).abs() + (g - b).abs() + (r - b).abs();
        }
      }
    }
    expect(
      bestSum,
      greaterThan(30),
      reason: 'No hairline was painted at the top edge.',
    );
    expect(
      bestSpread,
      lessThan(45),
      reason: 'The hairline should be neutral white (r≈g≈b), but the '
          'brightest pixel had a channel spread of $bestSpread.',
    );
  });

  test('glass border: repaints only when its style changes', () {
    // Guards the painter against a shouldRepaint that always returns true
    // (which would re-run the effect on every frame of a static screen).
    const ChromaticGlassBorderPainter a = ChromaticGlassBorderPainter(
      radius: 10,
      borderColorTop: AuthColors.fieldGlassBorderTop,
      borderColorBottom: AuthColors.fieldGlassBorderBottom,
    );
    const ChromaticGlassBorderPainter same = ChromaticGlassBorderPainter(
      radius: 10,
      borderColorTop: AuthColors.fieldGlassBorderTop,
      borderColorBottom: AuthColors.fieldGlassBorderBottom,
    );
    const ChromaticGlassBorderPainter different = ChromaticGlassBorderPainter(
      radius: 10,
      // The focus state swaps the hairline to the accent color.
      borderColorTop: AuthColors.fieldGlassBorderFocus,
      borderColorBottom: AuthColors.fieldGlassBorderBottom,
    );

    expect(a.shouldRepaint(same), isFalse);
    expect(a.shouldRepaint(different), isTrue);
  });

  testWidgets('text field: uses the chromatic glass edge, not a bordered box',
      (tester) async {
    // The old field drew its chrome with BoxDecoration.border on top of a
    // flat fill — the "layered grey box" the user rejected. It must now
    // paint its edge through the aberration painter, with no border on the
    // decoration at all.
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: AuthTextFieldHarness(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Finder field = find.byType(AuthTextFieldHarness);
    expect(field, findsOneWidget);

    // The surface must have a gradient fill (one layer) and NO border.
    // NB: AnimatedContainer does NOT extend Container (it is an
    // ImplicitlyAnimatedWidget that builds one internally), so it has to be
    // read as AnimatedContainer.
    final AnimatedContainer surface = tester.widget<AnimatedContainer>(
      find
          .descendant(of: field, matching: find.byType(AnimatedContainer))
          .first,
    );
    final BoxDecoration decoration = surface.decoration! as BoxDecoration;
    expect(
      decoration.border,
      isNull,
      reason: 'The field must not use a BoxDecoration border any more.',
    );
    expect(
      decoration.gradient,
      isA<LinearGradient>(),
      reason: 'The fill should be a single gradient (glass surface).',
    );

    // ...and the chromatic edge painter must be attached to it.
    final Finder paints = find.descendant(
      of: field,
      matching: find.byType(CustomPaint),
    );
    expect(paints, findsWidgets);
    final CustomPaint paint = tester.widget<CustomPaint>(paints.first);
    expect(paint.foregroundPainter, isA<ChromaticGlassBorderPainter>());
  });

  testWidgets('text field: content is inset from the glass border',
      (tester) async {
    // Regression guard: the field restyle dropped the container's horizontal
    // padding, which left the trailing icon (the Date of Birth calendar)
    // sitting flush against the right edge — its outline visibly coincided
    // with the glass box border.
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: const _SuffixFieldHarness(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Rect surface = tester.getRect(
      find
          .descendant(of: find.byType(_SuffixFieldHarness), matching: find.byType(AnimatedContainer))
          .first,
    );
    final Rect icon = tester.getRect(find.byIcon(Icons.calendar_today_outlined));

    expect(
      surface.right - icon.right,
      greaterThanOrEqualTo(10.0),
      reason: 'The trailing icon must sit inside the glass surface, not on '
          'its border (gap was ${surface.right - icon.right}px).',
    );
    expect(
      icon.right,
      lessThan(surface.right),
      reason: 'The icon must not touch or cross the right border.',
    );
    // And the leading side has breathing room too (same padding).
    final Rect textField = tester.getRect(find.byType(TextField));
    expect(
      textField.left - surface.left,
      greaterThanOrEqualTo(10.0),
      reason: 'The text must be inset from the left border.',
    );
  });
}

/// Harness with a trailing icon, mirroring the Date of Birth field.
class _SuffixFieldHarness extends StatefulWidget {
  const _SuffixFieldHarness();

  @override
  State<_SuffixFieldHarness> createState() => _SuffixFieldHarnessState();
}

class _SuffixFieldHarnessState extends State<_SuffixFieldHarness> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthTextField(
      controller: _controller,
      label: 'Date of Birth',
      suffixIcon: Icons.calendar_today_outlined,
    );
  }
}

/// Small harness so the field test can build an AuthTextField with a real
/// controller without pulling in the whole auth screen.
class AuthTextFieldHarness extends StatefulWidget {
  const AuthTextFieldHarness({super.key});

  @override
  State<AuthTextFieldHarness> createState() => _AuthTextFieldHarnessState();
}

class _AuthTextFieldHarnessState extends State<AuthTextFieldHarness> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthTextField(
      controller: _controller,
      label: 'Email',
    );
  }
}