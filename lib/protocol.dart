import 'dart:typed_data';
import 'models.dart';

// Protocol operating modes
const int kModeIdle = 0;
const int kModeRetrieveSong = 1;
const int kModeRetrieveConfig = 2;
const int kModeWriteSong = 3;
const int kModeWriteConfig = 4;
const int kModeChangeSong = 5;

// Trick mode constants
const int kTrickModeNone = 0;
const int kTrickModeSong = 1;
const int kTrickModeLoopLatch = 2;
const int kTrickModeLoopMoment = 3;
const int kTrickModeFswLatch = 4;
const int kTrickModeFswMoment = 5;
const int kTrickModeMidiMsg = 6;

/// Direct Dart port of myappgui.cpp — packet encode/decode and transfer state machine.
///
/// Protocol packet format:
///   8-byte  lowercase cmd: '$' cmd hex2 hex2 chksum CR
///   14-byte uppercase cmd: '$' CMD block_hex2 b0h2 b1h2 b2h2 b3h2 chksum CR
///
/// Song blocks  : 25 × 4 bytes = 100 bytes total
/// Config blocks: 56 × 4 bytes = 224 bytes total
class Protocol {
  SongModel ramSong = SongModel();
  SettingsModel ramSettings = SettingsModel();

  int _mode = kModeIdle;
  int _block = 0;
  int _lastSong = -1;
  final int _trickButtonState = 0;

  final void Function(Uint8List) writeData;
  final void Function() onSongComplete;
  final void Function() onConfigComplete;

  Protocol({
    required this.writeData,
    required this.onSongComplete,
    required this.onConfigComplete,
  });

  // ─── Incoming data entry point ──────────────────────────────────────────────

  void parseInData(Uint8List data) {
    if (data.length < 8) return;
    if (data[0] != 0x24 /* '$' */ ) return;

    final cmd = data[1];
    if (cmd >= 0x61 /* 'a' */ ) {
      _parsePacket8(data);
    } else if (cmd >= 0x41 /* 'A' */ ) {
      _parsePacket14(data);
    }
  }

  void _parsePacket8(Uint8List p) {
    // Low byte of the 4-char ASCII value at p[2..5] = block number
    // (High byte = companion field, e.g. song# or trick state)
    final low = _ascii16ToInt(p, 2) & 0xff;
    switch (p[1]) {
      case 0x61: // 'a' — device requesting next song block (write-to-device flow)
        _block = low;
        _sendBlockSetSong();
      case 0x62: // 'b' — status packet from device
        _receiveStatus(p);
      case 0x63: // 'c' — device requesting next config block (write-to-device flow)
        _block = low;
        _sendBlockSetConfig();
    }
  }

  void _parsePacket14(Uint8List p) {
    if (p.length < 14) return;
    switch (p[1]) {
      case 0x41: // 'A' — device sending song block to app
        if (_mode == kModeRetrieveSong) {
          _receiveSongBlock(p);
        } else {
          sendStatus();
        }
      case 0x43: // 'C' — device sending config block to app
        if (_mode == kModeRetrieveConfig) {
          _receiveConfigBlock(p);
        } else {
          sendStatus();
        }
    }
  }

  // ─── Block receive ───────────────────────────────────────────────────────────

  void _receiveSongBlock(Uint8List p) {
    final base = _block * 4;
    final w0 = _ascii16ToInt(p, 4);
    final w1 = _ascii16ToInt(p, 8);
    ramSong.bytes[base + 0] = (w0 >> 8) & 0xff;
    ramSong.bytes[base + 1] = w0 & 0xff;
    ramSong.bytes[base + 2] = (w1 >> 8) & 0xff;
    ramSong.bytes[base + 3] = w1 & 0xff;

    if (_block < kSongBlocks - 1) {
      _block++;
      _sendRequestForSongBlock();
    } else {
      _mode = kModeIdle;
      sendStatus();
      onSongComplete();
    }
  }

  void _receiveConfigBlock(Uint8List p) {
    final base = _block * 4;
    final w0 = _ascii16ToInt(p, 4);
    final w1 = _ascii16ToInt(p, 8);
    ramSettings.bytes[base + 0] = (w0 >> 8) & 0xff;
    ramSettings.bytes[base + 1] = w0 & 0xff;
    ramSettings.bytes[base + 2] = (w1 >> 8) & 0xff;
    ramSettings.bytes[base + 3] = w1 & 0xff;

    if (_block < kSettingsBlocks - 1) {
      _block++;
      sendRequestForConfigBlock();
    } else {
      _mode = kModeIdle;
      sendStatus();
      onConfigComplete();
    }
  }

  void _receiveStatus(Uint8List p) {
    // p[2..5] = 4 ASCII hex chars encoding (trickState << 8 | songNum)
    final word = _ascii16ToInt(p, 2);
    final song = word & 0xff;

    if (_mode == kModeChangeSong) {
      if (ramSettings.currentSong == song) {
        _lastSong = song;
        _sendRequestForSongBlock();
      }
    } else {
      ramSettings.currentSong = (song >= 1 && song <= 120) ? song : 1;

      if (!ramSettings.isFilled) {
        sendRequestForConfigBlock();
      } else if (_lastSong != ramSettings.currentSong) {
        _lastSong = ramSettings.currentSong;
        _sendRequestForSongBlock();
      }
    }
  }

  // ─── Request packets (app → device) ─────────────────────────────────────────

  void _sendRequestForSongBlock() {
    if (_mode != kModeRetrieveSong) {
      _block = 0;
      _mode = kModeRetrieveSong;
    }
    final p = Uint8List(8);
    p[0] = 0x24; // '$'
    p[1] = 0x61; // 'a'
    _intToAscii(ramSettings.currentSong, p, 2);
    _intToAscii(_block, p, 4);
    p[6] = _checksum(p, 6);
    p[7] = 0x0d;
    writeData(p);
  }

  void sendRequestForConfigBlock() {
    if (_mode != kModeRetrieveConfig) {
      _block = 0;
      _mode = kModeRetrieveConfig;
    }
    final p = Uint8List(8);
    p[0] = 0x24; // '$'
    p[1] = 0x63; // 'c'
    _intToAscii(0, p, 2);
    _intToAscii(_block, p, 4);
    p[6] = _checksum(p, 6);
    p[7] = 0x0d;
    writeData(p);
  }

  void sendStatus() {
    final p = Uint8List(8);
    p[0] = 0x24; // '$'
    p[1] = 0x62; // 'b'
    _intToAscii(_trickButtonState, p, 2);
    _intToAscii(ramSettings.currentSong, p, 4);
    p[6] = _checksum(p, 6);
    p[7] = 0x0d;
    writeData(p);
  }

  // ─── Block send packets (app → device) ──────────────────────────────────────

  void _sendBlockSetSong() => _send14Block(0x42 /* 'B' */, ramSong.bytes);
  void _sendBlockSetConfig() => _send14Block(0x44 /* 'D' */, ramSettings.bytes);

  void _send14Block(int cmd, Uint8List data) {
    final base = _block * 4;
    final p = Uint8List(14);
    p[0] = 0x24;
    p[1] = cmd;
    _intToAscii(_block, p, 2);
    _intToAscii(data[base + 0], p, 4);
    _intToAscii(data[base + 1], p, 6);
    _intToAscii(data[base + 2], p, 8);
    _intToAscii(data[base + 3], p, 10);
    p[12] = _checksum(p, 12);
    p[13] = 0x0d;
    writeData(p);
  }

  // ─── Public actions ──────────────────────────────────────────────────────────

  void updateSongToDevice() {
    _block = 0;
    _mode = kModeWriteSong;
    _sendBlockSetSong();
  }

  void updateConfigToDevice() {
    _block = 0;
    _mode = kModeWriteConfig;
    _sendBlockSetConfig();
  }

  void gotoNextSong() {
    _mode = kModeChangeSong;
    if (ramSettings.currentSong < 120) ramSettings.currentSong++;
    sendStatus();
  }

  void gotoPreviousSong() {
    _mode = kModeChangeSong;
    if (ramSettings.currentSong > 1) ramSettings.currentSong--;
    sendStatus();
  }

  // ─── Codec helpers (mirrors myappgui.cpp) ────────────────────────────────────

  static int _nibble(int ch) {
    if (ch >= 0x30 && ch <= 0x39) return ch - 0x30;
    if (ch >= 0x41 && ch <= 0x46) return ch - 0x37;
    if (ch >= 0x61 && ch <= 0x66) return ch - 0x57;
    return 0;
  }

  static int _hexChar(int n) => '0123456789ABCDEF'.codeUnitAt(n & 0x0f);

  // Write one byte as two ASCII hex chars at buf[offset..offset+1]
  static void _intToAscii(int byte, Uint8List buf, int offset) {
    buf[offset] = _hexChar((byte >> 4) & 0x0f);
    buf[offset + 1] = _hexChar(byte & 0x0f);
  }

  // Read four ASCII hex chars starting at p[offset] → 16-bit int (big-endian nibbles)
  static int _ascii16ToInt(Uint8List p, int offset) =>
      (_nibble(p[offset]) << 12) |
      (_nibble(p[offset + 1]) << 8) |
      (_nibble(p[offset + 2]) << 4) |
      _nibble(p[offset + 3]);

  // XOR-sum of first [len] bytes, AND with 0x0f, converted to ASCII hex char
  static int _checksum(Uint8List data, int len) {
    int sum = 0;
    for (int i = 0; i < len; i++) {
      sum += data[i];
    }
    return _hexChar(sum & 0x0f);
  }
}
