import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'platform_interface.dart';
import 'models/enums.dart';
import 'models/bluetooth_connection.dart';
import 'models/bluetooth_device.dart';
import 'models/bluetooth_server_socket.dart';
import 'models/platform_capabilities.dart';
import 'models/exceptions.dart';

/// An implementation of [FlutterClassicBluetoothPlatform] that uses
/// method channels and event channels to communicate with native code.
///
/// {@category Platform}
class MethodChannelFlutterClassicBluetooth
    extends FlutterClassicBluetoothPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel =
      const MethodChannel('flutter_classic_bluetooth/methods');

  // Event channels
  final _adapterStateChannel =
      const EventChannel('flutter_classic_bluetooth/adapter_state');
  final _discoveryStateChannel =
      const EventChannel('flutter_classic_bluetooth/discovery_state');
  final _discoveryResultsChannel =
      const EventChannel('flutter_classic_bluetooth/discovery_results');
  final _bondStateChannel =
      const EventChannel('flutter_classic_bluetooth/bond_state');

  // Cached broadcast streams
  Stream<BluetoothAdapterState>? _adapterStateStream;
  Stream<bool>? _discoveryStateStream;
  Stream<BluetoothDevice>? _discoveryResultsStream;

  // ── Adapter ──────────────────────────────────────────────────────────

  @override
  Future<bool> isSupported() async {
    return await _invoke<bool>('isSupported') ?? false;
  }

  @override
  Future<bool> isEnabled() async {
    return await _invoke<bool>('isEnabled') ?? false;
  }

  @override
  Future<bool> enableBluetooth() async {
    return await _invoke<bool>('enableBluetooth') ?? false;
  }

  @override
  Future<bool> disableBluetooth() async {
    return await _invoke<bool>('disableBluetooth') ?? false;
  }

  @override
  Stream<BluetoothAdapterState> adapterState() {
    _adapterStateStream ??= _adapterStateChannel
        .receiveBroadcastStream()
        .map((event) => BluetoothAdapterState.values.firstWhere(
              (e) => e.name == event,
              orElse: () => BluetoothAdapterState.unknown,
            ));
    return _adapterStateStream!;
  }

  @override
  Future<String?> getAdapterName() {
    return _invoke<String>('getAdapterName');
  }

  @override
  Future<String?> getAdapterAddress() {
    return _invoke<String>('getAdapterAddress');
  }

  // ── Discovery ────────────────────────────────────────────────────────

  @override
  Future<void> startDiscovery() async {
    await _invoke<void>('startDiscovery');
  }

  @override
  Future<void> stopDiscovery() async {
    await _invoke<void>('stopDiscovery');
  }

  @override
  Future<bool> isDiscovering() async {
    return await _invoke<bool>('isDiscovering') ?? false;
  }

  @override
  Stream<bool> discoveryState() {
    _discoveryStateStream ??= _discoveryStateChannel
        .receiveBroadcastStream()
        .map((event) => event as bool);
    return _discoveryStateStream!;
  }

  @override
  Stream<BluetoothDevice> discoveryResults() {
    _discoveryResultsStream ??= _discoveryResultsChannel
        .receiveBroadcastStream()
        .map((event) => BluetoothDevice.fromMap(
              Map<dynamic, dynamic>.from(event as Map),
            ));
    return _discoveryResultsStream!;
  }

  // ── Pairing ──────────────────────────────────────────────────────────

  @override
  Future<List<BluetoothDevice>> getPairedDevices() async {
    final result = await _invoke<List>('getPairedDevices');
    if (result == null) return [];
    return result
        .map((e) => BluetoothDevice.fromMap(Map<dynamic, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<bool> bondDevice(String address) async {
    return await _invoke<bool>('bondDevice', {'address': address}) ?? false;
  }

  @override
  Future<bool> unbondDevice(String address) async {
    return await _invoke<bool>('unbondDevice', {'address': address}) ?? false;
  }

  @override
  Stream<BluetoothBondState> bondState(String address) {
    return _bondStateChannel
        .receiveBroadcastStream({'address': address}).map((event) {
      return BluetoothBondState.values.firstWhere(
        (e) => e.name == event,
        orElse: () => BluetoothBondState.none,
      );
    });
  }

  // ── Connection ───────────────────────────────────────────────────────

  @override
  Future<BluetoothConnection> connect({
    required String address,
    required String uuid,
    bool secure = true,
  }) async {
    final result = await _invoke<Map>('connect', {
      'address': address,
      'uuid': uuid,
      'secure': secure,
    });
    final map = Map<dynamic, dynamic>.from(result!);
    return BluetoothConnection(
      id: map['id'] as int,
      address: address,
      methodChannel: methodChannel,
    );
  }

  @override
  Future<void> disconnect(int id) async {
    await _invoke<void>('disconnect', {'id': id});
  }

  @override
  Future<void> write(int id, Uint8List data) async {
    await _invoke<void>('write', {'id': id, 'data': data});
  }

  // ── Server ───────────────────────────────────────────────────────────

  @override
  Future<BluetoothServerSocket> startServer({
    required String uuid,
    required String serviceName,
    bool secure = true,
  }) async {
    final result = await _invoke<Map>('startServer', {
      'uuid': uuid,
      'serviceName': serviceName,
      'secure': secure,
    });
    final map = Map<dynamic, dynamic>.from(result!);
    return BluetoothServerSocket(
      id: map['id'] as int,
      uuid: uuid,
      serviceName: serviceName,
      methodChannel: methodChannel,
    );
  }

  @override
  Future<void> stopServer(int id) async {
    await _invoke<void>('stopServer', {'id': id});
  }

  // ── Discoverability ──────────────────────────────────────────────────

  @override
  Future<bool> setDiscoverable(int durationSeconds) async {
    return await _invoke<bool>(
            'setDiscoverable', {'duration': durationSeconds}) ??
        false;
  }

  // ── Capabilities ─────────────────────────────────────────────────────

  @override
  Future<PlatformCapabilities> getPlatformCapabilities() async {
    final result = await _invoke<Map>('getPlatformCapabilities');
    return PlatformCapabilities.fromMap(
      Map<dynamic, dynamic>.from(result!),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  /// Invokes a method on the platform channel and converts
  /// [PlatformException] to typed [BluetoothException].
  Future<T?> _invoke<T>(String method, [Map<String, dynamic>? arguments]) async {
    try {
      return await methodChannel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (e) {
      throw _convertException(e);
    }
  }

  /// Converts a [PlatformException] to a typed [BluetoothException].
  BluetoothException _convertException(PlatformException e) {
    switch (e.code) {
      case 'unsupported':
        return BluetoothUnsupportedException(
          feature: e.details?['feature'] as String? ?? 'unknown',
          platform: e.details?['platform'] as String? ?? 'unknown',
          reason: e.message,
        );
      case 'permissionDenied':
        return BluetoothPermissionException(e.message ?? 'Permission denied');
      case 'bluetoothDisabled':
        return BluetoothDisabledException(
            e.message ?? 'Bluetooth adapter is disabled');
      case 'connectionFailed':
        return BluetoothConnectionException(
          e.message ?? 'Connection failed',
          address: e.details?['address'] as String?,
        );
      case 'writeFailed':
        return BluetoothWriteException(e.message ?? 'Write failed');
      case 'timeout':
        return BluetoothTimeoutException(
          message: e.message ?? 'Operation timed out',
          timeoutMs: e.details?['timeoutMs'] as int?,
        );
      case 'invalidAddress':
        return BluetoothAddressException(
            e.details?['address'] as String? ?? 'unknown');
      case 'invalidUuid':
        return BluetoothUuidException(
            e.details?['uuid'] as String? ?? 'unknown');
      default:
        return BluetoothException(
          e.message ?? 'Unknown Bluetooth error',
          code: e.code,
        );
    }
  }
}
