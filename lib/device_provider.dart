import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'ble_service.dart';
import 'protocol.dart';
import 'models.dart';

enum BleState { disconnected, scanning, connecting, connected }

/// Central state object. Ties BleService + Protocol together and notifies
/// the UI via ChangeNotifier (replaces Q_PROPERTY / signals+slots).
class DeviceProvider extends ChangeNotifier {
  final _ble = BleService();
  late final Protocol _proto;

  BleState bleState = BleState.disconnected;
  String statusMessage = 'Not connected';
  List<BleDeviceInfo> scanResults = [];

  // Incremented each time a full song / config block transfer completes;
  // screens key their ListView on this so fields refresh with new data.
  int songLoadCount = 0;
  int configLoadCount = 0;

  StreamSubscription<List<BleDeviceInfo>>? _scanSub;
  StreamSubscription<Uint8List>? _dataSub;

  DeviceProvider() {
    _proto = Protocol(
      writeData: _ble.write,
      onSongComplete: () {
        statusMessage = 'Song ${_proto.ramSettings.currentSong} loaded';
        songLoadCount++;
        notifyListeners();
      },
      onConfigComplete: () {
        statusMessage = 'Config loaded — song ${_proto.ramSettings.currentSong}';
        configLoadCount++;
        notifyListeners();
      },
    );

    _scanSub = _ble.scanResults.listen((results) {
      scanResults = results;
      notifyListeners();
    });
  }

  // ─── Accessors ────────────────────────────────────────────────────────────────

  SongModel get song => _proto.ramSong;
  SettingsModel get settings => _proto.ramSettings;
  bool get isConnected => bleState == BleState.connected;

  // ─── Scanning ─────────────────────────────────────────────────────────────────

  Future<void> startScan() async {
    bleState = BleState.scanning;
    scanResults = [];
    statusMessage = 'Scanning…';
    notifyListeners();
    try {
      await _ble.startScan();
    } catch (e) {
      bleState = BleState.disconnected;
      statusMessage = 'Scan error: $e';
      notifyListeners();
    }
  }

  Future<void> stopScan() async {
    await _ble.stopScan();
    if (bleState == BleState.scanning) {
      bleState = BleState.disconnected;
      statusMessage = 'Scan stopped';
      notifyListeners();
    }
  }

  // ─── Connection ───────────────────────────────────────────────────────────────

  Future<void> connectToDevice(BluetoothDevice device) async {
    bleState = BleState.connecting;
    statusMessage = 'Connecting…';
    notifyListeners();
    try {
      await _ble.connect(device);

      _dataSub = _ble.dataStream.listen((data) {
        _proto.parseInData(data);
        notifyListeners();
      });

      bleState = BleState.connected;
      statusMessage = 'Connected — requesting config…';
      notifyListeners();

      _proto.sendRequestForConfigBlock();
    } catch (e) {
      bleState = BleState.disconnected;
      statusMessage = 'Connection failed: $e';
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    _dataSub?.cancel();
    _dataSub = null;
    await _ble.disconnect();
    bleState = BleState.disconnected;
    statusMessage = 'Disconnected';
    notifyListeners();
  }

  void notifyLocalSongChanged() => notifyListeners();

  // ─── Device actions ───────────────────────────────────────────────────────────

  void updateSongToDevice() {
    if (!isConnected) return;
    _proto.updateSongToDevice();
    statusMessage = 'Sending song…';
    notifyListeners();
  }

  void updateConfigToDevice() {
    if (!isConnected) return;
    _proto.updateConfigToDevice();
    statusMessage = 'Sending config…';
    notifyListeners();
  }

  void nextSong() {
    if (!isConnected) return;
    _proto.gotoNextSong();
    notifyListeners();
  }

  void prevSong() {
    if (!isConnected) return;
    _proto.gotoPreviousSong();
    notifyListeners();
  }

  // ─── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _scanSub?.cancel();
    _dataSub?.cancel();
    _ble.dispose();
    super.dispose();
  }
}
