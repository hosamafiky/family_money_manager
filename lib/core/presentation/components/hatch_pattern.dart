/// The 45° hatch, in one place.
///
/// Hatching is load-bearing in this design: it is what says "held, not
/// spendable" on a leading edge, "remaining" on a progress meter, and
/// "overshoot" past a meter's mark. All three must be the same texture, or the
/// pattern stops reading as one idea — which is why the geometry lives here
/// rather than being redrawn per component.
library;

import 'package:flutter/rendering.dart';

/// How dense a hatch is drawn. Density is meaning, not decoration: a denser
/// hatch reads as a stronger statement, so it is reserved for the exception.
enum HatchDensity {
  /// The ordinary case — a remainder, a held edge.
  regular(spacing: 8, strokeWidth: 1),

  /// An exception worth noticing — an overshoot band.
  dense(spacing: 5, strokeWidth: 2);

  const HatchDensity({required this.spacing, required this.strokeWidth});

  final double spacing;
  final double strokeWidth;
}

/// Fills [rect] with 45° hatching in [color].
///
/// The lines are drawn across the rect's own height, so the angle reads the
/// same whether the shape is a 4 dp leading edge or a full-width meter band.
void paintHatch(
  Canvas canvas,
  Rect rect,
  Color color, {
  HatchDensity density = HatchDensity.regular,
}) {
  if (rect.width <= 0 || rect.height <= 0) return;

  canvas
    ..save()
    ..clipRect(rect);

  final paint = Paint()
    ..color = color
    ..strokeWidth = density.strokeWidth
    ..isAntiAlias = true;

  // Start a full height before the left edge so the first diagonal already
  // intersects the rect, rather than leaving a bald corner.
  for (var x = rect.left - rect.height; x < rect.right; x += density.spacing) {
    canvas.drawLine(
      Offset(x, rect.bottom),
      Offset(x + rect.height, rect.top),
      paint,
    );
  }

  canvas.restore();
}
