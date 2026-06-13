import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../device_provider.dart';
import 'scan_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<DeviceProvider>();
    final s = p.settings;

    // configLoadCount as key forces TextFormField initialValues to refresh
    // whenever a new config is received from the device.
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.settings_input_component, size: 20),
            SizedBox(width: 6),
            Text('Breakout Setup'),
          ],
        ),
        backgroundColor: const Color(0xFF1A3A7A),
        actions: bleAppBarActions(p),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
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
                              (v) => s.setLoopName(i, v)),
                        _dividerSection('AUX'),
                        for (int i = 0; i < 4; i++)
                          _strField('Aux ${i + 1}:', s.getAuxName(i),
                              (v) => s.setAuxName(i, v)),
                        _dividerSection('FOOTSWITCH'),
                        for (int i = 0; i < 6; i++)
                          _strField('Fsw ${i + 1}:', s.getFswName(i),
                              (v) => s.setFswName(i, v)),
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
    );
  }
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

Widget _strField(String label, String value, void Function(String) onChange) =>
    _FieldRow(
      label: label,
      child: TextFormField(
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

// Widget _numField(String label, int value, void Function(int) onChange) =>
//     _FieldRow(
//       label: label,
//       child: TextFormField(
//         initialValue: value.toString(),
//         keyboardType: TextInputType.number,
//         inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//         maxLength: 3,
//         style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
//         decoration: const InputDecoration(
//           isDense: true,
//           counterText: '',
//           border: InputBorder.none,
//         ),
//         onChanged: (v) {
//           final n = int.tryParse(v);
//           if (n != null) onChange(n);
//         },
//       ),
//     );

class _FieldRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _FieldRow({required this.label, required this.child});

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
