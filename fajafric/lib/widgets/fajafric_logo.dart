import 'dart:math' as math;
import 'package:flutter/material.dart';

/// FajafricLogo — badge SVG animé + wordmark "FJ" gradient + ligne or + slogan
///
/// Paramètres :
///   onDark     → palette claire sur fond sombre
///   fontSize   → taille du texte "FJ" en pixels logiques
///   showSlogan → afficher "Plateforme médicale"
///   animated   → jouer les animations au montage
class FajafricLogo extends StatefulWidget {
  final bool   onDark;
  final double fontSize;
  final bool   showSlogan;
  final bool   animated;

  const FajafricLogo({
    super.key,
    this.onDark     = false,
    this.fontSize   = 40,
    this.showSlogan = false,
    this.animated   = true,
  });

  @override
  State<FajafricLogo> createState() => _FajafricLogoState();
}

class _FajafricLogoState extends State<FajafricLogo>
    with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _ring, _bg, _ticks, _cross, _pulse, _reveal, _line, _slogan;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    );

    if (widget.animated) {
      _ring   = _iv(0.025, 0.525, Curves.easeInOut);
      _bg     = _iv(0.075, 0.375, Curves.easeOut);
      _ticks  = _iv(0.475, 0.725, Curves.easeOut);
      _cross  = _iv(0.350, 0.575, Curves.easeOutBack);
      _pulse  = _iv(0.200, 0.550, Curves.easeInOut);
      _reveal = _iv(0.275, 0.725, Curves.easeOut);
      _line   = _iv(0.625, 0.975, Curves.easeOut);
      _slogan = _iv(0.725, 1.000, Curves.easeOut);
      _ctrl.forward();
    } else {
      _ring = _bg = _ticks = _cross = _pulse =
      _reveal = _line = _slogan = const AlwaysStoppedAnimation(1.0);
    }
  }

  Animation<double> _iv(double t0, double t1, Curve curve) =>
      Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Interval(t0, t1, curve: curve)));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ── Palette couleurs ──────────────────────────────────────────
    final Color c1   = widget.onDark ? const Color(0xFFEAF6F3) : const Color(0xFF0D4A66);
    final Color c2   = widget.onDark ? const Color(0xFF9FE7D6) : const Color(0xFF1A7A6E);
    final Color c3   = widget.onDark ? const Color(0xFF4FE0C9) : const Color(0xFF2EC4B6);
    final Color gold = widget.onDark ? const Color(0xFFF0B429) : const Color(0xFFC9920A);
    final Color bgS1 = widget.onDark ? const Color(0xFF12566B) : const Color(0xFF1A7A6E);
    final Color bgS2 = widget.onDark ? const Color(0xFF0A2F3D) : const Color(0xFF0D4A66);
    final Color sloganColor = widget.onDark ? c3 : c2;

    final double badgeSize = widget.fontSize * 1.6;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Badge ───────────────────────────────────────────────
            SizedBox(
              width: badgeSize, height: badgeSize,
              child: CustomPaint(
                painter: _BadgePainter(
                  ringP:  _ring.value,
                  bgP:    _bg.value,
                  ticksP: _ticks.value,
                  crossP: _cross.value,
                  pulseP: _pulse.value,
                  c1: c1, c2: c2, c3: c3,
                  gold: gold, bgS1: bgS1, bgS2: bgS2,
                ),
              ),
            ),

            const SizedBox(width: 16),

            // ── Wordmark ─────────────────────────────────────────────
            IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // "FJ" — révélation de gauche à droite
                  ClipRect(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: _reveal.value,
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [c1, c2, c3],
                          stops: const [0.0, 0.55, 1.0],
                        ).createShader(bounds),
                        blendMode: BlendMode.srcIn,
                        child: Text(
                          'FJ',
                          style: TextStyle(
                            fontSize:      widget.fontSize,
                            fontWeight:    FontWeight.w800,
                            letterSpacing: -1.5,
                            height:        1.0,
                            color:         Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Ligne or — glisse de gauche à droite
                  const SizedBox(height: 6),
                  Transform(
                    alignment: Alignment.centerLeft,
                    transform: Matrix4.diagonal3Values(_line.value, 1, 1),
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color:         gold,
                        borderRadius:  BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Slogan
                  if (widget.showSlogan) ...[
                    const SizedBox(height: 7),
                    Opacity(
                      opacity: _slogan.value.clamp(0.0, 1.0),
                      child: Text(
                        'Plateforme médicale',
                        style: TextStyle(
                          fontSize:      12,
                          fontWeight:    FontWeight.w600,
                          letterSpacing: 2.2,
                          color:         sloganColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Badge Painter  (viewBox 100 × 100)
// ─────────────────────────────────────────────────────────────────────────────
class _BadgePainter extends CustomPainter {
  final double ringP, bgP, ticksP, crossP, pulseP;
  final Color  c1, c2, c3, gold, bgS1, bgS2;

  _BadgePainter({
    required this.ringP, required this.bgP,
    required this.ticksP, required this.crossP, required this.pulseP,
    required this.c1, required this.c2, required this.c3,
    required this.gold,  required this.bgS1, required this.bgS2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final s  = size.width / 100.0; // échelle : viewBox 100 → canvas
    final cx = 50.0 * s;
    final cy = 50.0 * s;

    // ── 1. Fond circulaire (scale 0.85→1 + fondu) ─────────────────
    if (bgP > 0) {
      final bgScale = 0.85 + bgP * 0.15;
      final bgR     = 32.0 * s * bgScale;

      final bgPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          radius: 0.75,
          colors: [bgS1.withOpacity(bgP), bgS2.withOpacity(bgP)],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: bgR));

      canvas.drawCircle(Offset(cx, cy), bgR, bgPaint);
    }

    // ── 2. Tirets décoratifs (16, style cadran, fade groupé) ──────
    if (ticksP > 0) {
      final tickPaint = Paint()
        ..color      = gold.withOpacity(0.75 * ticksP)
        ..strokeWidth = 1.4 * s
        ..strokeCap  = StrokeCap.round;

      for (int i = 0; i < 16; i++) {
        final a    = i * 22.5 * math.pi / 180.0;
        final sinA = math.sin(a);
        final cosA = math.cos(a);
        // (50, y) tourné de `a` rad autour de (50, 50) :
        //   x' = 50 + (y-50) * sin(a)   [car dx=0]
        //   y' = 50 - (y-50) * cos(a)   -- wait
        // formule exacte :
        //   x' = cx + dx*cos(a) - dy*sin(a),  dx=0, dy=y-50
        //   x' = cx - dy*sinA = cx + (50-y)*sinA
        //   y' = cy + dx*sinA + dy*cosA = cy + (y-50)*cosA
        final x1 = cx + (50 - 10.0) * s * sinA; // outer (y=10)
        final y1 = cy + (10 - 50.0) * s * cosA;
        final x2 = cx + (50 - 15.0) * s * sinA; // inner (y=15)
        final y2 = cy + (15 - 50.0) * s * cosA;
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), tickPaint);
      }
    }

    // ── 3. Anneau gradient (arc draw) ─────────────────────────────
    if (ringP > 0) {
      final ringRect = Rect.fromCircle(center: Offset(cx, cy), radius: 36.0 * s);
      final ringPaint = Paint()
        ..shader = SweepGradient(
          colors: [c1, c2, c3, c1],
          stops:  const [0.0, 0.40, 0.85, 1.0],
          startAngle: -math.pi / 2,
          endAngle:    3 * math.pi / 2,
        ).createShader(ringRect)
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 2.5 * s
        ..strokeCap   = StrokeCap.round;

      canvas.drawArc(
        ringRect,
        -math.pi / 2,        // départ : 12h
        2 * math.pi * ringP, // balayage progressif
        false,
        ringPaint,
      );
    }

    // ── 4. Tracé ECG (dessin partiel via PathMetrics) ─────────────
    if (pulseP > 0) {
      final pulsePath = Path()
        ..moveTo(22 * s, 66 * s)
        ..lineTo(30 * s, 66 * s)
        ..lineTo(34 * s, 58 * s)
        ..lineTo(38 * s, 72 * s)
        ..lineTo(42 * s, 66 * s)
        ..lineTo(78 * s, 66 * s);

      final pulsePaint = Paint()
        ..color       = Colors.white.withOpacity(0.9)
        ..strokeWidth = 2.0 * s
        ..strokeCap   = StrokeCap.round
        ..strokeJoin  = StrokeJoin.round
        ..style       = PaintingStyle.stroke;

      for (final m in pulsePath.computeMetrics()) {
        canvas.drawPath(m.extractPath(0, m.length * pulseP), pulsePaint);
      }
    }

    // ── 5. Croix médicale (pop avec easeOutBack via crossP) ───────
    if (crossP > 0) {
      final crossPaint = Paint()
        ..color = gold
        ..style = PaintingStyle.fill;

      // Centre de la croix : (50, 47) dans le viewBox
      final crossCx = 50.0 * s;
      final crossCy = 47.0 * s;

      canvas.save();
      canvas.translate(crossCx, crossCy);
      canvas.scale(crossP, crossP);
      canvas.translate(-crossCx, -crossCy);

      // Barre verticale : x=47, y=34, w=6, h=26
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(47 * s, 34 * s, 6 * s, 26 * s),
          Radius.circular(2 * s),
        ),
        crossPaint,
      );
      // Barre horizontale : x=37, y=44, w=26, h=6
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(37 * s, 44 * s, 26 * s, 6 * s),
          Radius.circular(2 * s),
        ),
        crossPaint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BadgePainter old) =>
      old.ringP  != ringP  ||
      old.bgP    != bgP    ||
      old.ticksP != ticksP ||
      old.crossP != crossP ||
      old.pulseP != pulseP ||
      old.c1     != c1;
}
