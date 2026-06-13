import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../device_provider.dart';
import 'help_screen.dart';

// ─── Carbon fiber background ─────────────────────────────────────────────────

class _TexturePainter extends CustomPainter {
  const _TexturePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 1.0;

    for (double y = 0; y < size.height; y++) {
      // Overlapping sine waves at different frequencies simulate fine brush marks
      final v = (math.sin(y * 0.5)  * 0.40 +
                 math.sin(y * 1.3)  * 0.30 +
                 math.sin(y * 3.7)  * 0.20 +
                 math.sin(y * 0.09) * 0.10).abs();
      final b = (12 + v * 22).round().clamp(10, 38);
      paint.color = Color.fromARGB(255, b, b, b);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Subtle vignette — slightly darker at edges, lighter toward centre
    final bounds = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.35)],
          stops: const [0.55, 1.0],
        ).createShader(bounds),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class CarbonBackground extends StatelessWidget {
  final Widget child;
  const CarbonBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: const _TexturePainter(),
        child: child,
      );
}

// ─── App bar helpers ──────────────────────────────────────────────────────────

Widget appBarTitle(String text, {IconData? icon}) => Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    if (icon != null) ...[
      Icon(icon, size: 17, color: const Color(0xFFBCC8DC)),
      const SizedBox(width: 8),
    ],
    Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 20,
        letterSpacing: 6,
        color: Color(0xFFBCC8DC),
        fontWeight: FontWeight.w600,
      ),
    ),
  ],
);

IconData _rssiIcon(int rssi) {
  if (rssi >= -60) return Icons.signal_cellular_4_bar;
  if (rssi >= -70) return Icons.signal_cellular_alt_2_bar;
  if (rssi >= -85) return Icons.signal_cellular_alt_1_bar;
  return Icons.signal_cellular_0_bar;
}

Color _rssiColor(int rssi) {
  if (rssi >= -70) return Colors.greenAccent;
  if (rssi >= -85) return Colors.orange;
  return Colors.red;
}

List<Widget> bleAppBarActions(DeviceProvider p, BuildContext context) {
  final connected = p.bleState == BleState.connected;
  final scanning  = p.bleState == BleState.scanning;
  return [
    IconButton(
      icon: const Icon(Icons.help_outline),
      tooltip: 'Help',
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const HelpScreen()),
      ),
    ),
    // Signal / status indicator (non-interactive)
    if (connected && p.rssi != 0)
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Icon(_rssiIcon(p.rssi), color: _rssiColor(p.rssi), size: 20),
      )
    else if (connected)
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: Icon(Icons.signal_cellular_0_bar, color: Colors.grey, size: 20),
      )
    else if (scanning)
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: Icon(Icons.radar, color: Color(0xFFBCC8DC), size: 20),
      )
    else
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: Icon(Icons.signal_cellular_off, color: Colors.grey, size: 20),
      ),
    // BLE action button
    if (connected)
      IconButton(
        icon: const Icon(Icons.bluetooth_disabled),
        tooltip: 'Disconnect',
        onPressed: p.disconnect,
      )
    else if (scanning)
      IconButton(
        icon: const Icon(Icons.stop_circle_outlined),
        tooltip: 'Stop scan',
        onPressed: p.stopScan,
      )
    else
      IconButton(
        icon: const Icon(Icons.bluetooth_searching),
        tooltip: 'Scan',
        onPressed: p.startScan,
      ),
  ];
}

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<DeviceProvider>();
    final scanning = p.bleState == BleState.scanning;
    final connecting = p.bleState == BleState.connecting;
    final connected = p.bleState == BleState.connected;

    return Scaffold(
      appBar: AppBar(
        title: appBarTitle('Scanner', icon: Icons.bluetooth_searching),
        backgroundColor: const Color(0xFF1A3A7A),
        actions: bleAppBarActions(p, context),
      ),
      body: CarbonBackground(child: Stack(
        children: [
          Column(
        children: [
          // ── Status banner ────────────────────────────────────────────────────
          if (scanning) _ScanBanner(),
          if (connecting || connected)
            Container(
              width: double.infinity,
              color: connected ? Colors.green.shade800 : Colors.orange.shade800,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Text(
                p.statusMessage,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          // ── Device list / connected view ─────────────────────────────────────
          Expanded(
            child: connected
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.bluetooth_connected,
                          size: 72,
                          color: Color(0xFF1A3A7A),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          p.statusMessage,
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : p.scanResults.isEmpty
                ? const Center(
                    child: Text(
                      'No devices found.\nMake sure the Stompbox is powered on.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    itemCount: p.scanResults.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final dev = p.scanResults[i];
                      return ListTile(
                        leading: const Icon(
                          Icons.bluetooth,
                          color: Color(0xFF1A3A7A),
                        ),
                        title: Text(
                          dev.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          dev.address,
                          style: const TextStyle(fontSize: 12),
                        ),
                        onTap: () => p.connectToDevice(dev.device),
                      );
                    },
                  ),
          ),
        ],
          ),
          if (p.connectionLoading)
            const Positioned.fill(
              child: Center(
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    strokeWidth: 6,
                    color: Colors.white38,
                  ),
                ),
              ),
            ),
        ],
      )),
    );
  }
}

class _ScanBanner extends StatefulWidget {
  @override
  State<_ScanBanner> createState() => _ScanBannerState();
}

class _ScanBannerState extends State<_ScanBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Color?> _color;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _color = ColorTween(
      begin: const Color(0xFF1A3A7A),
      end: Colors.white,
    ).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _color,
      builder: (context, child) => Container(
        width: double.infinity,
        color: _color.value,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          'Scanning…',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _color.value == Colors.white ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }
}
