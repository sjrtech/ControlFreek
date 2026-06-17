import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothUnavailableException implements Exception {}

/// BLE device info wrapper for the scan list.
class BleDeviceInfo {
  final BluetoothDevice device;
  final String name;
  final String address;
  final int rssi;

  const BleDeviceInfo({
    required this.device,
    required this.name,
    required this.address,
    required this.rssi,
  });
}

/// Wraps flutter_blue_plus for the Stompbox protocol.
///
/// Service UUID  : 713d0000-503e-4c75-ba94-3148f18d941e
/// Read char     : 713d0002-503e-4c75-ba94-3148f18d941e
/// Write char    : 713d0003-503e-4c75-ba94-3148f18d941e
class BleService {
  static const _svcUuid  = '713d0000503e4c75ba943148f18d941e';
  static const _readUuid = '713d0002503e4c75ba943148f18d941e';
  static const _writeUuid= '713d0003503e4c75ba943148f18d941e';

  BluetoothDevice? _device;
  BluetoothCharacteristic? _readChar;
  BluetoothCharacteristic? _writeChar;
  bool _polling = false;

  final _dataCtrl = StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get dataStream => _dataCtrl.stream;

  final _scanCtrl = StreamController<List<BleDeviceInfo>>.broadcast();
  Stream<List<BleDeviceInfo>> get scanResults => _scanCtrl.stream;

  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<List<int>>? _notifySub;

  final Map<String, BleDeviceInfo> _seen = {};

  // ─── Linux BlueZ cache cleanup ───────────────────────────────────────────────

  static Future<void> clearLinuxBleCache() async {
    if (!Platform.isLinux) return;
    try {
      final result = await Process.run('bluetoothctl', ['devices']);
      final re = RegExp(r'^Device\s+([0-9A-Fa-f:]{17})\s+(BRKv\d{1,3}|BRK_v\d{1,3})', multiLine: true);
      for (final m in re.allMatches(result.stdout as String)) {
        try {
          await Process.run('bluetoothctl', ['remove', m.group(1)!]);
        } catch (_) {}
      }
    } catch (_) {}
  }

  // ─── Scanning ────────────────────────────────────────────────────────────────

  Future<void> startScan() async {
    // Wait for BT adapter to be ready — required on iOS at cold start
    try {
      await FlutterBluePlus.adapterState
          .where((s) => s == BluetoothAdapterState.on)
          .first
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      throw BluetoothUnavailableException();
    }
    _seen.clear();
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 30));
    _scanSub?.cancel();
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        final advName = r.advertisementData.advName;
        final platformName = r.device.platformName;
        final name = advName.isNotEmpty
            ? advName
            : platformName.isNotEmpty
                ? platformName
                : r.device.remoteId.str;
        if (r.rssi != 0) {
          _seen[r.device.remoteId.str] = BleDeviceInfo(
            device: r.device,
            name: name,
            address: r.device.remoteId.str,
            rssi: r.rssi,
          );
        }
      }
      _scanCtrl.add(_seen.values.toList());
    });
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _scanSub?.cancel();
    _scanSub = null;
  }

  // ─── Connection ──────────────────────────────────────────────────────────────

  Future<void> connect(BluetoothDevice device) async {
    await stopScan();
    await device.connect(autoConnect: false);
    _device = device;

    final services = await device.discoverServices();

    BluetoothService? svc;
    for (final s in services) {
      if (_uuidMatch(s.serviceUuid.toString(), _svcUuid)) {
        svc = s;
        break;
      }
    }
    if (svc == null) throw Exception('Stompbox service not found');

    for (final c in svc.characteristics) {
      final u = _stripDashes(c.characteristicUuid.toString());
      if (_uuidMatch(u, _readUuid)) _readChar = c;
      if (_uuidMatch(u, _writeUuid)) _writeChar = c;
    }

    if (_readChar == null) throw Exception('Read characteristic not found');
    if (_writeChar == null) throw Exception('Write characteristic not found');

    if (_readChar!.properties.notify || _readChar!.properties.indicate) {
      await _readChar!.setNotifyValue(true);
      _notifySub = _readChar!.onValueReceived.listen((data) {
        if (data.isNotEmpty) _dataCtrl.add(Uint8List.fromList(data));
      });
    } else {
      _startPolling();
    }
  }

  void _startPolling() {
    _polling = true;
    Future(() async {
      while (_polling && _readChar != null) {
        try {
          final data = await _readChar!.read();
          if (data.isNotEmpty) _dataCtrl.add(Uint8List.fromList(data));
          await Future.delayed(const Duration(milliseconds: 50));
        } catch (_) {
          break;
        }
      }
    });
  }

  Future<void> write(Uint8List data) async {
    if (_writeChar == null) return;
    try {
      await _writeChar!.write(data.toList(), withoutResponse: true);
    } catch (_) {
      // BLE write errors are non-fatal; the protocol will retry via next read
    }
  }

  Future<void> disconnect() async {
    _polling = false;
    _notifySub?.cancel();
    _notifySub = null;
    final addr = _device?.remoteId.str;
    try {
      await _device?.disconnect();
    } catch (_) {}
    if (Platform.isLinux && addr != null) {
      try {
        await Process.run('bluetoothctl', ['remove', addr]);
      } catch (_) {}
    }
    _device = null;
    _readChar = null;
    _writeChar = null;
  }

  bool get isConnected => _device?.isConnected ?? false;

  Future<int> readRssi() async {
    if (_device == null) return 0;
    return await _device!.readRssi();
  }

  void dispose() {
    _polling = false;
    _scanSub?.cancel();
    _notifySub?.cancel();
    _dataCtrl.close();
    _scanCtrl.close();
  }

  // ─── UUID helpers ─────────────────────────────────────────────────────────────

  static String _stripDashes(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[-{}]'), '');

  static bool _uuidMatch(String a, String b) =>
      _stripDashes(a) == _stripDashes(b);
}
