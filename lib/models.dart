import 'dart:typed_data';
import 'dart:convert';

// ─── Size constants ────────────────────────────────────────────────────────────
const int kSongSize = 100; // sizeof(SONG)
const int kSettingsSize = 224; // sizeof(SETTINGS)
const int kSongBlocks = 25; // kSongSize / 4
const int kSettingsBlocks = 56; // kSettingsSize / 4
const int kFillMarker = 0xa5;

// ─── SONG struct field offsets (mirrors myappgui.h) ───────────────────────────
// isFilled       [0]      1 byte
// name           [1..32]  32 bytes
// partname       [33..64] 32 bytes
// midiMessage1   [65..67] 3 bytes
// midiMessage2   [68..70] 3 bytes
// midiMessage3   [71..73] 3 bytes
// midiMessage4   [74..76] 3 bytes
// midiMsgMode    [77]     1 byte
// matrix         [78..89] 12 bytes
// footswitch     [90]     1 byte
// trickMode      [91..93] 3 bytes
// trickData      [94..96] 3 bytes
// lcdBacklight   [97]     1 byte
// Dummy          [98..99] 2 bytes

String _nullStr(Uint8List data, int offset, int maxLen) {
  final slice = data.sublist(offset, offset + maxLen);
  final end = slice.indexOf(0);
  return latin1.decode(end < 0 ? slice : slice.sublist(0, end));
}

void _writeStr(Uint8List data, int offset, int maxLen, String value) {
  final bytes = latin1.encode(value);
  final len = bytes.length < maxLen - 1 ? bytes.length : maxLen - 1;
  for (int i = 0; i < len; i++) {
    data[offset + i] = bytes[i];
  }
  data[offset + len] = 0;
}

String _midiToString(List<int> midi) => midi
    .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
    .join(' ');

List<int> _stringToMidi(String s) {
  final parts = s.trim().split(RegExp(r'[\s,]+'));
  return List.generate(
    3,
    (i) =>
        i < parts.length ? (int.tryParse(parts[i], radix: 16) ?? 0) & 0xff : 0,
  );
}

class SongModel {
  final Uint8List bytes;

  SongModel() : bytes = Uint8List(kSongSize);

  SongModel.fromBytes(Uint8List data)
    : bytes = Uint8List(kSongSize)
        ..setRange(0, data.length < kSongSize ? data.length : kSongSize, data);

  bool get isFilled => bytes[0] == kFillMarker;

  String get name => _nullStr(bytes, 1, 32);
  set name(String v) => _writeStr(bytes, 1, 32, v);

  String get partname => _nullStr(bytes, 33, 32);
  set partname(String v) => _writeStr(bytes, 33, 32, v);

  List<int> get midiMessage1 => bytes.sublist(65, 68).toList();
  set midiMessage1(List<int> v) {
    for (int i = 0; i < 3; i++) {
      bytes[65 + i] = i < v.length ? v[i] & 0xff : 0;
    }
  }

  String get midiMsg1Str => _midiToString(midiMessage1);
  set midiMsg1Str(String v) => midiMessage1 = _stringToMidi(v);

  List<int> get midiMessage2 => bytes.sublist(68, 71).toList();
  set midiMessage2(List<int> v) {
    for (int i = 0; i < 3; i++) {
      bytes[68 + i] = i < v.length ? v[i] & 0xff : 0;
    }
  }

  String get midiMsg2Str => _midiToString(midiMessage2);
  set midiMsg2Str(String v) => midiMessage2 = _stringToMidi(v);

  List<int> get midiMessage3 => bytes.sublist(71, 74).toList();
  set midiMessage3(List<int> v) {
    for (int i = 0; i < 3; i++) {
      bytes[71 + i] = i < v.length ? v[i] & 0xff : 0;
    }
  }

  String get midiMsg3Str => _midiToString(midiMessage3);
  set midiMsg3Str(String v) => midiMessage3 = _stringToMidi(v);

  List<int> get midiMessage4 => bytes.sublist(74, 77).toList();
  set midiMessage4(List<int> v) {
    for (int i = 0; i < 3; i++) {
      bytes[74 + i] = i < v.length ? v[i] & 0xff : 0;
    }
  }

  String get midiMsg4Str => _midiToString(midiMessage4);
  set midiMsg4Str(String v) => midiMessage4 = _stringToMidi(v);

  int get midiMode => bytes[77];
  set midiMode(int v) => bytes[77] = v & 0xff;

  int getMatrix(int i) => bytes[78 + i];
  void setMatrix(int i, int v) => bytes[78 + i] = v & 0xff;

  int get footswitch => bytes[90];
  set footswitch(int v) => bytes[90] = v & 0xff;

  int get trickMode => bytes[91];
  set trickMode(int v) => bytes[91] = v & 0xff;

  int get trickData => bytes[94];
  set trickData(int v) => bytes[94] = v & 0xff;

  int get diveBombMode => bytes[92];
  set diveBombMode(int v) => bytes[92] = v & 0xff;

  int get diveBombData => bytes[95];
  set diveBombData(int v) => bytes[95] = v & 0xff;

  int get backlight => bytes[97];
  set backlight(int v) => bytes[97] = v & 0xff;
}

// ─── SETTINGS struct field offsets (mirrors myappgui.h) ──────────────────────
// isFilled       [0]        1 byte
// lcdBacklight   [1]        1 byte
// currentSong    [2]        1 byte
// loopName[7][12][3..86]   84 bytes
// loopBacklite[7][87..93]   7 bytes
// fswName[6][12] [94..165] 72 bytes
// fswBacklite[6] [166..171] 6 bytes
// auxOutName[4][12][172..219] 48 bytes
// auxBacklite[4] [220..223] 4 bytes

class SettingsModel {
  final Uint8List bytes;

  SettingsModel() : bytes = Uint8List(kSettingsSize);

  SettingsModel.fromBytes(Uint8List data)
    : bytes = Uint8List(kSettingsSize)
        ..setRange(
          0,
          data.length < kSettingsSize ? data.length : kSettingsSize,
          data,
        );

  bool get isFilled => bytes[0] == kFillMarker;

  int get backlight => bytes[1];
  set backlight(int v) => bytes[1] = v & 0xff;

  int get currentSong => bytes[2];
  set currentSong(int v) => bytes[2] = v & 0xff;

  String getLoopName(int i) => _nullStr(bytes, 3 + i * 12, 12);
  void setLoopName(int i, String v) => _writeStr(bytes, 3 + i * 12, 12, v);

  String getFswName(int i) => _nullStr(bytes, 94 + i * 12, 12);
  void setFswName(int i, String v) => _writeStr(bytes, 94 + i * 12, 12, v);

  String getAuxName(int i) => _nullStr(bytes, 172 + i * 12, 12);
  void setAuxName(int i, String v) => _writeStr(bytes, 172 + i * 12, 12, v);
}
