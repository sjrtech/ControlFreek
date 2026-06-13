import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../device_provider.dart';
import '../models.dart';
import 'scan_screen.dart';

// 2 bits per channel: R=bits[5:4], G=bits[3:2], B=bits[1:0]
// Values from ControlFreek myappgui.h
const _colorValues = [0, 48, 3, 12, 51, 60, 15, 63];
const _colorNames = ['Off', 'Red', 'Blue', 'Green', 'Red/Blue', 'Red/Green', 'Blue/Green', 'White'];

int _backlightIndex(int raw) {
  final i = _colorValues.indexOf(raw);
  return i >= 0 ? i : 0;
}

// Convert the 2-bit-per-channel backlight byte to a pastel Flutter Color.
// Bits[5:4]=R, [3:2]=G, [1:0]=B; each 2-bit value → 0/85/170/255.
// Off (0) → light gray. Colors are blended 70% toward white for readability.
Color _backlightToColor(int raw) {
  final r = ((raw >> 4) & 0x3) * 85;
  final g = ((raw >> 2) & 0x3) * 85;
  final b = (raw & 0x3) * 85;
  if (r == 0 && g == 0 && b == 0) return Colors.grey.shade200;
  return Color.fromRGBO(
    r + ((255 - r) * 0.7).round(),
    g + ((255 - g) * 0.7).round(),
    b + ((255 - b) * 0.7).round(),
    1.0,
  );
}

const _trickModeNames = [
  'Off',              // 0
  'Song - Latch',     // 1
  'Song - Momentary', // 2
  'Loop - Latch',     // 3
  'Loop - Momentary', // 4
  'FSW - Latch',      // 5
  'FSW - Momentary',  // 6
  'MIDI Message',     // 7
];

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
        title: appBarTitle('Song', icon: Icons.music_note),
        backgroundColor: const Color(0xFF1A3A7A),
        actions: bleAppBarActions(p),
      ),
      body: Stack(
        children: [
          Column(
        children: [
          Expanded(
            child: ListView(
              key: ValueKey(p.songLoadCount),
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                IgnorePointer(
                  ignoring: kDisableWhenDisconnected && !p.isConnected,
                  child: AnimatedOpacity(
                    opacity: kDisableWhenDisconnected && !p.isConnected ? 0.35 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _NameFieldsBox(song: song, notify: notify, songNumber: p.displayedSongNumber),
                        _dividerSection('LOOPS'),
                        ..._buildLoopChain(song, settings, notify),
                        _dividerSection('AUX', topPadding: 0),
                        for (int i = 0; i < 4; i++)
                          if (settings.getAuxName(i).isNotEmpty)
                            _matrixDropField(i + 8, '${settings.getAuxName(i)} ←', song, settings, notify, divider: false, labelAlign: TextAlign.right),
                        _dividerSection('FOOTSWITCH'),
                        _FswRow(
                          initialValue: song.footswitch,
                          names: List.generate(6, (i) {
                            final n = settings.getFswName(i);
                            return n.isNotEmpty ? n : 'Fsw ${i + 1}';
                          }),
                          onChange: (v) { song.footswitch = v; notify(); },
                        ),
                        _dividerSection('BACKLIGHT'),
                        _colorField('', song.backlight, (v) { song.backlight = v; notify(); }),
                        _dividerSection('TRICK SHOT'),
                        _trickModeDropField('Mode', song.trickMode, (v) { song.trickMode = v; notify(); }),
                        ..._trickDataWidgets(song.trickMode, song.trickData, settings,
                            notify, (v) { song.trickData = v; }),
                        _dividerSection('DIVE BOMB'),
                        _trickModeDropField('Mode', song.diveBombMode, (v) { song.diveBombMode = v; notify(); }),
                        ..._trickDataWidgets(song.diveBombMode, song.diveBombData, settings,
                            notify, (v) { song.diveBombData = v; }),
                        _dividerSection('LOCAL BACKUP'),
                        _LocalBackupButtons(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          ColoredBox(
            color: const Color(0xFF0D1B3E),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Prev'),
                        onPressed: p.isConnected ? () {
                          HapticFeedback.mediumImpact();
                          p.prevSong();
                        } : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: p.isConnected ? p.updateSongToDevice : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A3A7A),
                          foregroundColor: const Color(0xFFBCC8DC),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.settings_input_component, size: 18),
                            SizedBox(width: 8),
                            Text('Update Song',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Next'),
                        onPressed: p.isConnected ? () {
                          HapticFeedback.mediumImpact();
                          p.nextSong();
                        } : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
          ),
          if (p.songLoading)
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
      ),
    );
  }
}

Widget _dividerSection(String title, {double topPadding = 14}) => Padding(
      padding: EdgeInsets.fromLTRB(12, topPadding, 12, 2),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Colors.grey)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 6,
              ),
            ),
          ),
          const Expanded(child: Divider(color: Colors.grey)),
        ],
      ),
    );


class _NameFieldsBox extends StatelessWidget {
  final SongModel song;
  final VoidCallback notify;
  final int songNumber;

  const _NameFieldsBox({required this.song, required this.notify, required this.songNumber});

  @override
  Widget build(BuildContext context) {
    final boxWidth = MediaQuery.of(context).size.width * 0.35;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 28,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Name line 1:', style: const TextStyle(fontSize: 15, color: Colors.grey)),
                  ),
                ),
                SizedBox(
                  height: 28,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Name line 2:', style: const TextStyle(fontSize: 15, color: Colors.grey)),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: boxWidth,
              child: Container(
                decoration: BoxDecoration(
                  color: _backlightToColor(song.backlight),
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '$songNumber',
                      style: TextStyle(
                        fontSize: 90,
                        fontWeight: FontWeight.bold,
                        color: Colors.black.withValues(alpha: 0.16),
                        height: 1,
                      ),
                    ),
                    Column(
                      children: [
                        _inputField(song.name, (v) { song.name = v; notify(); }),
                        _inputField(song.partname, (v) { song.partname = v; notify(); }),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(String value, void Function(String) onChange) =>
      SizedBox(
        height: 28,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: TextFormField(
            initialValue: value.toUpperCase(),
            maxLength: 31,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
            cursorColor: Colors.black,
            textAlign: TextAlign.left,
            inputFormatters: [
              TextInputFormatter.withFunction((oldValue, newValue) {
                final filtered = newValue.text
                    .toUpperCase()
                    .replaceAll(RegExp(r'[^\x20-\x5F]'), '');
                return newValue.copyWith(text: filtered);
              }),
            ],
            decoration: const InputDecoration(
              isDense: true,
              counterText: '',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: onChange,
          ),
        ),
      );
}


Widget _numField(String label, int value, void Function(int) onChange) =>
    _FieldRow(
      label: label,
      child: TextFormField(
        initialValue: value.toString(),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        maxLength: 3,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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

Widget _colorSwatch(int colorValue) => Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: _backlightToColor(colorValue),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade600),
      ),
    );

Widget _colorField(String label, int rawByte, void Function(int) onChange) =>
    _FieldRow(
      label: label,
      child: DropdownButton<int>(
        value: _backlightIndex(rawByte),
        isExpanded: true,
        underline: const SizedBox(),
        items: [
          for (int i = 0; i < _colorNames.length; i++)
            DropdownMenuItem(
              value: i,
              child: Row(
                children: [
                  _colorSwatch(_colorValues[i]),
                  const SizedBox(width: 10),
                  Text(_colorNames[i],
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
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
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
        items: [
          for (int i = 0; i < options.length; i++)
            DropdownMenuItem(value: i, child: Text(options[i])),
        ],
        onChanged: (v) {
          if (v != null) onChange(v);
        },
      ),
    );

const _trickModeIcons = [
  Icons.do_not_disturb,      // 0 Off
  Icons.music_note,          // 1 Song - Latch
  Icons.music_note,          // 2 Song - Momentary
  Icons.loop,                // 3 Loop - Latch
  Icons.loop,                // 4 Loop - Momentary
  Icons.toggle_on,           // 5 FSW - Latch
  Icons.radio_button_checked,// 6 FSW - Momentary
  Icons.piano,               // 7 MIDI Message
];

Widget _trickModeDropField(String label, int value, void Function(int) onChange) =>
    _FieldRow(
      label: label,
      child: DropdownButton<int>(
        value: value.clamp(0, _trickModeNames.length - 1),
        isExpanded: true,
        underline: const SizedBox(),
        items: [
          for (int i = 0; i < _trickModeNames.length; i++)
            DropdownMenuItem(
              value: i,
              child: Row(
                children: [
                  Icon(_trickModeIcons[i], size: 18, color: Colors.lightBlueAccent),
                  const SizedBox(width: 8),
                  Text(_trickModeNames[i],
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
        ],
        onChanged: (v) { if (v != null) onChange(v); },
      ),
    );

Widget _matrixDropField(
  int matIdx, String label, SongModel song, SettingsModel s, VoidCallback notify, {bool divider = true, TextAlign labelAlign = TextAlign.left}
) {
  final opts = _buildMatrixOptions(matIdx, s);
  final selIdx = _matrixDropIdx(song.getMatrix(matIdx), opts);
  return _FieldRow(
    label: label,
    divider: divider,
    labelAlign: labelAlign,
    child: DropdownButton<int>(
      value: selIdx,
      isExpanded: true,
      underline: const SizedBox(),
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
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

List<Widget> _buildLoopChain(SongModel song, SettingsModel s, VoidCallback notify) {
  final widgets = <Widget>[];

  widgets.add(KeyedSubtree(
    key: const ValueKey(0),
    child: _matrixDropField(0, 'Main Out ←', song, s, notify, divider: false, labelAlign: TextAlign.right),
  ));

  int currentSource = song.getMatrix(0);
  final visited = <int>{};

  while (true) {
    final loopIdx = _loopSourceValues.indexOf(currentSource);
    if (loopIdx < 0 || visited.contains(loopIdx)) break;
    visited.add(loopIdx);
    final matIdx = loopIdx + 1;
    final name = s.getLoopName(loopIdx);
    final displayName = name.isNotEmpty ? name : 'Loop ${loopIdx + 1}';
    widgets.add(KeyedSubtree(
      key: ValueKey(matIdx),
      child: _matrixDropField(matIdx, '$displayName ←', song, s, notify, divider: false, labelAlign: TextAlign.right),
    ));
    currentSource = song.getMatrix(matIdx);
  }

  // Append any named loops not reached by the chain
  for (int i = 0; i < 7; i++) {
    if (visited.contains(i)) continue;
    final name = s.getLoopName(i);
    if (name.isEmpty) continue;
    final matIdx = i + 1;
    widgets.add(KeyedSubtree(
      key: ValueKey(matIdx),
      child: _matrixDropField(matIdx, '$name ←', song, s, notify, divider: false, labelAlign: TextAlign.right),
    ));
  }

  return widgets;
}

List<Widget> _trickDataWidgets(
  int mode, int data, SettingsModel settings, VoidCallback notify, void Function(int) set,
) {
  switch (mode) {
    case 1:
    case 2: // Song latch / momentary — song number 1-120
      return [_numField('Song #', data.clamp(1, 120), (v) { set(v.clamp(1, 120)); notify(); })];

    case 3:
    case 4: // Loop latch / momentary — dropdown of named loops
      final loops = <({String name, int index})>[];
      for (int i = 0; i < 7; i++) {
        final n = settings.getLoopName(i);
        if (n.isNotEmpty) loops.add((name: n, index: i));
      }
      if (loops.isEmpty) return [];
      final selIdx = loops.indexWhere((l) => l.index == data.clamp(0, 6));
      final safeIdx = selIdx < 0 ? 0 : selIdx;
      return [
        _FieldRow(
          label: 'Loop',
          child: DropdownButton<int>(
            value: safeIdx,
            isExpanded: true,
            underline: const SizedBox(),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
            items: [
              for (int i = 0; i < loops.length; i++)
                DropdownMenuItem(value: i, child: Text(loops[i].name)),
            ],
            onChanged: (i) { if (i != null) { set(loops[i].index); notify(); } },
          ),
        ),
      ];

    case 5:
    case 6: // FSW latch / momentary — 6-bit checkboxes
      return [
        _FswRow(
          initialValue: data,
          names: List.generate(6, (i) {
            final n = settings.getFswName(i);
            return n.isNotEmpty ? n : 'Fsw ${i + 1}';
          }),
          onChange: (v) { set(v); notify(); },
        ),
      ];

    case 7: // MIDI message slot 1-4
      return [
        _dropField('Msg #', (data.clamp(1, 4) - 1),
            ['Msg 1', 'Msg 2', 'Msg 3', 'Msg 4'],
            (v) { set(v + 1); notify(); }),
      ];

    default: // Off — no data needed
      return [];
  }
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (int i = 0; i < 6; i++)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.names[i],
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
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

class _LocalBackupButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.read<DeviceProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              child: const Text('Backup Song'),
              onPressed: () async {
                try {
                  final path = await p.saveSong();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Saved to $path')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Backup failed: $e')),
                    );
                  }
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              child: const Text('Restore Song'),
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['cfk'],
                );
                if (result == null) return;
                try {
                  final bytes = await File(result.files.single.path!).readAsBytes();
                  p.restoreSongFromBytes(bytes);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Song restored')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Restore failed: $e')),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final Widget child;
  final bool divider;
  final TextAlign labelAlign;

  const _FieldRow({required this.label, required this.child, this.divider = false, this.labelAlign = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      decoration: divider ? BoxDecoration(
        border: Border(
            bottom: BorderSide(color: Colors.grey.shade800, width: 0.5)),
      ) : null,
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(label, textAlign: labelAlign,
                  style: const TextStyle(fontSize: 15, color: Colors.grey)),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
