import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../device_provider.dart';
import '../models.dart';

// 2 bits per channel: R=bits[5:4], G=bits[3:2], B=bits[1:0]
// Values from ControlFreek myappgui.h
const _colorValues = [0, 48, 3, 12, 51, 60, 15, 63];
const _colorNames = ['Off', 'Red', 'Blue', 'Green', 'Red/Blue', 'Red/Green', 'Blue/Green', 'White'];

int _backlightIndex(int raw) {
  final i = _colorValues.indexOf(raw);
  return i >= 0 ? i : 0;
}

const _trickModeNames = ['Off', 'Jump to Song', 'Latch Footswitch', 'Momentary Footswitch'];

// Matrix source byte values: 0=not used, 1=MAIN IN, 2=Loop1, 4=Loop2, ..., 128=Loop7
const _loopSourceValues = [2, 4, 8, 16, 32, 64, 128];
// Which source value each matrix slot excludes (its own loop output)
const _matrixSelfValue = [0, 2, 4, 8, 16, 32, 64, 128, 0, 0, 0, 0];

typedef _MatOpt = ({String name, int value});

List<_MatOpt> _buildMatrixOptions(int matIdx, SettingsModel s) {
  final skipValue = _matrixSelfValue[matIdx];
  final opts = <_MatOpt>[
    (name: '*not used*', value: 0),
    (name: 'MAIN IN', value: 1),
  ];
  for (int i = 0; i < 7; i++) {
    final srcVal = _loopSourceValues[i];
    if (srcVal == skipValue) continue;
    final nm = s.getLoopName(i);
    if (nm.isNotEmpty) opts.add((name: nm, value: srcVal));
  }
  return opts;
}

int _matrixDropIdx(int byteValue, List<_MatOpt> opts) {
  for (int i = 0; i < opts.length; i++) {
    if (opts[i].value == byteValue) return i;
  }
  return 0;
}

class SongScreen extends StatelessWidget {
  const SongScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<DeviceProvider>();
    final song = p.song;
    final settings = p.settings;
    final notify = p.notifyLocalSongChanged;

    return Scaffold(
      appBar: AppBar(
        title: Text('Song ${settings.currentSong}'),
        backgroundColor: const Color(0xFF1c56f3),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              key: ValueKey(p.songLoadCount),
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _section('Song Info'),
                _strField('Song Name', song.name, (v) { song.name = v; notify(); }, maxLen: 31),
                _strField('Part', song.partname, (v) { song.partname = v; notify(); }, maxLen: 31),
                _section('Footswitches'),
                _FswRow(
                  initialValue: song.footswitch,
                  names: List.generate(6, (i) {
                    final n = settings.getFswName(i);
                    return n.isNotEmpty ? n : 'Fsw ${i + 1}';
                  }),
                  onChange: (v) { song.footswitch = v; notify(); },
                ),
                _section('Backlight'),
                _colorField('Color', song.backlight, (v) { song.backlight = v; notify(); }),
                _section('Trick Shot'),
                _dropField('Mode', song.trickMode.clamp(0, _trickModeNames.length - 1),
                    _trickModeNames, (v) { song.trickMode = v; notify(); }),
                _numField('Data', song.trickData, (v) { song.trickData = v; notify(); }),
                _section('Dive Bomb'),
                _dropField('Mode', song.diveBombMode.clamp(0, _trickModeNames.length - 1),
                    _trickModeNames, (v) { song.diveBombMode = v; notify(); }),
                _numField('Data', song.diveBombData, (v) { song.diveBombData = v; notify(); }),
                _section('Matrix'),
                _matrixDropField(0, 'Main Out ←', song, settings, notify),
                for (int i = 0; i < 7; i++)
                  if (settings.getLoopName(i).isNotEmpty)
                    _matrixDropField(i + 1, '${settings.getLoopName(i)} ←', song, settings, notify),
                for (int i = 0; i < 4; i++)
                  if (settings.getAuxName(i).isNotEmpty)
                    _matrixDropField(i + 8, '${settings.getAuxName(i)} ←', song, settings, notify),
                const SizedBox(height: 80),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Prev'),
                      onPressed: p.isConnected ? p.prevSong : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: p.isConnected ? p.updateSongToDevice : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1c56f3),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Update Song',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Next'),
                      onPressed: p.isConnected ? p.nextSong : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _section(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 2),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );

Widget _strField(String label, String value, void Function(String) onChange,
        {int maxLen = 31}) =>
    _FieldRow(
      label: label,
      child: TextFormField(
        initialValue: value,
        maxLength: maxLen,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(
          isDense: true,
          counterText: '',
          border: InputBorder.none,
        ),
        onChanged: onChange,
      ),
    );

Widget _numField(String label, int value, void Function(int) onChange) =>
    _FieldRow(
      label: label,
      child: TextFormField(
        initialValue: value.toString(),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        maxLength: 3,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(
          isDense: true,
          counterText: '',
          border: InputBorder.none,
        ),
        onChanged: (v) {
          final n = int.tryParse(v);
          if (n != null) onChange(n);
        },
      ),
    );

Widget _colorField(String label, int rawByte, void Function(int) onChange) =>
    _FieldRow(
      label: label,
      child: DropdownButton<int>(
        value: _backlightIndex(rawByte),
        isExpanded: true,
        underline: const SizedBox(),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        items: [
          for (int i = 0; i < _colorNames.length; i++)
            DropdownMenuItem(value: i, child: Text(_colorNames[i])),
        ],
        onChanged: (i) {
          if (i != null) onChange(_colorValues[i]);
        },
      ),
    );

Widget _dropField(
        String label, int value, List<String> options, void Function(int) onChange) =>
    _FieldRow(
      label: label,
      child: DropdownButton<int>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        items: [
          for (int i = 0; i < options.length; i++)
            DropdownMenuItem(value: i, child: Text(options[i])),
        ],
        onChanged: (v) {
          if (v != null) onChange(v);
        },
      ),
    );

Widget _matrixDropField(
  int matIdx, String label, SongModel song, SettingsModel s, VoidCallback notify,
) {
  final opts = _buildMatrixOptions(matIdx, s);
  final selIdx = _matrixDropIdx(song.getMatrix(matIdx), opts);
  return _FieldRow(
    label: label,
    child: DropdownButton<int>(
      value: selIdx,
      isExpanded: true,
      underline: const SizedBox(),
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      items: [
        for (int i = 0; i < opts.length; i++)
          DropdownMenuItem(value: i, child: Text(opts[i].name)),
      ],
      onChanged: (i) {
        if (i != null) {
          song.setMatrix(matIdx, opts[i].value);
          notify();
        }
      },
    ),
  );
}

class _FswRow extends StatefulWidget {
  final int initialValue;
  final List<String> names;
  final void Function(int) onChange;

  const _FswRow({
    required this.initialValue,
    required this.names,
    required this.onChange,
  });

  @override
  State<_FswRow> createState() => _FswRowState();
}

class _FswRowState extends State<_FswRow> {
  late int _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade800, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (int i = 0; i < 6; i++)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.names[i],
                    style: const TextStyle(fontSize: 10, color: Colors.grey)),
                Checkbox(
                  value: (_value >> i) & 1 == 1,
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _value = v ? _value | (1 << i) : _value & ~(1 << i);
                    });
                    widget.onChange(_value);
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _FieldRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(color: Colors.grey.shade800, width: 0.5)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
