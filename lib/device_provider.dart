import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'ble_service.dart';
import 'protocol.dart';
import 'models.dart';

/// Set to true to gray-out and disable all song/setup controls when disconnected.
const bool kDisableWhenDisconnected = true;

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
  bool songLoading = false;
  bool connectionLoading = false;
  int displayedSongNumber = 0;

  StreamSubscription<List<BleDeviceInfo>>? _scanSub;
  StreamSubscription<Uint8List>? _dataSub;
  Timer? _autoConnectTimer;
  Timer? _retryTimer;
  Timer? _rssiTimer;
  bool _autoConnecting = false;
  bool _userDisconnected = false;

  int rssi = 0; // 0 = no reading

  DeviceProvider() {
    _proto = Protocol(
      writeData: _ble.write,
      onSongComplete: () {
        displayedSongNumber = _proto.ramSettings.currentSong;
        statusMessage = 'Song $displayedSongNumber loaded';
        songLoadCount++;
        songLoading = false;
        connectionLoading = false;
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
      if (!_autoConnecting && !_userDisconnected) {
        final match = results.where((d) => d.name.startsWith('BRK_v'));
        if (match.isNotEmpty) {
          _autoConnecting = true;
          _autoConnectTimer?.cancel();
          connectToDevice(match.first.device);
        }
      }
      notifyListeners();
    });

    // Kick off initial scan on app start
    WidgetsBinding.instance.addPostFrameCallback((_) => startScan());
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
    _autoConnecting = false;
    _userDisconnected = false;
    notifyListeners();

    _autoConnectTimer?.cancel();
    _autoConnectTimer = Timer(const Duration(seconds: 15), _onScanTimeout);

    try {
      await _ble.startScan();
    } catch (e) {
      _autoConnectTimer?.cancel();
      bleState = BleState.disconnected;
      statusMessage = 'Scan error: $e';
      notifyListeners();
    }
  }

  Future<void> _onScanTimeout() async {
    await _ble.stopScan();
    final retry = !kIsWeb && !Platform.isLinux;
    if (bleState == BleState.scanning) {
      bleState = BleState.disconnected;
      statusMessage = retry ? 'Device not found — retrying…' : 'Device not found';
      notifyListeners();
    }
    if (retry) {
      _retryTimer?.cancel();
      _retryTimer = Timer(const Duration(seconds: 3), startScan);
    }
  }

  Future<void> stopScan() async {
    _autoConnectTimer?.cancel();
    _retryTimer?.cancel();
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
    connectionLoading = true;
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

      _startRssiPolling();
      _proto.sendRequestForConfigBlock();
    } catch (e) {
      _autoConnecting = false;
      connectionLoading = false;
      bleState = BleState.disconnected;
      statusMessage = 'Connection failed: $e';
      notifyListeners();
      if (!kIsWeb && !Platform.isLinux) {
        _retryTimer?.cancel();
        _retryTimer = Timer(const Duration(seconds: 3), startScan);
      }
    }
  }

  void _startRssiPolling() {
    _rssiTimer?.cancel();
    _readRssi();
    _rssiTimer = Timer.periodic(const Duration(seconds: 5), (_) => _readRssi());
  }

  Future<void> _readRssi() async {
    if (bleState != BleState.connected) return;
    try {
      rssi = await _ble.readRssi();
      WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
    } catch (_) {}
  }

  void _stopRssiPolling() {
    _rssiTimer?.cancel();
    _rssiTimer = null;
    rssi = 0;
  }

  Future<void> disconnect() async {
    _userDisconnected = true;
    _autoConnectTimer?.cancel();
    _retryTimer?.cancel();
    _stopRssiPolling();
    _dataSub?.cancel();
    _dataSub = null;
    await _ble.stopScan();
    await _ble.disconnect();
    bleState = BleState.disconnected;
    statusMessage = 'Disconnected';
    notifyListeners();
  }

  void notifyLocalSongChanged() => notifyListeners();

  // ─── Device actions ───────────────────────────────────────────────────────────

  void updateSongToDevice() {
    debugPrint('updateSongToDevice: isConnected=$isConnected song=${settings.currentSong}');
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
    songLoading = true;
    _proto.gotoNextSong();
    notifyListeners();
  }

  void prevSong() {
    if (!isConnected) return;
    songLoading = true;
    _proto.gotoPreviousSong();
    notifyListeners();
  }

  // ─── Local backup ─────────────────────────────────────────────────────────────

  Future<String> saveSong() async {
    final dir = await getApplicationDocumentsDirectory();
    final songNum = settings.currentSong.toString().padLeft(3, '0');
    final path = '${dir.path}/song_$songNum.cfk';
    await File(path).writeAsBytes(song.bytes);
    statusMessage = 'Song backed up to $path';
    notifyListeners();
    return path;
  }

  void restoreSongFromBytes(Uint8List data) {
    final len = data.length < kSongSize ? data.length : kSongSize;
    song.bytes.setRange(0, len, data);
    songLoadCount++;
    statusMessage = 'Song restored from backup';
    notifyListeners();
  }

  // ─── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _autoConnectTimer?.cancel();
    _retryTimer?.cancel();
    _stopRssiPolling();
    _scanSub?.cancel();
    _dataSub?.cancel();
    _ble.dispose();
    super.dispose();
  }
}
