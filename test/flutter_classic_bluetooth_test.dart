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
  Stream<BtcAdapterState> adapterState() =>
      Stream.value(BtcAdapterState.on);

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
  Stream<BtcDevice> discoveryResults() => const Stream.empty();

  @override
  Future<List<BtcDevice>> getPairedDevices() =>
      Future.value([
        const BtcDevice(
          address: 'AA:BB:CC:DD:EE:FF',
          name: 'TestDevice',
          bondState: BtcBondState.bonded,
        ),
      ]);

  @override
  Future<bool> bondDevice(String address) => Future.value(true);

  @override
  Future<bool> unbondDevice(String address) => Future.value(true);

  @override
  Stream<BtcBondState> bondState(String address) =>
      Stream.value(BtcBondState.bonded);

  @override
  Future<BtcConnection> connect({
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
  Future<BtcServerSocket> startServer({
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
  Future<BtcPlatformCapabilities> getPlatformCapabilities() =>
      Future.value(const BtcPlatformCapabilities(
        canDiscoverDevices: true,
        canGetPairedDevices: true,
        canBondDevices: true,
        supportsMultipleConnections: true,
      ));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ── Platform Interface Tests ──────────────────────────────────────────

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

    test('can set platform instance', () {
      final mock = MockFlutterClassicBluetoothPlatform();
      FlutterClassicBluetoothPlatform.instance = mock;
      expect(FlutterClassicBluetoothPlatform.instance, same(mock));
    });
  });

  // ── FlutterClassicBluetooth (Main Plugin Class) ──────────────────────

  group('FlutterClassicBluetooth', () {
    late FlutterClassicBluetooth bluetooth;
    late MockFlutterClassicBluetoothPlatform mockPlatform;

    setUp(() {
      mockPlatform = MockFlutterClassicBluetoothPlatform();
      FlutterClassicBluetoothPlatform.instance = mockPlatform;
      bluetooth = FlutterClassicBluetooth();
    });

    test('singleton returns same instance', () {
      final a = FlutterClassicBluetooth();
      final b = FlutterClassicBluetooth();
      expect(identical(a, b), isTrue);
    });

    test('isSupported returns true from mock', () async {
      expect(await bluetooth.isSupported(), isTrue);
    });

    test('isEnabled returns true from mock', () async {
      expect(await bluetooth.isEnabled(), isTrue);
    });

    test('enableBluetooth returns true from mock', () async {
      expect(await bluetooth.enableBluetooth(), isTrue);
    });

    test('disableBluetooth returns true from mock', () async {
      expect(await bluetooth.disableBluetooth(), isTrue);
    });

    test('getAdapterName returns test name', () async {
      expect(await bluetooth.getAdapterName(), 'TestAdapter');
    });

    test('getAdapterAddress returns test address', () async {
      expect(await bluetooth.getAdapterAddress(), 'AA:BB:CC:DD:EE:FF');
    });

    test('startDiscovery completes without error', () async {
      await bluetooth.startDiscovery();
    });

    test('stopDiscovery completes without error', () async {
      await bluetooth.stopDiscovery();
    });

    test('isDiscovering returns false from mock', () async {
      expect(await bluetooth.isDiscovering(), isFalse);
    });

    test('getPairedDevices returns mock list', () async {
      final devices = await bluetooth.getPairedDevices();
      expect(devices, hasLength(1));
      expect(devices.first.address, 'AA:BB:CC:DD:EE:FF');
      expect(devices.first.name, 'TestDevice');
    });

    test('bondDevice returns true for valid address', () async {
      expect(await bluetooth.bondDevice('AA:BB:CC:DD:EE:FF'), isTrue);
    });

    test('unbondDevice returns true for valid address', () async {
      expect(await bluetooth.unbondDevice('AA:BB:CC:DD:EE:FF'), isTrue);
    });

    test('setDiscoverable returns true', () async {
      expect(await bluetooth.setDiscoverable(120), isTrue);
    });

    test('getPlatformCapabilities returns mock capabilities', () async {
      final caps = await bluetooth.getPlatformCapabilities();
      expect(caps.canDiscoverDevices, isTrue);
      expect(caps.canGetPairedDevices, isTrue);
      expect(caps.canBondDevices, isTrue);
      expect(caps.supportsMultipleConnections, isTrue);
    });

    test('adapterState stream emits values', () async {
      final state = await bluetooth.adapterState.first;
      expect(state, BtcAdapterState.on);
    });

    test('discoveryState stream emits values', () async {
      final state = await bluetooth.discoveryState.first;
      expect(state, isFalse);
    });
  });

  // ── Input Validation ──────────────────────────────────────────────────

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
        throwsA(isA<BtcAddressException>()),
      );
    });

    test('bondDevice throws on empty address', () {
      expect(
        () => bluetooth.bondDevice(''),
        throwsA(isA<BtcAddressException>()),
      );
    });

    test('unbondDevice throws on invalid address', () {
      expect(
        () => bluetooth.unbondDevice('ZZZZ'),
        throwsA(isA<BtcAddressException>()),
      );
    });

    test('connect throws on invalid address', () {
      expect(
        () => bluetooth.connect(
          address: 'bad-address',
          uuid: '00001101-0000-1000-8000-00805F9B34FB',
        ),
        throwsA(isA<BtcAddressException>()),
      );
    });

    test('connect throws on invalid UUID', () {
      expect(
        () => bluetooth.connect(
          address: 'AA:BB:CC:DD:EE:FF',
          uuid: 'not-a-uuid',
        ),
        throwsA(isA<BtcUuidException>()),
      );
    });

    test('connect throws on short UUID', () {
      expect(
        () => bluetooth.connect(
          address: 'AA:BB:CC:DD:EE:FF',
          uuid: '0000-1101',
        ),
        throwsA(isA<BtcUuidException>()),
      );
    });

    test('startServer throws on invalid UUID', () {
      expect(
        () => bluetooth.startServer(uuid: 'bad', serviceName: 'test'),
        throwsA(isA<BtcUuidException>()),
      );
    });

    test('bondDevice accepts valid MAC address', () async {
      final result = await bluetooth.bondDevice('AA:BB:CC:DD:EE:FF');
      expect(result, isTrue);
    });

    test('bondDevice accepts lowercase MAC', () async {
      final result = await bluetooth.bondDevice('aa:bb:cc:dd:ee:ff');
      expect(result, isTrue);
    });

    test('connect accepts valid address and UUID', () {
      // The mock throws UnimplementedError for connect, which is fine —
      // we verify validation passes.
      expect(
        () => bluetooth.connect(
          address: 'AA:BB:CC:DD:EE:FF',
          uuid: '00001101-0000-1000-8000-00805F9B34FB',
        ),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('bondState throws on invalid address', () {
      expect(
        () => bluetooth.bondState('not-valid'),
        throwsA(isA<BtcAddressException>()),
      );
    });

    test('bondState returns stream for valid address', () async {
      final state = await bluetooth.bondState('AA:BB:CC:DD:EE:FF').first;
      expect(state, BtcBondState.bonded);
    });
  });

  // ── Method Channel Tests ──────────────────────────────────────────────

  group('MethodChannelFlutterClassicBluetooth', () {
    late MethodChannelFlutterClassicBluetooth platform;
    late List<MethodCall> log;

    setUp(() {
      platform = MethodChannelFlutterClassicBluetooth();
      log = [];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        platform.methodChannel,
        (MethodCall call) async {
          log.add(call);
          switch (call.method) {
            case 'isSupported':
              return true;
            case 'isEnabled':
              return true;
            case 'enableBluetooth':
              return true;
            case 'disableBluetooth':
              return true;
            case 'getAdapterName':
              return 'MockAdapter';
            case 'getAdapterAddress':
              return '11:22:33:44:55:66';
            case 'startDiscovery':
              return null;
            case 'stopDiscovery':
              return null;
            case 'isDiscovering':
              return false;
            case 'getPairedDevices':
              return [
                {
                  'address': 'AA:BB:CC:DD:EE:FF',
                  'name': 'Device1',
                  'bondState': 'bonded',
                }
              ];
            case 'bondDevice':
              return true;
            case 'unbondDevice':
              return true;
            case 'connect':
              return {'id': 1, 'address': call.arguments['address']};
            case 'disconnect':
              return null;
            case 'write':
              return null;
            case 'startServer':
              return {'id': 1};
            case 'stopServer':
              return null;
            case 'setDiscoverable':
              return true;
            case 'getPlatformCapabilities':
              return {
                'canEnableBluetooth': true,
                'canDisableBluetooth': false,
                'canDiscoverDevices': true,
                'canGetPairedDevices': true,
                'canBondDevices': true,
                'canUnbondDevices': true,
                'canCreateServer': true,
                'canSetDiscoverable': false,
                'supportsMultipleConnections': true,
                'supportsSecureConnection': true,
                'supportsInsecureConnection': false,
                'requiresMfiCertification': false,
                'platformNote': 'Test platform',
              };
            default:
              return null;
          }
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, null);
    });

    test('isSupported sends correct method', () async {
      final result = await platform.isSupported();
      expect(result, isTrue);
      expect(log.last.method, 'isSupported');
    });

    test('isEnabled sends correct method', () async {
      final result = await platform.isEnabled();
      expect(result, isTrue);
      expect(log.last.method, 'isEnabled');
    });

    test('enableBluetooth sends correct method', () async {
      final result = await platform.enableBluetooth();
      expect(result, isTrue);
      expect(log.last.method, 'enableBluetooth');
    });

    test('disableBluetooth sends correct method', () async {
      final result = await platform.disableBluetooth();
      expect(result, isTrue);
      expect(log.last.method, 'disableBluetooth');
    });

    test('getAdapterName sends correct method', () async {
      final result = await platform.getAdapterName();
      expect(result, 'MockAdapter');
      expect(log.last.method, 'getAdapterName');
    });

    test('getAdapterAddress sends correct method', () async {
      final result = await platform.getAdapterAddress();
      expect(result, '11:22:33:44:55:66');
      expect(log.last.method, 'getAdapterAddress');
    });

    test('startDiscovery sends correct method', () async {
      await platform.startDiscovery();
      expect(log.last.method, 'startDiscovery');
    });

    test('stopDiscovery sends correct method', () async {
      await platform.stopDiscovery();
      expect(log.last.method, 'stopDiscovery');
    });

    test('isDiscovering sends correct method', () async {
      final result = await platform.isDiscovering();
      expect(result, isFalse);
      expect(log.last.method, 'isDiscovering');
    });

    test('getPairedDevices sends correct method and parses result', () async {
      final devices = await platform.getPairedDevices();
      expect(log.last.method, 'getPairedDevices');
      expect(devices, hasLength(1));
      expect(devices.first.address, 'AA:BB:CC:DD:EE:FF');
      expect(devices.first.name, 'Device1');
      expect(devices.first.bondState, BtcBondState.bonded);
    });

    test('bondDevice sends address argument', () async {
      final result = await platform.bondDevice('11:22:33:44:55:66');
      expect(result, isTrue);
      expect(log.last.method, 'bondDevice');
      expect(log.last.arguments, {'address': '11:22:33:44:55:66'});
    });

    test('unbondDevice sends address argument', () async {
      final result = await platform.unbondDevice('11:22:33:44:55:66');
      expect(result, isTrue);
      expect(log.last.method, 'unbondDevice');
      expect(log.last.arguments, {'address': '11:22:33:44:55:66'});
    });

    test('connect sends correct arguments and returns connection', () async {
      final connection = await platform.connect(
        address: 'AA:BB:CC:DD:EE:FF',
        uuid: '00001101-0000-1000-8000-00805F9B34FB',
        secure: true,
      );
      expect(log.last.method, 'connect');
      expect(log.last.arguments, {
        'address': 'AA:BB:CC:DD:EE:FF',
        'uuid': '00001101-0000-1000-8000-00805F9B34FB',
        'secure': true,
      });
      expect(connection.id, 1);
      expect(connection.address, 'AA:BB:CC:DD:EE:FF');
    });

    test('disconnect sends id argument', () async {
      await platform.disconnect(5);
      expect(log.last.method, 'disconnect');
      expect(log.last.arguments, {'id': 5});
    });

    test('write sends id and data arguments', () async {
      final data = Uint8List.fromList([1, 2, 3]);
      await platform.write(5, data);
      expect(log.last.method, 'write');
      expect(log.last.arguments['id'], 5);
      expect(log.last.arguments['data'], data);
    });

    test('startServer sends correct arguments and returns server', () async {
      final server = await platform.startServer(
        uuid: '00001101-0000-1000-8000-00805F9B34FB',
        serviceName: 'TestService',
        secure: true,
      );
      expect(log.last.method, 'startServer');
      expect(log.last.arguments, {
        'uuid': '00001101-0000-1000-8000-00805F9B34FB',
        'serviceName': 'TestService',
        'secure': true,
      });
      expect(server.id, 1);
      expect(server.uuid, '00001101-0000-1000-8000-00805F9B34FB');
      expect(server.serviceName, 'TestService');
    });

    test('stopServer sends id argument', () async {
      await platform.stopServer(3);
      expect(log.last.method, 'stopServer');
      expect(log.last.arguments, {'id': 3});
    });

    test('setDiscoverable sends duration argument', () async {
      final result = await platform.setDiscoverable(300);
      expect(result, isTrue);
      expect(log.last.method, 'setDiscoverable');
      expect(log.last.arguments, {'duration': 300});
    });

    test('getPlatformCapabilities parses all fields', () async {
      final caps = await platform.getPlatformCapabilities();
      expect(log.last.method, 'getPlatformCapabilities');
      expect(caps.canEnableBluetooth, isTrue);
      expect(caps.canDisableBluetooth, isFalse);
      expect(caps.canDiscoverDevices, isTrue);
      expect(caps.canGetPairedDevices, isTrue);
      expect(caps.canBondDevices, isTrue);
      expect(caps.canUnbondDevices, isTrue);
      expect(caps.canCreateServer, isTrue);
      expect(caps.canSetDiscoverable, isFalse);
      expect(caps.supportsMultipleConnections, isTrue);
      expect(caps.supportsSecureConnection, isTrue);
      expect(caps.supportsInsecureConnection, isFalse);
      expect(caps.requiresMfiCertification, isFalse);
      expect(caps.platformNote, 'Test platform');
    });

    test('PlatformException converted to BtcUnsupportedException', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (call) async {
        throw PlatformException(
          code: 'unsupported',
          message: 'Feature not available',
          details: {'feature': 'discovery', 'platform': 'iOS'},
        );
      });

      expect(
        () => platform.isSupported(),
        throwsA(isA<BtcUnsupportedException>().having(
          (e) => e.feature,
          'feature',
          'discovery',
        )),
      );
    });

    test('PlatformException converted to BtcPermissionException', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (call) async {
        throw PlatformException(code: 'permissionDenied', message: 'No BT permission');
      });

      expect(
        () => platform.isEnabled(),
        throwsA(isA<BtcPermissionException>()),
      );
    });

    test('PlatformException converted to BtcDisabledException', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (call) async {
        throw PlatformException(code: 'bluetoothDisabled', message: 'BT off');
      });

      expect(
        () => platform.startDiscovery(),
        throwsA(isA<BtcDisabledException>()),
      );
    });

    test('PlatformException converted to BtcConnectionException', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (call) async {
        throw PlatformException(
          code: 'connectionFailed',
          message: 'Refused',
          details: {'address': 'AA:BB:CC:DD:EE:FF'},
        );
      });

      expect(
        () => platform.connect(
          address: 'AA:BB:CC:DD:EE:FF',
          uuid: '00001101-0000-1000-8000-00805F9B34FB',
        ),
        throwsA(isA<BtcConnectionException>().having(
          (e) => e.address,
          'address',
          'AA:BB:CC:DD:EE:FF',
        )),
      );
    });

    test('PlatformException converted to BtcWriteException', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (call) async {
        throw PlatformException(code: 'writeFailed', message: 'Write error');
      });

      expect(
        () => platform.write(1, Uint8List(0)),
        throwsA(isA<BtcWriteException>()),
      );
    });

    test('PlatformException converted to BtcTimeoutException', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (call) async {
        throw PlatformException(
          code: 'timeout',
          message: 'Timed out',
          details: {'timeoutMs': 5000},
        );
      });

      expect(
        () => platform.connect(
          address: 'AA:BB:CC:DD:EE:FF',
          uuid: '00001101-0000-1000-8000-00805F9B34FB',
        ),
        throwsA(isA<BtcTimeoutException>().having(
          (e) => e.timeoutMs,
          'timeoutMs',
          5000,
        )),
      );
    });

    test('Unknown PlatformException converted to BtcException', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (call) async {
        throw PlatformException(code: 'unknown_code', message: 'Something');
      });

      expect(
        () => platform.isSupported(),
        throwsA(isA<BtcException>().having(
          (e) => e.code,
          'code',
          'unknown_code',
        )),
      );
    });
  });

  // ── BtcDevice Model ──────────────────────────────────────────────────

  group('BtcDevice', () {
    test('fromMap creates device correctly', () {
      final device = BtcDevice.fromMap({
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
      expect(device.type, BtcDeviceType.classic);
      expect(device.bondState, BtcBondState.bonded);
      expect(device.uuids, hasLength(1));
    });

    test('toMap round-trip is consistent', () {
      const original = BtcDevice(
        address: 'AA:BB:CC:DD:EE:FF',
        name: 'Dev',
        type: BtcDeviceType.dual,
        bondState: BtcBondState.bonding,
        uuids: ['uuid1'],
      );
      final map = original.toMap();
      final restored = BtcDevice.fromMap(map);

      expect(restored.address, original.address);
      expect(restored.name, original.name);
      expect(restored.type, original.type);
      expect(restored.bondState, original.bondState);
      expect(restored.uuids, original.uuids);
    });

    test('equality is based on address', () {
      const a = BtcDevice(address: 'AA:BB:CC:DD:EE:FF', name: 'A');
      const b = BtcDevice(address: 'AA:BB:CC:DD:EE:FF', name: 'B');
      const c = BtcDevice(address: '11:22:33:44:55:66', name: 'A');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });

    test('displayName falls back through alias → name → address', () {
      const withAlias = BtcDevice(
        address: 'AA:BB:CC:DD:EE:FF',
        name: 'Name',
        alias: 'Alias',
      );
      const withName = BtcDevice(
        address: 'AA:BB:CC:DD:EE:FF',
        name: 'Name',
      );
      const addressOnly = BtcDevice(address: 'AA:BB:CC:DD:EE:FF');

      expect(withAlias.displayName, 'Alias');
      expect(withName.displayName, 'Name');
      expect(addressOnly.displayName, 'AA:BB:CC:DD:EE:FF');
    });

    test('fromMap handles missing optional fields', () {
      final device = BtcDevice.fromMap({
        'address': 'AA:BB:CC:DD:EE:FF',
      });
      expect(device.name, isNull);
      expect(device.alias, isNull);
      expect(device.rssi, isNull);
      expect(device.type, BtcDeviceType.unknown);
      expect(device.bondState, BtcBondState.none);
      expect(device.uuids, isEmpty);
    });

    test('fromMap handles unknown enum values', () {
      final device = BtcDevice.fromMap({
        'address': 'AA:BB:CC:DD:EE:FF',
        'type': 'nonexistent_type',
        'bondState': 'weird',
      });
      expect(device.type, BtcDeviceType.unknown);
      expect(device.bondState, BtcBondState.none);
    });

    test('toString contains address and name', () {
      const device = BtcDevice(address: 'AA:BB:CC:DD:EE:FF', name: 'Dev');
      expect(device.toString(), contains('AA:BB:CC:DD:EE:FF'));
      expect(device.toString(), contains('Dev'));
    });
  });

  // ── PlatformCapabilities Model ────────────────────────────────────────

  group('PlatformCapabilities', () {
    test('fromMap creates capabilities correctly', () {
      final caps = BtcPlatformCapabilities.fromMap({
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
      const original = BtcPlatformCapabilities(
        canDiscoverDevices: true,
        canEnableBluetooth: true,
        requiresMfiCertification: true,
        platformNote: 'iOS',
      );
      final map = original.toMap();
      final restored = BtcPlatformCapabilities.fromMap(map);

      expect(restored.canDiscoverDevices, original.canDiscoverDevices);
      expect(restored.canEnableBluetooth, original.canEnableBluetooth);
      expect(restored.requiresMfiCertification, original.requiresMfiCertification);
      expect(restored.platformNote, original.platformNote);
    });

    test('defaults are all false/null', () {
      const caps = BtcPlatformCapabilities();
      expect(caps.canEnableBluetooth, isFalse);
      expect(caps.canDisableBluetooth, isFalse);
      expect(caps.canDiscoverDevices, isFalse);
      expect(caps.canGetPairedDevices, isFalse);
      expect(caps.canBondDevices, isFalse);
      expect(caps.canUnbondDevices, isFalse);
      expect(caps.canCreateServer, isFalse);
      expect(caps.canSetDiscoverable, isFalse);
      expect(caps.supportsMultipleConnections, isFalse);
      expect(caps.supportsSecureConnection, isFalse);
      expect(caps.supportsInsecureConnection, isFalse);
      expect(caps.requiresMfiCertification, isFalse);
      expect(caps.platformNote, isNull);
    });

    test('fromMap handles missing keys with defaults', () {
      final caps = BtcPlatformCapabilities.fromMap({});
      expect(caps.canEnableBluetooth, isFalse);
      expect(caps.canDiscoverDevices, isFalse);
      expect(caps.platformNote, isNull);
    });
  });

  // ── Exception Hierarchy ───────────────────────────────────────────────

  group('Exception hierarchy', () {
    test('BtcException stores message and code', () {
      const ex = BtcException('test error', code: 'testCode');
      expect(ex.message, 'test error');
      expect(ex.code, 'testCode');
      expect(ex.toString(), contains('testCode'));
    });

    test('BtcException without code', () {
      const ex = BtcException('simple error');
      expect(ex.code, isNull);
    });

    test('BtcUnsupportedException has feature and platform', () {
      const ex = BtcUnsupportedException(
        feature: 'discovery',
        platform: 'iOS',
      );
      expect(ex.feature, 'discovery');
      expect(ex.platform, 'iOS');
      expect(ex.toString(), contains('discovery'));
      expect(ex.toString(), contains('iOS'));
    });

    test('BtcUnsupportedException with custom reason', () {
      const ex = BtcUnsupportedException(
        feature: 'server',
        platform: 'iOS',
        reason: 'Custom reason',
      );
      expect(ex.message, 'Custom reason');
    });

    test('BtcConnectionException has address', () {
      const ex = BtcConnectionException(
        'Connection refused',
        address: 'AA:BB:CC:DD:EE:FF',
      );
      expect(ex.address, 'AA:BB:CC:DD:EE:FF');
      expect(ex.message, 'Connection refused');
      expect(ex.code, 'connectionFailed');
    });

    test('BtcConnectionException without address', () {
      const ex = BtcConnectionException('Failed');
      expect(ex.address, isNull);
    });

    test('BtcAddressException has address', () {
      const ex = BtcAddressException('INVALID');
      expect(ex.address, 'INVALID');
      expect(ex.toString(), contains('INVALID'));
      expect(ex.code, 'invalidAddress');
    });

    test('BtcUuidException has uuid', () {
      const ex = BtcUuidException('bad-uuid');
      expect(ex.uuid, 'bad-uuid');
      expect(ex.code, 'invalidUuid');
    });

    test('BtcTimeoutException has timeoutMs', () {
      const ex = BtcTimeoutException(timeoutMs: 3000);
      expect(ex.timeoutMs, 3000);
      expect(ex.code, 'timeout');
    });

    test('BtcPermissionException defaults', () {
      const ex = BtcPermissionException();
      expect(ex.message, 'Bluetooth permission denied');
      expect(ex.code, 'permissionDenied');
    });

    test('BtcDisabledException defaults', () {
      const ex = BtcDisabledException();
      expect(ex.message, 'Bluetooth adapter is disabled');
      expect(ex.code, 'bluetoothDisabled');
    });

    test('BtcWriteException defaults', () {
      const ex = BtcWriteException();
      expect(ex.message, 'Failed to write data');
      expect(ex.code, 'writeFailed');
    });

    test('all exceptions are BtcException', () {
      expect(
        const BtcPermissionException(),
        isA<BtcException>(),
      );
      expect(
        const BtcDisabledException(),
        isA<BtcException>(),
      );
      expect(
        const BtcWriteException(),
        isA<BtcException>(),
      );
      expect(
        const BtcTimeoutException(),
        isA<BtcException>(),
      );
      expect(
        const BtcAddressException('test'),
        isA<BtcException>(),
      );
      expect(
        const BtcUuidException('test'),
        isA<BtcException>(),
      );
      expect(
        const BtcUnsupportedException(feature: 'f', platform: 'p'),
        isA<BtcException>(),
      );
      expect(
        const BtcConnectionException('test'),
        isA<BtcException>(),
      );
    });

    test('all exceptions implement Exception', () {
      expect(const BtcException('test'), isA<Exception>());
      expect(const BtcPermissionException(), isA<Exception>());
    });
  });

  // ── BtcStreamSink ────────────────────────────────────────────────────

  group('BtcStreamSink', () {
    test('throws StateError after close', () async {
      final sink = BtcStreamSink(
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

    test('isClosed is false initially', () {
      final sink = BtcStreamSink(
        connectionId: 1,
        methodChannel: const MethodChannel('flutter_classic_bluetooth/methods'),
      );
      expect(sink.isClosed, isFalse);
    });

    test('cancel marks sink as closed', () {
      final sink = BtcStreamSink(
        connectionId: 1,
        methodChannel: const MethodChannel('flutter_classic_bluetooth/methods'),
      );
      sink.cancel();
      expect(sink.isClosed, isTrue);
    });

    test('close marks sink as closed', () async {
      final sink = BtcStreamSink(
        connectionId: 1,
        methodChannel: const MethodChannel('flutter_classic_bluetooth/methods'),
      );
      await sink.close();
      expect(sink.isClosed, isTrue);
    });

    test('double close does not throw', () async {
      final sink = BtcStreamSink(
        connectionId: 1,
        methodChannel: const MethodChannel('flutter_classic_bluetooth/methods'),
      );
      await sink.close();
      await sink.close();
      expect(sink.isClosed, isTrue);
    });

    test('add sends write over method channel', () async {
      final methodChannel = const MethodChannel('flutter_classic_bluetooth/methods');
      final calls = <MethodCall>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, (call) async {
        calls.add(call);
        return null;
      });

      final sink = BtcStreamSink(
        connectionId: 42,
        methodChannel: methodChannel,
      );

      final data = Uint8List.fromList([1, 2, 3]);
      await sink.add(data);

      expect(calls, hasLength(1));
      expect(calls.first.method, 'write');
      expect(calls.first.arguments['id'], 42);
      expect(calls.first.arguments['data'], data);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, null);
    });

    test('writes are chained in order', () async {
      final methodChannel = const MethodChannel('flutter_classic_bluetooth/methods');
      final calls = <int>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, (call) async {
        calls.add(call.arguments['data'][0] as int);
        return null;
      });

      final sink = BtcStreamSink(
        connectionId: 1,
        methodChannel: methodChannel,
      );

      // Fire-and-forget multiple writes
      sink.add(Uint8List.fromList([1]));
      sink.add(Uint8List.fromList([2]));
      await sink.add(Uint8List.fromList([3]));

      expect(calls, [1, 2, 3]);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, null);
    });
  });

  // ── BtcConnection ────────────────────────────────────────────────────

  group('BtcConnection', () {
    test('constructor sets properties correctly', () {
      final conn = BtcConnection(
        id: 5,
        address: 'AA:BB:CC:DD:EE:FF',
        methodChannel: const MethodChannel('flutter_classic_bluetooth/methods'),
      );

      expect(conn.id, 5);
      expect(conn.address, 'AA:BB:CC:DD:EE:FF');
      expect(conn.isConnected, isTrue);
      expect(conn.state, BtcConnectionState.connected);
    });

    test('output sink is a BtcStreamSink', () {
      final conn = BtcConnection(
        id: 1,
        address: 'AA:BB:CC:DD:EE:FF',
        methodChannel: const MethodChannel('flutter_classic_bluetooth/methods'),
      );

      expect(conn.output, isA<BtcStreamSink>());
      expect(conn.output.isClosed, isFalse);
    });

    test('dispose cancels output sink', () {
      final conn = BtcConnection(
        id: 1,
        address: 'AA:BB:CC:DD:EE:FF',
        methodChannel: const MethodChannel('flutter_classic_bluetooth/methods'),
      );

      conn.dispose();
      expect(conn.output.isClosed, isTrue);
    });
  });

  // ── BtcServerSocket ──────────────────────────────────────────────────

  group('BtcServerSocket', () {
    test('constructor sets properties correctly', () {
      final server = BtcServerSocket(
        id: 3,
        uuid: '00001101-0000-1000-8000-00805F9B34FB',
        serviceName: 'TestService',
        methodChannel: const MethodChannel('flutter_classic_bluetooth/methods'),
      );

      expect(server.id, 3);
      expect(server.uuid, '00001101-0000-1000-8000-00805F9B34FB');
      expect(server.serviceName, 'TestService');
    });

    test('close sends stopServer method call', () async {
      final methodChannel = const MethodChannel('flutter_classic_bluetooth/methods');
      final calls = <MethodCall>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, (call) async {
        calls.add(call);
        return null;
      });

      final server = BtcServerSocket(
        id: 7,
        uuid: '00001101-0000-1000-8000-00805F9B34FB',
        serviceName: 'Test',
        methodChannel: methodChannel,
      );

      await server.close();

      expect(calls, hasLength(1));
      expect(calls.first.method, 'stopServer');
      expect(calls.first.arguments, {'id': 7});

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, null);
    });
  });

  // ── Enum Values ───────────────────────────────────────────────────────

  group('Enums', () {
    test('BtcAdapterState has all expected values', () {
      expect(BtcAdapterState.values, hasLength(7));
      expect(BtcAdapterState.values, contains(BtcAdapterState.on));
      expect(BtcAdapterState.values, contains(BtcAdapterState.off));
      expect(BtcAdapterState.values, contains(BtcAdapterState.unknown));
    });

    test('BtcBondState has all expected values', () {
      expect(BtcBondState.values, hasLength(3));
    });

    test('BtcDeviceType has all expected values', () {
      expect(BtcDeviceType.values, hasLength(4));
    });

    test('BtcConnectionState has all expected values', () {
      expect(BtcConnectionState.values, hasLength(4));
    });
  });
}

/// A platform that doesn't implement anything — used to verify
/// that all methods throw [UnimplementedError].
class _UnimplementedPlatform extends FlutterClassicBluetoothPlatform {}
