import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:services_rj/services_rj.dart';

bool _registered = false;

/// Registers the demo adapters for every pluggable field type (signature,
/// qrScanner, barcodeScanner, richText, markdown, htmlEditor) and the
/// `mood_picker` custom type. Safe to call more than once.
///
/// None of them needs a plugin: scanners simulate a scan, the editors are
/// plain text areas with a marker toolbar, and the signature pad draws with
/// a `CustomPaint`.
void registerDemoAdapters() {
  if (_registered) return;
  _registered = true;
  FieldFactory.register(FieldType.signature, _signature);
  FieldFactory.register(
    FieldType.qrScanner,
    (c, f, ctl) => _SimulatedScanner(
      field: f,
      controller: ctl,
      icon: Icons.qr_code_scanner,
      prefix: 'QR',
    ),
  );
  FieldFactory.register(
    FieldType.barcodeScanner,
    (c, f, ctl) => _SimulatedScanner(
      field: f,
      controller: ctl,
      icon: Icons.barcode_reader,
      prefix: 'EAN',
    ),
  );
  FieldFactory.register(
    FieldType.richText,
    (c, f, ctl) =>
        _MarkupEditor(field: f, controller: ctl, mode: _MarkupMode.rich),
  );
  FieldFactory.register(
    FieldType.markdown,
    (c, f, ctl) =>
        _MarkupEditor(field: f, controller: ctl, mode: _MarkupMode.markdown),
  );
  FieldFactory.register(
    FieldType.htmlEditor,
    (c, f, ctl) =>
        _MarkupEditor(field: f, controller: ctl, mode: _MarkupMode.html),
  );
  FieldFactory.registerCustom(
    'mood_picker',
    (c, f, ctl) => _MoodPicker(field: f, controller: ctl),
  );
}

/// Shared frame: label, content and the field's validation error.
class _AdapterFrame extends StatelessWidget {
  const _AdapterFrame({
    required this.field,
    required this.controller,
    required this.child,
    this.trailing,
  });

  final FieldConfig field;
  final DynamicFormController controller;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final state = controller.state(field.id);
    return ValueListenableBuilder<String?>(
      valueListenable: state.error,
      builder: (context, error, _) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: error == null
                ? Theme.of(context).dividerColor
                : scheme.error,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(field.label ?? field.id, style: text.titleSmall),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 8),
            child,
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  error,
                  style: text.bodySmall?.copyWith(color: scheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------- signature

Widget _signature(
  BuildContext context,
  FieldConfig field,
  DynamicFormController controller,
) => _SignaturePad(field: field, controller: controller);

/// Drag-to-draw pad. The value is a list of strokes, each a list of
/// `[x, y]` points, or null while empty.
///
/// Drawing claims the touch immediately (an [EagerGestureRecognizer]) so the
/// surrounding list never scrolls while you sign, and pointer events (not a
/// pan recognizer) draw, so even a tiny stroke or a dot registers.
class _SignaturePad extends StatefulWidget {
  const _SignaturePad({required this.field, required this.controller});

  final FieldConfig field;
  final DynamicFormController controller;

  @override
  State<_SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<_SignaturePad> {
  final List<List<List<double>>> _strokes = [];

  /// Bumped on every point so only the painter repaints while drawing.
  final ValueNotifier<int> _ink = ValueNotifier(0);

  /// Pointer currently drawing, so a second finger cannot corrupt the stroke.
  int? _pointer;

  late final ValueNotifier<Object?> _value = widget.controller
      .state(widget.field.id)
      .value;

  bool get _drawing => _pointer != null;

  @override
  void initState() {
    super.initState();
    _value.addListener(_followExternalChange);
  }

  @override
  void dispose() {
    _value.removeListener(_followExternalChange);
    _ink.dispose();
    super.dispose();
  }

  /// Clears the pad when the form is reset or cleared from outside. The form
  /// value is only committed when a stroke ends, so it is still null while
  /// drawing and must not be mistaken for a reset.
  void _followExternalChange() {
    if (_value.value == null && !_drawing && _strokes.isNotEmpty) {
      _strokes.clear();
      _ink.value++;
      setState(() {});
    }
  }

  void _commit() => widget.controller.setValue(
    widget.field.id,
    _strokes.isEmpty
        ? null
        : [
            for (final stroke in _strokes)
              [
                for (final p in stroke) [...p],
              ],
          ],
  );

  void _down(PointerDownEvent e) {
    if (_drawing) return;
    _pointer = e.pointer;
    _strokes.add([
      [e.localPosition.dx, e.localPosition.dy],
    ]);
    _ink.value++;
  }

  void _move(PointerMoveEvent e) {
    if (e.pointer != _pointer || _strokes.isEmpty) return;
    _strokes.last.add([e.localPosition.dx, e.localPosition.dy]);
    _ink.value++;
  }

  void _up(PointerEvent e) {
    if (e.pointer != _pointer) return;
    _pointer = null;
    _commit();
    setState(() {}); // refresh the stroke counter and Clear button
  }

  void _clear() {
    _pointer = null;
    _strokes.clear();
    _ink.value++;
    _commit();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Explicit pairs so the signature always contrasts with its paper:
    // dark ink on light paper, light ink on dark paper.
    final paper = dark ? const Color(0xFF26272B) : Colors.white;
    final ink = dark ? Colors.white : const Color(0xFF14213D);
    final strokes = _strokes.length;
    return _AdapterFrame(
      field: widget.field,
      controller: widget.controller,
      trailing: TextButton.icon(
        onPressed: strokes == 0 ? null : _clear,
        icon: const Icon(Icons.clear),
        label: const Text('Clear'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: RawGestureDetector(
              gestures: {
                EagerGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<
                      EagerGestureRecognizer
                    >(EagerGestureRecognizer.new, (_) {}),
              },
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: _down,
                onPointerMove: _move,
                onPointerUp: _up,
                onPointerCancel: _up,
                child: Container(
                  key: const ValueKey('signature_pad'),
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: paper,
                    border: Border.all(color: scheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomPaint(
                    painter: SignatureInkPainter(
                      _strokes,
                      ink: ink,
                      guide: ink.withValues(alpha: 0.25),
                      repaint: _ink,
                      showGuide: strokes == 0,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            strokes == 0
                ? 'Draw with your finger or mouse.'
                : '$strokes stroke(s) captured.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Paints signature strokes on a baseline. [ink] is the stroke colour and
/// [guide] the faint "sign here" line; both are chosen per theme brightness.
@visibleForTesting
class SignatureInkPainter extends CustomPainter {
  /// Creates a painter that repaints whenever [repaint] notifies.
  SignatureInkPainter(
    this.strokes, {
    required this.ink,
    required this.guide,
    required this.showGuide,
    super.repaint,
  });

  /// Strokes as lists of `[x, y]` points.
  final List<List<List<double>>> strokes;

  /// Stroke colour.
  final Color ink;

  /// Colour of the baseline and the placeholder.
  final Color guide;

  /// Whether to draw the baseline and "Sign here" while the pad is empty.
  final bool showGuide;

  @override
  void paint(Canvas canvas, Size size) {
    if (showGuide) {
      final y = size.height * 0.72;
      canvas.drawLine(
        Offset(16, y),
        Offset(size.width - 16, y),
        Paint()
          ..color = guide
          ..strokeWidth = 1.2,
      );
      final label = TextPainter(
        text: TextSpan(
          text: 'Sign here',
          style: TextStyle(color: guide, fontSize: 13),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, Offset(16, y + 6));
    }
    final paint = Paint()
      ..color = ink
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        canvas.drawCircle(
          Offset(stroke[0][0], stroke[0][1]),
          1.4,
          Paint()..color = ink,
        );
        continue;
      }
      final path = Path()..moveTo(stroke[0][0], stroke[0][1]);
      for (final p in stroke.skip(1)) {
        path.lineTo(p[0], p[1]);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(SignatureInkPainter old) =>
      old.ink != ink || old.showGuide != showGuide || old.guide != guide;
}

// --------------------------------------------------------------- scanners

/// Stands in for a camera scanner: a read-only code box plus a button that
/// "scans" a fake code, so the demo needs no camera plugin.
class _SimulatedScanner extends StatelessWidget {
  const _SimulatedScanner({
    required this.field,
    required this.controller,
    required this.icon,
    required this.prefix,
  });

  final FieldConfig field;
  final DynamicFormController controller;
  final IconData icon;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    final state = controller.state(field.id);
    return ValueListenableBuilder<Object?>(
      valueListenable: state.value,
      builder: (context, value, _) => _AdapterFrame(
        field: field,
        controller: controller,
        child: Row(
          children: [
            Expanded(
              child: Text(
                value?.toString() ?? 'Nothing scanned yet',
                key: ValueKey('${field.id}_code'),
                style: TextStyle(
                  fontFamily: value == null ? null : 'monospace',
                  color: value == null ? Theme.of(context).hintColor : null,
                ),
              ),
            ),
            FilledButton.tonalIcon(
              key: ValueKey('${field.id}_scan'),
              onPressed: () {
                final n = math.Random().nextInt(900000) + 100000;
                controller.setValue(field.id, '$prefix-$n');
              },
              icon: Icon(icon),
              label: const Text('Simulate scan'),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- editors

enum _MarkupMode { rich, markdown, html }

class _MarkupEditor extends StatefulWidget {
  const _MarkupEditor({
    required this.field,
    required this.controller,
    required this.mode,
  });

  final FieldConfig field;
  final DynamicFormController controller;
  final _MarkupMode mode;

  @override
  State<_MarkupEditor> createState() => _MarkupEditorState();
}

class _MarkupEditorState extends State<_MarkupEditor> {
  late final TextEditingController _text;
  VoidCallback? _cancel;

  (String, String) _pair(String tool) => switch (widget.mode) {
    _MarkupMode.html => switch (tool) {
      'bold' => ('<b>', '</b>'),
      'italic' => ('<i>', '</i>'),
      _ => ('<code>', '</code>'),
    },
    _ => switch (tool) {
      'bold' => ('**', '**'),
      'italic' => ('_', '_'),
      _ => ('`', '`'),
    },
  };

  @override
  void initState() {
    super.initState();
    final c = widget.controller;
    _text = TextEditingController(
      text: c.getValue(widget.field.id)?.toString() ?? '',
    );
    _text.addListener(() {
      final v = _text.text.isEmpty ? null : _text.text;
      if (v != c.getValue(widget.field.id)) c.setValue(widget.field.id, v);
    });
    _cancel = c.listen(widget.field.id, (v) {
      final s = v?.toString() ?? '';
      if (s != _text.text) _text.text = s;
    });
  }

  @override
  void dispose() {
    _cancel?.call();
    _text.dispose();
    super.dispose();
  }

  void _wrap(String tool) {
    final (open, close) = _pair(tool);
    final sel = _text.selection;
    final at = sel.isValid
        ? sel
        : TextSelection.collapsed(offset: _text.text.length);
    final inner = at.textInside(_text.text);
    final replaced = _text.text.replaceRange(
      at.start,
      at.end,
      '$open$inner$close',
    );
    _text.value = TextEditingValue(
      text: replaced,
      selection: TextSelection.collapsed(
        offset: at.start + open.length + inner.length,
      ),
    );
  }

  /// A tiny preview: rich/markdown render bold, italic and code runs; HTML
  /// shows the tags stripped of markup but styled the same way.
  List<InlineSpan> _preview(String source) {
    final pattern = widget.mode == _MarkupMode.html
        ? RegExp(r'<(b|i|code)>(.*?)</\1>', dotAll: true)
        : RegExp(r'(\*\*|_|`)(.+?)\1', dotAll: true);
    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in pattern.allMatches(source)) {
      if (m.start > last) {
        spans.add(TextSpan(text: source.substring(last, m.start)));
      }
      final tag = m.group(1)!;
      final style = switch (tag) {
        '**' || 'b' => const TextStyle(fontWeight: FontWeight.bold),
        '_' || 'i' => const TextStyle(fontStyle: FontStyle.italic),
        _ => const TextStyle(
          fontFamily: 'monospace',
          backgroundColor: Color(0x22888888),
        ),
      };
      spans.add(TextSpan(text: m.group(2), style: style));
      last = m.end;
    }
    if (last < source.length) spans.add(TextSpan(text: source.substring(last)));
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.controller.state(widget.field.id);
    final kind = switch (widget.mode) {
      _MarkupMode.rich => 'Rich text (markers)',
      _MarkupMode.markdown => 'Markdown',
      _MarkupMode.html => 'HTML',
    };
    return _AdapterFrame(
      field: widget.field,
      controller: widget.controller,
      trailing: Text(kind, style: Theme.of(context).textTheme.labelSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Bold',
                onPressed: () => _wrap('bold'),
                icon: const Icon(Icons.format_bold),
              ),
              IconButton(
                tooltip: 'Italic',
                onPressed: () => _wrap('italic'),
                icon: const Icon(Icons.format_italic),
              ),
              IconButton(
                tooltip: 'Code',
                onPressed: () => _wrap('code'),
                icon: const Icon(Icons.code),
              ),
            ],
          ),
          TextField(
            key: ValueKey('${widget.field.id}_input'),
            controller: _text,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          Text('Preview', style: Theme.of(context).textTheme.labelSmall),
          ValueListenableBuilder<Object?>(
            valueListenable: state.value,
            builder: (context, value, _) => Text.rich(
              TextSpan(children: _preview(value?.toString() ?? '')),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------- custom type

/// `{"type": "custom", "customType": "mood_picker"}`: five emoji, stored as
/// an int 1-5.
class _MoodPicker extends StatelessWidget {
  const _MoodPicker({required this.field, required this.controller});

  final FieldConfig field;
  final DynamicFormController controller;

  static const _moods = ['😖', '🙁', '😐', '🙂', '🤩'];

  @override
  Widget build(BuildContext context) {
    final state = controller.state(field.id);
    return ValueListenableBuilder<Object?>(
      valueListenable: state.value,
      builder: (context, value, _) => _AdapterFrame(
        field: field,
        controller: controller,
        child: Wrap(
          spacing: 8,
          children: [
            for (var i = 0; i < _moods.length; i++)
              ChoiceChip(
                key: ValueKey('${field.id}_${i + 1}'),
                label: Text(_moods[i], style: const TextStyle(fontSize: 24)),
                selected: value == i + 1,
                onSelected: (_) => controller.setValue(field.id, i + 1),
              ),
          ],
        ),
      ),
    );
  }
}
