import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';

/// Clé de stockage SharedPreferences pour la signature
const kSignatureKey = 'doctor_signature_b64';

/// Lit la signature enregistrée (base64 PNG) ou null
Future<String?> loadSignature() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(kSignatureKey);
}

/// Sauvegarde la signature en base64
Future<void> saveSignature(String b64) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(kSignatureKey, b64);
}

/// Supprime la signature
Future<void> clearSignature() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(kSignatureKey);
}

/// Affiche la signature depuis un base64 PNG
class SignatureImage extends StatelessWidget {
  final String base64;
  final double height;
  const SignatureImage({super.key, required this.base64, this.height = 80});

  @override
  Widget build(BuildContext context) {
    try {
      final bytes = base64Decode(base64);
      return Image.memory(Uint8List.fromList(bytes),
          height: height, fit: BoxFit.contain);
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}

// ── Pad de dessin ─────────────────────────────────────────────────────────────

class SignaturePadScreen extends StatefulWidget {
  const SignaturePadScreen({super.key});

  @override
  State<SignaturePadScreen> createState() => _SignaturePadScreenState();
}

class _SignaturePadScreenState extends State<SignaturePadScreen> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _current = [];
  final _repaintKey = GlobalKey();
  bool _saving = false;
  bool _hasDrawn = false;

  void _onPanStart(DragStartDetails d) {
    setState(() {
      _current = [d.localPosition];
      _hasDrawn = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() => _current = [..._current, d.localPosition]);
  }

  void _onPanEnd(DragEndDetails _) {
    setState(() {
      _strokes.add(List.from(_current));
      _current = [];
    });
  }

  void _clear() => setState(() { _strokes.clear(); _current = []; _hasDrawn = false; });

  Future<void> _save() async {
    if (!_hasDrawn) return;
    setState(() => _saving = true);
    try {
      final boundary = _repaintKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('toByteData null');
      final bytes = byteData.buffer.asUint8List();
      final b64 = base64Encode(bytes);
      await saveSignature(b64);
      if (mounted) Navigator.pop(context, b64);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'enregistrement')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Signature électronique',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _clear,
            child: const Text('Effacer',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Column(children: [
        // Instructions
        Container(
          width: double.infinity,
          color: AppTheme.bgElevated,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(children: [
            const Icon(Icons.gesture_rounded, color: AppTheme.teal, size: 18),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Dessinez votre signature avec le doigt dans le cadre ci-dessous',
                  style: TextStyle(fontSize: 13, color: AppTheme.inkSoft)),
            ),
          ]),
        ),

        // Canvas
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: RepaintBoundary(
                key: _repaintKey,
                child: GestureDetector(
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppTheme.border, width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(children: [
                      // Ligne de base
                      Positioned(
                        left: 40, right: 40,
                        bottom: 60,
                        child: Container(height: 1, color: AppTheme.border),
                      ),
                      if (!_hasDrawn)
                        const Center(
                          child: Text('Signez ici',
                              style: TextStyle(
                                  color: Color(0xFFCCCCCC),
                                  fontSize: 22,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w300)),
                        ),
                      CustomPaint(
                        painter: _SignaturePainter(
                            strokes: _strokes, current: _current),
                        size: Size.infinite,
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Bouton sauvegarder
        Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).padding.bottom + 20),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: (_hasDrawn && !_saving) ? _save : null,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_rounded),
              label: Text(_saving ? 'Enregistrement…' : 'Enregistrer la signature',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.border,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Painter ───────────────────────────────────────────────────────────────────

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> current;

  _SignaturePainter({required this.strokes, required this.current});

  final _paint = Paint()
    ..color = const Color(0xFF0E2A3A)
    ..strokeWidth = 2.8
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;

  void _drawStroke(Canvas canvas, List<Offset> pts) {
    if (pts.isEmpty) return;
    if (pts.length == 1) {
      canvas.drawCircle(pts.first, 1.4, _paint..style = PaintingStyle.fill);
      _paint.style = PaintingStyle.stroke;
      return;
    }
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length - 1; i++) {
      final mid = Offset((pts[i].dx + pts[i + 1].dx) / 2,
          (pts[i].dy + pts[i + 1].dy) / 2);
      path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(pts.last.dx, pts.last.dy);
    canvas.drawPath(path, _paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) { _drawStroke(canvas, s); }
    _drawStroke(canvas, current);
  }

  @override
  bool shouldRepaint(_SignaturePainter old) =>
      old.strokes != strokes || old.current != current;
}
