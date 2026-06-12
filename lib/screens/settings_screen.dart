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
        title: const Text('System Settings'),
        backgroundColor: const Color(0xFF1c56f3),
        actions: bleAppBarActions(p),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              key: ValueKey(p.configLoadCount),
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // _section('General'),
                // _numField('Backlight', s.backlight, (v) => s.backlight = v),
                // _numField('Current Song', s.currentSong, (v) => s.currentSong = v),
                _section('Loop Names'),
                for (int i = 0; i < 7; i++)
                  _strField('Loop ${i + 1} Name:', s.getLoopName(i),
                      (v) => s.setLoopName(i, v)),
                _section('Aux Output Names'),
                for (int i = 0; i < 4; i++)
                  _strField('Aux${i + 1} Name:', s.getAuxName(i),
                      (v) => s.setAuxName(i, v)),
                _section('Footswitch Names'),
                for (int i = 0; i < 6; i++)
                  _strField('Fsw${i + 1} Name:', s.getFswName(i),
                      (v) => s.setFswName(i, v)),
                const SizedBox(height: 80),
              ],
            ),
          ),
          _UpdateButton(
            label: 'Update Settings',
            enabled: p.isConnected,
            onPressed: p.updateConfigToDevice,
          ),
        ],
      ),
    );
  }
}

Widget _section(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 1),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(color: Colors.grey.shade800, width: 0.5)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(fontSize: 16, color: Colors.grey)),
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: enabled ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1c56f3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(label,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
