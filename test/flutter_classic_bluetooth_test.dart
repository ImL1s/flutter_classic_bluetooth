import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// ── Mock Platform ──────────────────────────────────────────────────────

class MockFlutterClassicBluetoothPlatform
    with MockPlatformInterfaceMixin
    implements FlutterClassicBluetoothPlatform {
  @override
  Future<bool> isSupported() => Future.value(true);

  @override
  Future<bool> isEnabled() => Future.value(true);

  @override
  Future<bool> enableBluetooth() => Future.value(true);

  @override
  Future<bool> disableBluetooth() => Future.value(true);

  @override
  Stream<BluetoothAdapterState> adapterState() =>
      Stream.value(BluetoothAdapterState.on);

  @override
  Future<String?> getAdapterName() => Future.value('TestAdapter');

  @override
  Future<String?> getAdapterAddress() =>
      Future.value('AA:BB:CC:DD:EE:FF');

  @override
  Future<void> startDiscovery() => Future.value();

  @override
  Future<void> stopDiscovery() => Future.value();

  @override
  Future<bool> isDiscovering() => Future.value(false);

  @override
  Stream<bool> discoveryState() => Stream.value(false);

  @override
  Stream<BluetoothDevice> discoveryResults() => const Stream.empty();

  @override
  Future<List<BluetoothDevice>> getPairedDevices() =>
      Future.value([
        const BluetoothDevice(
          address: 'AA:BB:CC:DD:EE:FF',
          name: 'TestDevice',
          bondState: BluetoothBondState.bonded,
        ),
      ]);

  @override
  Future<bool> bondDevice(String address) => Future.value(true);

  @override
  Future<bool> unbondDevice(String address) => Future.value(true);

  @override
  Stream<BluetoothBondState> bondState(String address) =>
      Stream.value(BluetoothBondState.bonded);

  @override
  Future<BluetoothConnection> connect({
    required String address,
    required String uuid,
    bool secure = true,
  }) {
    throw UnimplementedError('connect() mock not implemented');
  }

  @override
  Future<void> disconnect(int id) => Future.value();

  @override
  Future<void> write(int id, Uint8List data) => Future.value();

  @override
  Future<BluetoothServerSocket> startServer({
    required String uuid,
    required String serviceName,
    bool secure = true,
  }) {
    throw UnimplementedError('startServer() mock not implemented');
  }

  @override
  Future<void> stopServer(int id) => Future.value();

  @override
  Future<bool> setDiscoverable(int durationSeconds) => Future.value(true);

  @override
  Future<PlatformCapabilities> getPlatformCapabilities() =>
      Future.value(const PlatformCapabilities(
        canDiscoverDevices: true,
        canGetPairedDevices: true,
        canBondDevices: true,
        supportsMultipleConnections: true,
      ));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Platform interface', () {
    test('MethodChannelFlutterClassicBluetooth is the default instance', () {
      expect(
        FlutterClassicBluetoothPlatform.instance,
        isA<MethodChannelFlutterClassicBluetooth>(),
      );
    });

    test('platform interface throws UnimplementedError for all methods', () {
      final platform = _UnimplementedPlatform();

      expect(() => platform.isSupported(), throwsUnimplementedError);
      expect(() => platform.isEnabled(), throwsUnimplementedError);
      expect(() => platform.enableBluetooth(), throwsUnimplementedError);
      expect(() => platform.disableBluetooth(), throwsUnimplementedError);
      expect(() => platform.adapterState(), throwsUnimplementedError);
      expect(() => platform.getAdapterName(), throwsUnimplementedError);
      expect(() => platform.getAdapterAddress(), throwsUnimplementedError);
      expect(() => platform.startDiscovery(), throwsUnimplementedError);
      expect(() => platform.stopDiscovery(), throwsUnimplementedError);
      expect(() => platform.isDiscovering(), throwsUnimplementedError);
      expect(() => platform.discoveryState(), throwsUnimplementedError);
      expect(() => platform.discoveryResults(), throwsUnimplementedError);
      expect(() => platform.getPairedDevices(), throwsUnimplementedError);
      expect(() => platform.bondDevice('AA:BB:CC:DD:EE:FF'), throwsUnimplementedError);
      expect(() => platform.unbondDevice('AA:BB:CC:DD:EE:FF'), throwsUnimplementedError);
      expect(() => platform.bondState('AA:BB:CC:DD:EE:FF'), throwsUnimplementedError);
      expect(
        () => platform.connect(
          address: 'AA:BB:CC:DD:EE:FF',
          uuid: '00001101-0000-1000-8000-00805F9B34FB',
        ),
        throwsUnimplementedError,
      );
      expect(() => platform.disconnect(0), throwsUnimplementedError);
      expect(() => platform.write(0, Uint8List(0)), throwsUnimplementedError);
      expect(
        () => platform.startServer(
          uuid: '00001101-0000-1000-8000-00805F9B34FB',
          serviceName: 'test',
        ),
        throwsUnimplementedError,
      );
      expect(() => platform.stopServer(0), throwsUnimplementedError);
      expect(() => platform.setDiscoverable(120), throwsUnimplementedError);
      expect(() => platform.getPlatformCapabilities(), throwsUnimplementedError);
    });
  });

  group('FlutterClassicBluetooth', () {
    late FlutterClassicBluetooth bluetooth;
    late MockFlutterClassicBluetoothPlatform mockPlatform;

    setUp(() {
      mockPlatform = MockFlutterClassicBluetoothPlatform();
      FlutterClassicBluetoothPlatform.instance = mockPlatform;
      bluetooth = FlutterClassicBluetooth();
    });

    test('isSupported returns true from mock', () async {
      expect(await bluetooth.isSupported(), isTrue);
    });

    test('isEnabled returns true from mock', () async {
      expect(await bluetooth.isEnabled(), isTrue);
    });

    test('getAdapterName returns test name', () async {
      expect(await bluetooth.getAdapterName(), 'TestAdapter');
    });

    test('getPairedDevices returns mock list', () async {
      final devices = await bluetooth.getPairedDevices();
      expect(devices, hasLength(1));
      expect(devices.first.address, 'AA:BB:CC:DD:EE:FF');
      expect(devices.first.name, 'TestDevice');
    });

    test('getPlatformCapabilities returns mock capabilities', () async {
      final caps = await bluetooth.getPlatformCapabilities();
      expect(caps.canDiscoverDevices, isTrue);
      expect(caps.canGetPairedDevices, isTrue);
    });
  });

  group('Input validation', () {
    late FlutterClassicBluetooth bluetooth;

    setUp(() {
      FlutterClassicBluetoothPlatform.instance =
          MockFlutterClassicBluetoothPlatform();
      bluetooth = FlutterClassicBluetooth();
    });

    test('bondDevice throws on invalid address', () {
      expect(
        () => bluetooth.bondDevice('invalid'),
        throwsA(isA<BluetoothAddressException>()),
      );
    });

    test('unbondDevice throws on invalid address', () {
      expect(
        () => bluetooth.unbondDevice('ZZZZ'),
        throwsA(isA<BluetoothAddressException>()),
      );
    });

    test('connect throws on invalid address', () {
      expect(
        () => bluetooth.connect(
          address: 'bad-address',
          uuid: '00001101-0000-1000-8000-00805F9B34FB',
        ),
        throwsA(isA<BluetoothAddressException>()),
      );
    });

    test('connect throws on invalid UUID', () {
      expect(
        () => bluetooth.connect(
          address: 'AA:BB:CC:DD:EE:FF',
          uuid: 'not-a-uuid',
        ),
        throwsA(isA<BluetoothUuidException>()),
      );
    });

    test('startServer throws on invalid UUID', () {
      expect(
        () => bluetooth.startServer(uuid: 'bad', serviceName: 'test'),
        throwsA(isA<BluetoothUuidException>()),
      );
    });

    test('bondDevice accepts valid MAC address', () async {
      final result = await bluetooth.bondDevice('AA:BB:CC:DD:EE:FF');
      expect(result, isTrue);
    });

    test('connect accepts valid address and UUID', () {
      // The mock throws UnimplementedError for connect, which is fine —
      // we just verify validation passes.
      expect(
        () => bluetooth.connect(
          address: 'AA:BB:CC:DD:EE:FF',
          uuid: '00001101-0000-1000-8000-00805F9B34FB',
        ),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });

  group('BluetoothDevice', () {
    test('fromMap creates device correctly', () {
      final device = BluetoothDevice.fromMap({
        'address': '11:22:33:44:55:66',
        'name': 'TestDevice',
        'alias': 'MyDevice',
        'rssi': -50,
        'type': 'classic',
        'bondState': 'bonded',
        'uuids': ['00001101-0000-1000-8000-00805F9B34FB'],
      });

      expect(device.address, '11:22:33:44:55:66');
      expect(device.name, 'TestDevice');
      expect(device.alias, 'MyDevice');
      expect(device.rssi, -50);
      expect(device.type, BluetoothDeviceType.classic);
      expect(device.bondState, BluetoothBondState.bonded);
      expect(device.uuids, hasLength(1));
    });

    test('toMap round-trip is consistent', () {
      const original = BluetoothDevice(
        address: 'AA:BB:CC:DD:EE:FF',
        name: 'Dev',
        type: BluetoothDeviceType.dual,
        bondState: BluetoothBondState.bonding,
        uuids: ['uuid1'],
      );
      final map = original.toMap();
      final restored = BluetoothDevice.fromMap(map);

      expect(restored.address, original.address);
      expect(restored.name, original.name);
      expect(restored.type, original.type);
      expect(restored.bondState, original.bondState);
      expect(restored.uuids, original.uuids);
    });

    test('equality is based on address', () {
      const a = BluetoothDevice(address: 'AA:BB:CC:DD:EE:FF', name: 'A');
      const b = BluetoothDevice(address: 'AA:BB:CC:DD:EE:FF', name: 'B');
      const c = BluetoothDevice(address: '11:22:33:44:55:66', name: 'A');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });

    test('displayName falls back through alias → name → address', () {
      const withAlias = BluetoothDevice(
        address: 'AA:BB:CC:DD:EE:FF',
        name: 'Name',
        alias: 'Alias',
      );
      const withName = BluetoothDevice(
        address: 'AA:BB:CC:DD:EE:FF',
        name: 'Name',
      );
      const addressOnly = BluetoothDevice(address: 'AA:BB:CC:DD:EE:FF');

      expect(withAlias.displayName, 'Alias');
      expect(withName.displayName, 'Name');
      expect(addressOnly.displayName, 'AA:BB:CC:DD:EE:FF');
    });

    test('fromMap handles missing optional fields', () {
      final device = BluetoothDevice.fromMap({
        'address': 'AA:BB:CC:DD:EE:FF',
      });
      expect(device.name, isNull);
      expect(device.alias, isNull);
      expect(device.rssi, isNull);
      expect(device.type, BluetoothDeviceType.unknown);
      expect(device.bondState, BluetoothBondState.none);
      expect(device.uuids, isEmpty);
    });
  });

  group('PlatformCapabilities', () {
    test('fromMap creates capabilities correctly', () {
      final caps = PlatformCapabilities.fromMap({
        'canDiscoverDevices': true,
        'canGetPairedDevices': true,
        'canBondDevices': true,
        'canUnbondDevices': true,
        'canCreateServer': true,
        'supportsMultipleConnections': true,
        'supportsSecureConnection': true,
        'supportsInsecureConnection': true,
        'platformNote': 'Test note',
      });

      expect(caps.canDiscoverDevices, isTrue);
      expect(caps.canGetPairedDevices, isTrue);
      expect(caps.canCreateServer, isTrue);
      expect(caps.supportsMultipleConnections, isTrue);
      expect(caps.platformNote, 'Test note');
      expect(caps.requiresMfiCertification, isFalse);
    });

    test('toMap round-trip is consistent', () {
      const original = PlatformCapabilities(
        canDiscoverDevices: true,
        canEnableBluetooth: true,
        requiresMfiCertification: true,
        platformNote: 'iOS',
      );
      final map = original.toMap();
      final restored = PlatformCapabilities.fromMap(map);

      expect(restored.canDiscoverDevices, original.canDiscoverDevices);
      expect(restored.canEnableBluetooth, original.canEnableBluetooth);
      expect(restored.requiresMfiCertification, original.requiresMfiCertification);
      expect(restored.platformNote, original.platformNote);
    });

    test('defaults are all false/null', () {
      const caps = PlatformCapabilities();
      expect(caps.canEnableBluetooth, isFalse);
      expect(caps.canDisableBluetooth, isFalse);
      expect(caps.canDiscoverDevices, isFalse);
      expect(caps.canGetPairedDevices, isFalse);
      expect(caps.platformNote, isNull);
    });
  });

  group('Exception hierarchy', () {
    test('BluetoothException stores message and code', () {
      const ex = BluetoothException('test error', code: 'testCode');
      expect(ex.message, 'test error');
      expect(ex.code, 'testCode');
      expect(ex.toString(), contains('testCode'));
    });

    test('BluetoothUnsupportedException has feature and platform', () {
      const ex = BluetoothUnsupportedException(
        feature: 'discovery',
        platform: 'iOS',
      );
      expect(ex.feature, 'discovery');
      expect(ex.platform, 'iOS');
      expect(ex.toString(), contains('discovery'));
      expect(ex.toString(), contains('iOS'));
    });

    test('BluetoothConnectionException has address', () {
      const ex = BluetoothConnectionException(
        'Connection refused',
        address: 'AA:BB:CC:DD:EE:FF',
      );
      expect(ex.address, 'AA:BB:CC:DD:EE:FF');
      expect(ex.message, 'Connection refused');
    });

    test('BluetoothAddressException has address', () {
      const ex = BluetoothAddressException('INVALID');
      expect(ex.address, 'INVALID');
      expect(ex.toString(), contains('INVALID'));
    });

    test('BluetoothUuidException has uuid', () {
      const ex = BluetoothUuidException('bad-uuid');
      expect(ex.uuid, 'bad-uuid');
    });

    test('all exceptions are BluetoothException', () {
      expect(
        const BluetoothPermissionException(),
        isA<BluetoothException>(),
      );
      expect(
        const BluetoothDisabledException(),
        isA<BluetoothException>(),
      );
      expect(
        const BluetoothWriteException(),
        isA<BluetoothException>(),
      );
      expect(
        const BluetoothTimeoutException(),
        isA<BluetoothException>(),
      );
    });
  });

  group('BluetoothStreamSink', () {
    test('throws StateError after close', () async {
      final sink = BluetoothStreamSink(
        connectionId: 1,
        methodChannel: const MethodChannel('flutter_classic_bluetooth/methods'),
      );

      sink.cancel();
      expect(sink.isClosed, isTrue);
      expect(
        () => sink.add(Uint8List(1)),
        throwsA(isA<StateError>()),
      );
    });
  });
}

/// A platform that doesn't implement anything — used to verify
/// that all methods throw [UnimplementedError].
class _UnimplementedPlatform extends FlutterClassicBluetoothPlatform {}
