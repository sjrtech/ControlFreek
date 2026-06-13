import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../device_provider.dart';
import 'scan_screen.dart';

const double _imgW = 314;
const double _imgH = 219;

enum _PortType { main, aux, fsw, loopSend, loopReturn }

class _Port {
  final String id;
  final double x, y;
  final String label;
  final _PortType type;
  final String? fieldKey; // 'loop_0'..'loop_6', 'aux_0'..'aux_3', 'fsw_0'..'fsw_5'

  const _Port(this.id, this.x, this.y, this.label, this.type, [this.fieldKey]);

  Color get color => switch (type) {
        _PortType.main       => Colors.white,
        _PortType.aux        => const Color(0xFFFFD700),
        _PortType.fsw        => const Color(0xFF4499FF),
        _PortType.loopSend   => const Color(0xFF44DD88),
        _PortType.loopReturn => const Color(0xFF88FFBB),
      };
}

const _ports = [
  _Port('A1',  63,  73, 'MAIN IN',        _PortType.main),
  _Port('A2',  63, 105, 'MAIN OUT',       _PortType.main),
  _Port('B1', 109,  73, 'AUX 1',          _PortType.aux,       'aux_0'),
  _Port('B2', 109, 105, 'AUX 2',          _PortType.aux,       'aux_1'),
  _Port('C1', 141,  72, 'AUX 3',          _PortType.aux,       'aux_2'),
  _Port('C2', 140, 105, 'AUX 4',          _PortType.aux,       'aux_3'),
  _Port('D1', 189,  73, 'FSW 1',          _PortType.fsw,       'fsw_0'),
  _Port('D2', 189, 105, 'FSW 2',          _PortType.fsw,       'fsw_1'),
  _Port('E1', 221,  73, 'FSW 3',          _PortType.fsw,       'fsw_2'),
  _Port('E2', 221, 105, 'FSW 4',          _PortType.fsw,       'fsw_3'),
  _Port('F1', 253,  73, 'FSW 5',          _PortType.fsw,       'fsw_4'),
  _Port('F2', 253, 105, 'FSW 6',          _PortType.fsw,       'fsw_5'),
  _Port('A3',  60, 139, 'Loop 1 Return',  _PortType.loopReturn,'loop_0'),
  _Port('A4',  61, 172, 'Loop 1 Send',    _PortType.loopSend,  'loop_0'),
  _Port('B3',  92, 139, 'Loop 2 Return',  _PortType.loopReturn,'loop_1'),
  _Port('B4',  91, 173, 'Loop 2 Send',    _PortType.loopSend,  'loop_1'),
  _Port('C3', 124, 139, 'Loop 3 Return',  _PortType.loopReturn,'loop_2'),
  _Port('C4', 124, 172, 'Loop 3 Send',    _PortType.loopSend,  'loop_2'),
  _Port('D3', 157, 139, 'Loop 4 Return',  _PortType.loopReturn,'loop_3'),
  _Port('D4', 156, 172, 'Loop 4 Send',    _PortType.loopSend,  'loop_3'),
  _Port('E3', 188, 139, 'Loop 5 Return',  _PortType.loopReturn,'loop_4'),
  _Port('E4', 188, 172, 'Loop 5 Send',    _PortType.loopSend,  'loop_4'),
  _Port('F3', 221, 139, 'Loop 6 Return',  _PortType.loopReturn,'loop_5'),
  _Port('F4', 221, 172, 'Loop 6 Send',    _PortType.loopSend,  'loop_5'),
  _Port('G3', 253, 139, 'Loop 7 Return',  _PortType.loopReturn,'loop_6'),
  _Port('G4', 253, 171, 'Loop 7 Send',    _PortType.loopSend,  'loop_6'),
];

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _scrollController = ScrollController();
  String? _activeField;

  final _focusNodes = <String, FocusNode>{
    for (int i = 0; i < 7; i++) 'loop_$i': FocusNode(),
    for (int i = 0; i < 4; i++) 'aux_$i': FocusNode(),
    for (int i = 0; i < 6; i++) 'fsw_$i': FocusNode(),
  };

  final _fieldKeys = <String, GlobalKey>{
    for (int i = 0; i < 7; i++) 'loop_$i': GlobalKey(),
    for (int i = 0; i < 4; i++) 'aux_$i': GlobalKey(),
    for (int i = 0; i < 6; i++) 'fsw_$i': GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    for (final e in _focusNodes.entries) {
      e.value.addListener(() {
        setState(() {
          if (e.value.hasFocus) {
            _activeField = e.key;
          } else if (_activeField == e.key) {
            _activeField = null;
          }
        });
      });
    }
  }

  @override
  void dispose() {
    for (final n in _focusNodes.values) { n.dispose(); }
    _scrollController.dispose();
    super.dispose();
  }

  void _onPortTap(_Port port) {
    final key = port.fieldKey;
    if (key == null) return;
    _focusNodes[key]?.requestFocus();
    final ctx = _fieldKeys[key]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 300), alignment: 0.3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<DeviceProvider>();
    final s = p.settings;

    return Scaffold(
      appBar: AppBar(
        title: appBarTitle('Breakout Setup', icon: Icons.settings_input_component),
        backgroundColor: const Color(0xFF1A3A7A),
        actions: bleAppBarActions(p, context),
      ),
      body: CarbonBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _BreakoutImage(activeField: _activeField, onPortTap: _onPortTap),
            ),
            Expanded(
              child: ListView(
                controller: _scrollController,
                key: ValueKey(p.configLoadCount),
                padding: EdgeInsets.zero,
                children: [
                  IgnorePointer(
                    ignoring: kDisableWhenDisconnected && !p.isConnected,
                    child: AnimatedOpacity(
                      opacity: kDisableWhenDisconnected && !p.isConnected ? 0.35 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _dividerSection('LOOPS'),
                          for (int i = 0; i < 7; i++)
                            _strField('Loop ${i + 1}:', s.getLoopName(i),
                                (v) => s.setLoopName(i, v),
                                focusNode: _focusNodes['loop_$i']!,
                                rowKey: _fieldKeys['loop_$i']!),
                          _dividerSection('AUX OUTPUTS'),
                          for (int i = 0; i < 4; i++)
                            _strField('Aux ${i + 1}:', s.getAuxName(i),
                                (v) => s.setAuxName(i, v),
                                focusNode: _focusNodes['aux_$i']!,
                                rowKey: _fieldKeys['aux_$i']!),
                          _dividerSection('FOOTSWITCHES'),
                          for (int i = 0; i < 6; i++)
                            _strField('Fsw ${i + 1}:', s.getFswName(i),
                                (v) => s.setFswName(i, v),
                                focusNode: _focusNodes['fsw_$i']!,
                                rowKey: _fieldKeys['fsw_$i']!),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _UpdateButton(
              label: 'Update Setup',
              enabled: p.isConnected,
              onPressed: p.updateConfigToDevice,
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakoutImage extends StatelessWidget {
  final String? activeField;
  final void Function(_Port) onPortTap;

  const _BreakoutImage({required this.activeField, required this.onPortTap});

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    return LayoutBuilder(builder: (context, constraints) {
      final fraction = isLandscape ? 0.25 : 0.5;
      final imgW = constraints.maxWidth * fraction;
      final scale = imgW / _imgW;
      final imgH = _imgH * scale;
      final leftMargin = (constraints.maxWidth - imgW) / 2;

      return SizedBox(
        width: constraints.maxWidth,
        height: imgH,
        child: Stack(
          children: [
            // Image + port dots/labels, centered
            Positioned(
              left: leftMargin,
              top: 0,
              child: SizedBox(
                width: imgW,
                height: imgH,
                child: Stack(
                  children: [
                    Image.asset('assets/breakout box.png',
                        width: imgW, height: imgH, fit: BoxFit.fill),
                    for (final port in _ports)
                      _PortDot(
                        port: port,
                        scale: scale,
                        isActive: port.fieldKey != null && port.fieldKey == activeField,
                        onTap: () => onPortTap(port),
                      ),
                    ..._buildLabels(scale),
                    ..._buildGroupLabels(scale),
                  ],
                ),
              ),
            ),
            // MAIN IN / MAIN OUT labels drawn in full-width space to the left of the image
            CustomPaint(
              size: Size(constraints.maxWidth, imgH),
              painter: _MainLabelPainter(scale, leftMargin),
            ),
          ],
        ),
      );
    });
  }

  List<Widget> _buildLabels(double scale) {
    const entries = [
      (109.0, 73.0,  '1'), (109.0, 105.0, '2'), // AUX 1-2
      (141.0, 72.0,  '3'), (140.0, 105.0, '4'), // AUX 3-4
      (189.0, 73.0,  '1'), (189.0, 105.0, '2'), // FSW 1-2
      (221.0, 73.0,  '3'), (221.0, 105.0, '4'), // FSW 3-4
      (253.0, 73.0,  '5'), (253.0, 105.0, '6'), // FSW 5-6
      // Loop numbers midway between row 3 (y≈139) and row 4 (y≈172)
      ( 60.5, 155.5, '1'), ( 91.5, 155.5, '2'), (124.0, 155.5, '3'),
      (156.5, 155.5, '4'), (188.0, 155.5, '5'), (221.0, 155.5, '6'),
      (253.0, 155.5, '7'),
    ];

    final r = 9.0 * scale;
    final fontSize = (13.0 * scale).clamp(10.0, 18.0);

    return [
      for (final (ox, oy, text) in entries)
        Positioned(
          left: ox * scale - r,
          top: oy * scale - r,
          child: SizedBox(
            width: r * 2,
            height: r * 2,
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: const [Shadow(color: Colors.black, blurRadius: 3)],
                ),
              ),
            ),
          ),
        ),
    ];
  }

  List<Widget> _buildGroupLabels(double scale) {
    final fontSize = (13.0 * scale).clamp(10.0, 18.0);
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      shadows: const [Shadow(color: Colors.black, blurRadius: 3)],
    );

    // AUX ports at x=109,141 → center x=125; FSW ports at x=189,221,253 → center x=221
    // Positioned above row 1 (y=73), label top at y≈53 in original coords
    Widget label(double cx, String text) => Positioned(
      left: (cx - 30) * scale,
      top: 40.0 * scale,
      child: SizedBox(
        width: 60.0 * scale,
        child: Text(text, textAlign: TextAlign.center, style: style),
      ),
    );

    return [
      label(125.0, 'AUX'),
      label(221.0, 'FSW'),
    ];
  }
}

class _PortDot extends StatelessWidget {
  final _Port port;
  final double scale;
  final bool isActive;
  final VoidCallback onTap;

  const _PortDot({
    required this.port,
    required this.scale,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final x = port.x * scale;
    final y = port.y * scale;
    final r = 9.0 * scale;

    return Positioned(
      left: x - r,
      top: y - r,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: r * 2,
          height: r * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: port.color.withValues(alpha: isActive ? 0.8 : 0.35),
            border: Border.all(
              color: isActive ? Colors.white : port.color,
              width: isActive ? 2.0 * scale : 1.2 * scale,
            ),
            boxShadow: isActive
                ? [BoxShadow(
                    color: port.color.withValues(alpha: 0.9),
                    blurRadius: 8 * scale,
                    spreadRadius: 2 * scale)]
                : null,
          ),
        ),
      ),
    );
  }
}

class _MainLabelPainter extends CustomPainter {
  final double scale;
  final double leftMargin;

  const _MainLabelPainter(this.scale, this.leftMargin);

  TextStyle get _style => TextStyle(
    fontSize: (13.0 * scale).clamp(10.0, 18.0),
    fontWeight: FontWeight.bold,
    color: Colors.white,
    shadows: const [Shadow(color: Colors.black, blurRadius: 3)],
  );

  TextPainter _measure(String text) =>
      TextPainter(text: TextSpan(text: text, style: _style), textDirection: TextDirection.ltr)
        ..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final portCenterX = leftMargin + 63.0 * scale;
    _drawArrowLabel(canvas, 'MAIN IN',  portCenterX, 73.0  * scale);
    _drawArrowLabel(canvas, 'MAIN OUT', portCenterX, 105.0 * scale);
    _drawLoopsLabel(canvas);
  }

  void _drawArrowLabel(Canvas canvas, String text, double portX, double portY) {
    final arrowSz = 5.0 * scale;
    final gap     = 5.0 * scale;
    final tp      = _measure(text);

    // Text ends just left of the image
    final textRight = leftMargin - gap;
    final textX = math.max(4.0, textRight - tp.width);
    tp.paint(canvas, Offset(textX, portY - tp.height / 2));

    final lineStart = textX + tp.width + gap;
    final tipX  = portX;
    final baseX = tipX - arrowSz;

    final shadowPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 4.0 * scale
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5 * scale
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(lineStart, portY), Offset(baseX, portY), shadowPaint);
    canvas.drawLine(Offset(lineStart, portY), Offset(baseX, portY), linePaint);

    final arrow = Path()
      ..moveTo(tipX,  portY)
      ..lineTo(baseX, portY - arrowSz / 2)
      ..lineTo(baseX, portY + arrowSz / 2)
      ..close();
    canvas.drawPath(arrow, Paint()..color = Colors.black..style = PaintingStyle.fill);
    canvas.drawPath(arrow, Paint()..color = Colors.white..style = PaintingStyle.fill);
  }

  void _drawLoopsLabel(Canvas canvas) {
    final tp  = _measure('LOOPS');
    final gap = 5.0 * scale;
    // Center halfway between image left edge and Loop 1 column
    final imageLeftEdge = leftMargin - gap;
    final loop1X = leftMargin + 60.5 * scale;
    final cx = (3 * imageLeftEdge + loop1X) / 4;
    final textX = math.max(4.0, cx - tp.width / 2);
    tp.paint(canvas, Offset(textX, 155.5 * scale - tp.height / 2));
  }

  @override
  bool shouldRepaint(_MainLabelPainter old) =>
      old.scale != scale || old.leftMargin != leftMargin;
}

Widget _dividerSection(String title, {double topPadding = 6}) => Padding(
      padding: EdgeInsets.only(top: topPadding, bottom: 0),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                letterSpacing: 6,
                color: Colors.grey,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );

Widget _strField(
  String label,
  String value,
  void Function(String) onChange, {
  required FocusNode focusNode,
  required GlobalKey rowKey,
}) =>
    _FieldRow(
      key: rowKey,
      label: label,
      child: TextFormField(
        focusNode: focusNode,
        initialValue: value,
        maxLength: 11,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(
          isDense: true,
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 2),
        ),
        onChanged: onChange,
      ),
    );

class _FieldRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _FieldRow({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final leftPad = MediaQuery.of(context).size.width * 0.25;
    return Container(
      padding: EdgeInsets.only(left: leftPad, right: 12, top: 0, bottom: 0),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(label,
                style: const TextStyle(fontSize: 15, color: Colors.grey)),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _UpdateButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  const _UpdateButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0D1B3E),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
          child: Row(
            children: [
              const Expanded(child: SizedBox()),
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: enabled ? onPressed : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A3A7A),
                    foregroundColor: const Color(0xFFBCC8DC),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.settings_input_component, size: 18),
                      const SizedBox(width: 8),
                      Text(label,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      ),
    );
  }
}
