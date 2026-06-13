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

class SongScreen extends StatefulWidget {
  const SongScreen({super.key});
  @override
  State<SongScreen> createState() => _SongScreenState();
}

class _SongScreenState extends State<SongScreen> {
  bool _editingChain = false;
  bool _showAdvanced = false;
  bool _hasUnsavedChanges = false;
  int _lastSongLoadCount = -1;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<DeviceProvider>();
    if (p.songLoadCount != _lastSongLoadCount) {
      _lastSongLoadCount = p.songLoadCount;
      _hasUnsavedChanges = false;
    }
    final song = p.song;
    final settings = p.settings;
    final notify = () {
      if (!_hasUnsavedChanges) setState(() => _hasUnsavedChanges = true);
      p.notifyLocalSongChanged();
    };

    return Scaffold(
      appBar: AppBar(
        title: appBarTitle('Song', icon: Icons.music_note),
        backgroundColor: const Color(0xFF1A3A7A),
        actions: bleAppBarActions(p, context),
      ),
      body: CarbonBackground(child: Stack(
        children: [
          Column(
        children: [
          Expanded(
            child: ListView(
              key: ValueKey(p.songLoadCount),
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Helper: dim + block input for data fields when disconnected.
                // UI-only toggles (chains, ADVANCED header) are NOT wrapped here.
                ...() {
                  final disabled = kDisableWhenDisconnected && !p.isConnected;
                  Widget dw(Widget child) => IgnorePointer(
                    ignoring: disabled,
                    child: AnimatedOpacity(
                      opacity: disabled ? 0.35 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: child,
                    ),
                  );
                  return <Widget>[
                    Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      _NameFieldsBox(song: song, notify: notify, songNumber: p.displayedSongNumber, disabled: disabled),
                      dw(_dividerSection('MAIN LOOP')),
                    ]),
                    // Main chain: always interactive
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _editingChain = !_editingChain),
                      child: Column(children: [
                        _ChainDiagram(song: song, settings: settings, notify: notify),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            _editingChain ? 'tap to hide controls' : 'tap to view controls',
                            style: TextStyle(fontSize: 9, color: Colors.grey.shade600, letterSpacing: 0.5),
                          ),
                        ),
                      ]),
                    ),
                    // Loop source rows (edit mode): dim when disconnected
                    if (_editingChain)
                      dw(Column(crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: _buildLoopChain(song, settings, notify))),
                    // AUX section
                    if (List.generate(4, (i) => settings.getAuxName(i)).any((n) => n.isNotEmpty)) ...[
                      dw(_dividerSection('AUX OUTPUTS', topPadding: 0)),
                      for (int i = 0; i < 4; i++)
                        if (settings.getAuxName(i).isNotEmpty) ...[
                          // AUX chain: always interactive
                          if (song.getMatrix(i + 8) != 0)
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => setState(() => _editingChain = !_editingChain),
                              child: Column(children: [
                                _AuxChainDiagram(
                                  auxName: settings.getAuxName(i),
                                  auxMatIdx: i + 8,
                                  song: song,
                                  settings: settings,
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    _editingChain ? 'tap to hide controls' : 'tap to view controls',
                                    style: TextStyle(fontSize: 9, color: Colors.grey.shade600, letterSpacing: 0.5),
                                  ),
                                ),
                              ]),
                            ),
                          // AUX source dropdown (edit mode): dim when disconnected
                          if (_editingChain)
                            dw(_matrixDropField(i + 8, '${settings.getAuxName(i)} ←', song, settings, notify, divider: false, labelAlign: TextAlign.right)),
                        ],
                    ],
                    // Backlight: dim when disconnected
                    dw(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      _dividerSection('BACKLIGHT'),
                      _colorField('', song.backlight, (v) { song.backlight = v; notify(); }),
                    ])),
                    // ADVANCED toggle: always interactive
                    InkWell(
                      onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        child: Row(children: [
                          const Expanded(child: Divider(color: Colors.grey, thickness: 0.4)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Text('ADVANCED', style: TextStyle(fontSize: 16, letterSpacing: 2, color: Colors.grey.shade500)),
                              const SizedBox(width: 6),
                              AnimatedRotation(
                                turns: _showAdvanced ? 0.5 : 0,
                                duration: const Duration(milliseconds: 200),
                                child: Icon(Icons.keyboard_arrow_down, size: 24, color: Colors.grey.shade500),
                              ),
                            ]),
                          ),
                          const Expanded(child: Divider(color: Colors.grey, thickness: 0.4)),
                        ]),
                      ),
                    ),
                    // Advanced content: dim when disconnected
                    if (_showAdvanced)
                      dw(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        _dividerSection('FOOTSWITCHES'),
                        _FswRow(
                          initialValue: song.footswitch,
                          names: List.generate(6, (i) {
                            final n = settings.getFswName(i);
                            return n.isNotEmpty ? n : 'Fsw ${i + 1}';
                          }),
                          onChange: (v) { song.footswitch = v; notify(); },
                        ),
                        _dividerSection('TRICK SHOT'),
                        _trickModeDropField('Mode', song.trickMode, (v) { song.trickMode = v; notify(); }),
                        ..._trickDataWidgets(song.trickMode, song.trickData, settings, notify, (v) { song.trickData = v; }),
                        _dividerSection('DIVE BOMB'),
                        _trickModeDropField('Mode', song.diveBombMode, (v) { song.diveBombMode = v; notify(); }),
                        ..._trickDataWidgets(song.diveBombMode, song.diveBombData, settings, notify, (v) { song.diveBombData = v; }),
                        _dividerSection('LOCAL BACKUP'),
                        _LocalBackupButtons(),
                      ])),
                    const SizedBox(height: 24),
                  ];
                }(),
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
                        onPressed: p.isConnected ? () async {
                          if (_hasUnsavedChanges) {
                            final cont = await _showUnsavedChangesDialog(context);
                            if (!cont || !mounted) return;
                            setState(() => _hasUnsavedChanges = false);
                          }
                          HapticFeedback.mediumImpact();
                          p.prevSong();
                        } : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: p.isConnected ? () {
                          p.updateSongToDevice();
                          setState(() => _hasUnsavedChanges = false);
                        } : null,
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
                        onPressed: p.isConnected ? () async {
                          if (_hasUnsavedChanges) {
                            final cont = await _showUnsavedChangesDialog(context);
                            if (!cont || !mounted) return;
                            setState(() => _hasUnsavedChanges = false);
                          }
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
      )),
    );
  }

  Future<bool> _showUnsavedChangesDialog(BuildContext ctx) async {
    final result = await showGeneralDialog<bool>(
      context: ctx,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.75),
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (context, anim, _, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: anim, child: child),
      ),
      pageBuilder: (context, _, _) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B3E),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.amber.shade600, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.18),
                  blurRadius: 32,
                  spreadRadius: 6,
                ),
                const BoxShadow(color: Colors.black54, blurRadius: 16),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.amber.shade400, size: 52),
                const SizedBox(height: 14),
                Text(
                  'CHANGES DETECTED',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: Colors.amber.shade300,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'You have unsaved edits that have not been sent to the device.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14, color: Color(0xFFBCC8DC), height: 1.5),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_back, size: 17),
                  label: const Text('GO BACK TO UPDATE',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A3A7A),
                    foregroundColor: const Color(0xFFBCC8DC),
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  icon: Icon(Icons.skip_next,
                      size: 17, color: Colors.red.shade300),
                  label: Text('CONTINUE & LOSE CHANGES',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: Colors.red.shade300)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.shade700),
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return result ?? false;
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
  final bool disabled;

  const _NameFieldsBox({required this.song, required this.notify, required this.songNumber, this.disabled = false});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final scale = isLandscape ? 0.5 : 1.0;
    final boxWidth = screenWidth * 0.55 * scale;
    final rowHeight = screenWidth * 0.124 * scale;
    final dur = const Duration(milliseconds: 300);
    final labelColor = disabled ? Colors.grey.shade700 : Colors.grey;
    final boxColor = disabled
        ? Color.lerp(_backlightToColor(song.backlight), const Color(0xFF0E0E0E), 0.65)!
        : _backlightToColor(song.backlight);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedOpacity(
              opacity: disabled ? 0.35 : 1.0,
              duration: dur,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: rowHeight,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Name line 1:', style: TextStyle(fontSize: 10, color: labelColor)),
                    ),
                  ),
                  SizedBox(
                    height: rowHeight,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Name line 2:', style: TextStyle(fontSize: 10, color: labelColor)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: boxWidth,
              child: AnimatedContainer(
                duration: dur,
                height: screenWidth * 0.28 * scale,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: boxColor,
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Stack(
                  children: [
                    // Watermark number — centered in box
                    Positioned.fill(
                      child: AnimatedOpacity(
                        opacity: disabled ? 0.35 : 1.0,
                        duration: dur,
                        child: Center(
                          child: Text(
                            '$songNumber',
                            style: TextStyle(
                              fontSize: 128 * scale,
                              fontWeight: FontWeight.bold,
                              color: Colors.black.withValues(alpha: 0.16),
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // "- CONTROL FREEK -" label
                    Positioned(
                      top: rowHeight * 0.05 + 10,
                      left: 8,
                      right: 8,
                      child: AnimatedOpacity(
                        opacity: disabled ? 0.35 : 1.0,
                        duration: dur,
                        child: Text(
                          '- CONTROL FREEK -',
                          style: TextStyle(
                            fontSize: rowHeight * 0.261,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                    // Name line 1
                    Positioned(
                      top: rowHeight * 0.40 - 7,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        ignoring: disabled,
                        child: AnimatedOpacity(
                          opacity: disabled ? 0.35 : 1.0,
                          duration: dur,
                          child: _inputField(song.name, (v) { song.name = v; notify(); }, rowHeight),
                        ),
                      ),
                    ),
                    // Name line 2
                    Positioned(
                      top: rowHeight * 1.40 - 20,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        ignoring: disabled,
                        child: AnimatedOpacity(
                          opacity: disabled ? 0.35 : 1.0,
                          duration: dur,
                          child: _inputField(song.partname, (v) { song.partname = v; notify(); }, rowHeight),
                        ),
                      ),
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

  Widget _inputField(String value, void Function(String) onChange, double rowHeight) =>
      SizedBox(
        height: rowHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: TextFormField(
            initialValue: value.toUpperCase(),
            maxLength: 31,
            style: TextStyle(fontSize: rowHeight * 0.668, fontWeight: FontWeight.bold, color: Colors.black),
            cursorColor: Colors.black,
            textAlign: TextAlign.left,
            textAlignVertical: TextAlignVertical.top,
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

// ─── Chain diagram ────────────────────────────────────────────────────────────

List<({int matIdx, String label})> _getChainOrder(SongModel song, SettingsModel s) {
  if (song.getMatrix(0) != 0) {
    // Main Out has a source — follow backwards from Main Out
    final chain = <({int matIdx, String label})>[];
    int src = song.getMatrix(0);
    final visited = <int>{};
    while (true) {
      final i = _loopSourceValues.indexOf(src);
      if (i < 0 || visited.contains(i)) break;
      visited.add(i);
      final n = s.getLoopName(i);
      chain.add((matIdx: i + 1, label: n.isNotEmpty ? n : 'Loop ${i + 1}'));
      src = song.getMatrix(i + 1);
    }
    return chain; // [Loop3, Loop1, ...] — reversed in display for signal flow
  }

  // Main Out not used — forward traversal from the loop that sources MAIN IN
  int? curr;
  for (int i = 0; i < 7; i++) {
    if (song.getMatrix(i + 1) == 1) { curr = i; break; }
  }
  if (curr == null) return [];

  final fwd = <({int matIdx, String label})>[];
  final visited = <int>{};
  while (curr != null) {
    if (visited.contains(curr)) break;
    visited.add(curr);
    final n = s.getLoopName(curr);
    fwd.add((matIdx: curr + 1, label: n.isNotEmpty ? n : 'Loop ${curr + 1}'));
    final outVal = _loopSourceValues[curr];
    curr = null;
    for (int i = 0; i < 7; i++) {
      if (!visited.contains(i) && song.getMatrix(i + 1) == outVal) {
        curr = i;
        break;
      }
    }
  }
  // fwd is signal-flow order [Loop1, Loop3] — reverse so display's .reversed gives correct order
  return fwd.reversed.toList();
}


class _ChainDiagram extends StatelessWidget {
  final SongModel song;
  final SettingsModel settings;
  final VoidCallback notify;

  const _ChainDiagram({required this.song, required this.settings, required this.notify});

  @override
  Widget build(BuildContext context) {
    final chain = _getChainOrder(song, settings);
    final noSource = song.getMatrix(0) == 0;

    // Signal-flow order: MAIN IN → [loops] → MAIN OUT
    // matIdx -1 = MAIN IN (not tappable)
    final items = [
      (matIdx: -1, label: 'MAIN IN'),
      ...chain.reversed.map((e) => (matIdx: e.matIdx, label: e.label)),
      (matIdx: 0, label: 'MAIN OUT'),
    ];

    const boxH = 34.0;
    const arrowW = 18.0;
    const hPad = 8.0;
    const minBoxW = 28.0;
    const labelStyle = TextStyle(fontSize: 8, height: 1.1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Measure natural single-line width of each box
          double naturalTotal = (items.length - 1) * arrowW;
          for (final item in items) {
            final tp = TextPainter(
              text: TextSpan(text: item.label, style: labelStyle),
              textDirection: TextDirection.ltr,
              maxLines: 1,
            )..layout();
            final w = tp.size.width + hPad;
            naturalTotal += w < minBoxW ? minBoxW : w;
          }

          // Only wrap labels that contain a space, and only when overflow occurs
          final wrap = naturalTotal > constraints.maxWidth;

          return SizedBox(
            height: boxH,
            width: constraints.maxWidth,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < items.length; i++) ...[
                    if (i > 0)
                      _ChainArrow(
                        width: arrowW,
                        hasX: noSource && i == items.length - 1,
                      ),
                    _ChainBox(
                      label: items[i].label,
                      wrap: wrap,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChainBox extends StatelessWidget {
  final String label;
  final bool wrap;

  const _ChainBox({required this.label, this.wrap = false});

  @override
  Widget build(BuildContext context) {
    final displayLabel =
        (wrap && label.contains(' ')) ? label.replaceAll(' ', '\n') : label;
    return Container(
        height: 34,
        constraints: const BoxConstraints(minWidth: 28),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade700, width: 0.75),
          borderRadius: BorderRadius.circular(5),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          displayLabel,
          textAlign: TextAlign.center,
          textHeightBehavior: const TextHeightBehavior(
            applyHeightToFirstAscent: false,
            applyHeightToLastDescent: false,
          ),
          style: const TextStyle(fontSize: 8, color: Colors.grey, height: 1.1),
        ),
    );
  }
}

class _ChainArrow extends StatelessWidget {
  final double width;
  final bool hasX;

  const _ChainArrow({required this.width, this.hasX = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 34,
      child: CustomPaint(painter: _ChainArrowPainter(hasX: hasX)),
    );
  }
}

class _ChainArrowPainter extends CustomPainter {
  final bool hasX;
  const _ChainArrowPainter({this.hasX = false});

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final linePaint = Paint()
      ..color = Colors.grey.shade700
      ..strokeWidth = 0.75
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), linePaint);

    // Arrowhead pointing right
    const ah = 3.0;
    canvas.drawLine(Offset(size.width, midY), Offset(size.width - ah, midY - ah), linePaint);
    canvas.drawLine(Offset(size.width, midY), Offset(size.width - ah, midY + ah), linePaint);

    if (hasX) {
      const xr = 3.5;
      final cx = size.width / 2;
      final xPaint = Paint()
        ..color = Colors.red.shade400
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(cx - xr, midY - xr), Offset(cx + xr, midY + xr), xPaint);
      canvas.drawLine(Offset(cx + xr, midY - xr), Offset(cx - xr, midY + xr), xPaint);
    }
  }

  @override
  bool shouldRepaint(_ChainArrowPainter old) => old.hasX != hasX;
}

// ─── AUX chain diagram ────────────────────────────────────────────────────────

class _AuxChainDiagram extends StatelessWidget {
  final String auxName;
  final int auxMatIdx;
  final SongModel song;
  final SettingsModel settings;

  const _AuxChainDiagram({
    required this.auxName,
    required this.auxMatIdx,
    required this.song,
    required this.settings,
  });

  List<String> _buildItems() {
    final auxSrc = song.getMatrix(auxMatIdx);
    if (auxSrc == 0) return [];

    // Trace backward from AUX source through each loop's source until MAIN IN
    final chain = <String>[];
    int src = auxSrc;
    final visited = <int>{};
    while (true) {
      final i = _loopSourceValues.indexOf(src);
      if (i < 0 || visited.contains(i)) break; // src == MAIN IN or cycle
      visited.add(i);
      final n = settings.getLoopName(i);
      chain.add(n.isNotEmpty ? n : 'Loop ${i + 1}');
      src = song.getMatrix(i + 1);
    }

    return ['MAIN IN', ...chain.reversed, auxName];
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildItems();
    if (items.isEmpty) return const SizedBox.shrink();

    const boxH = 34.0;
    const arrowW = 18.0;
    const hPad = 8.0;
    const minBoxW = 28.0;
    const labelStyle = TextStyle(fontSize: 8, height: 1.1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double naturalTotal = (items.length - 1) * arrowW;
          for (final label in items) {
            final tp = TextPainter(
              text: TextSpan(text: label, style: labelStyle),
              textDirection: TextDirection.ltr,
              maxLines: 1,
            )..layout();
            final w = tp.size.width + hPad;
            naturalTotal += w < minBoxW ? minBoxW : w;
          }
          final wrap = naturalTotal > constraints.maxWidth;

          return SizedBox(
            height: boxH,
            width: constraints.maxWidth,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < items.length; i++) ...[
                    if (i > 0) const _ChainArrow(width: arrowW),
                    _ChainBox(label: items[i], wrap: wrap),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Chain rows ───────────────────────────────────────────────────────────────

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
