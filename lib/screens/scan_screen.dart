import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../device_provider.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeviceProvider>().startScan();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<DeviceProvider>();
    final scanning = p.bleState == BleState.scanning;
    final connecting = p.bleState == BleState.connecting;
    final connected = p.bleState == BleState.connected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stompbox Scanner'),
        backgroundColor: const Color(0xFF1c56f3),
        actions: [
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
        ],
      ),
      body: Column(
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
                          color: Color(0xFF1c56f3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          p.statusMessage,
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Use Settings and Song tabs to configure the device.',
                          style: TextStyle(color: Colors.grey),
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
                          color: Color(0xFF1c56f3),
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
      begin: const Color(0xFF1c56f3),
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
