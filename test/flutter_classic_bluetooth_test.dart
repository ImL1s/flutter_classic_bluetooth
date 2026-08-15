import 'dart:async';

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
  Stream<BtcAdapterState> adapterState() => Stream.value(BtcAdapterState.on);

  @override
  Future<String?> getAdapterName() => Future.value('TestAdapter');

  @override
  Future<String?> getAdapterAddress() => Future.value('AA:BB:CC:DD:EE:FF');

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
  Future<List<BtcDevice>> getPairedDevices() => Future.value([
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

  /// Overrides what `connect()` returns, for tests about the call itself
  /// rather than about the connection it produces.
  Future<BtcConnection> Function()? connectResponse;

  @override
  Future<BtcConnection> connect({
    required String address,
    String uuid = BtcUuid.spp,
    bool secure = true,
    int? channel,
  }) {
    final override = connectResponse;
    if (override != null) return override();
    throw UnimplementedError('connect() mock not implemented');
  }

  /// Addresses this mock was asked to abort, in order.
  final List<String> cancelledConnects = [];

  int? sdkInt = 34;

  @override
  Future<int?> androidSdkInt() => Future.value(sdkInt);

  @override
  Future<bool> cancelConnect(String address) {
    cancelledConnects.add(address);
    return Future.value(true);
  }

  @override
  Future<void> disconnect(int id) => Future.value();

  @override
  Future<void> write(int id, Uint8List data) => Future.value();

  @override
  Future<BtcServerSocket> startServer({
    required String serviceName,
    String uuid = BtcUuid.spp,
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
  explicitChannelTests();
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
      expect(() => platform.bondDevice('AA:BB:CC:DD:EE:FF'),
          throwsUnimplementedError);
      expect(() => platform.unbondDevice('AA:BB:CC:DD:EE:FF'),
          throwsUnimplementedError);
      expect(() => platform.bondState('AA:BB:CC:DD:EE:FF'),
          throwsUnimplementedError);
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
      expect(
          () => platform.getPlatformCapabilities(), throwsUnimplementedError);
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
      // The mock throws UnimplementedError for connect, which is fine.
      // We verify validation passes.
      expect(
        () => bluetooth.connect(
          address: 'AA:BB:CC:DD:EE:FF',
          uuid: '00001101-0000-1000-8000-00805F9B34FB',
        ),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('connect with no uuid passes validation (defaults to SPP)', () {
      // Validation passes (no BtcUuidException) and reaches the mock,
      // which throws UnimplementedError, proving the SPP default is valid.
      expect(
        () => bluetooth.connect(address: 'AA:BB:CC:DD:EE:FF'),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('startServer with no uuid passes validation (defaults to SPP)', () {
      expect(
        () => bluetooth.startServer(serviceName: 'svc'),
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

    test('connect defaults uuid to SPP when omitted', () async {
      await platform.connect(address: 'AA:BB:CC:DD:EE:FF');
      expect(log.last.method, 'connect');
      expect(log.last.arguments['uuid'], BtcUuid.spp);
      expect(log.last.arguments['secure'], true);
    });

    test('startServer defaults uuid to SPP when omitted', () async {
      await platform.startServer(serviceName: 'TestService');
      expect(log.last.method, 'startServer');
      expect(log.last.arguments['uuid'], BtcUuid.spp);
      expect(log.last.arguments['serviceName'], 'TestService');
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
        throw PlatformException(
            code: 'permissionDenied', message: 'No BT permission');
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

    test('mergedWith keeps earlier non-null fields, applies new ones', () {
      const a = BtcDevice(
        address: 'AA:BB:CC:DD:EE:FF',
        name: 'Name',
        rssi: -50,
        uuids: ['u1'],
      );
      const b = BtcDevice(address: 'AA:BB:CC:DD:EE:FF', rssi: -40);
      final m = a.mergedWith(b);
      expect(m.name, 'Name'); // preserved (b had none)
      expect(m.rssi, -40); // updated
      expect(m.uuids, ['u1']); // preserved
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
        canReadConnectionRssi: true,
        requiresMfiCertification: true,
        platformNote: 'iOS',
      );
      final map = original.toMap();
      final restored = BtcPlatformCapabilities.fromMap(map);

      expect(restored.canDiscoverDevices, original.canDiscoverDevices);
      expect(restored.canEnableBluetooth, original.canEnableBluetooth);
      expect(restored.canReadConnectionRssi, original.canReadConnectionRssi);
      expect(
          restored.requiresMfiCertification, original.requiresMfiCertification);
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
      expect(caps.canReadConnectionRssi, isFalse);
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
      final methodChannel =
          const MethodChannel('flutter_classic_bluetooth/methods');
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

    test('writeLine appends the newline', () async {
      const methodChannel = MethodChannel('flutter_classic_bluetooth/methods');
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, (call) async {
        calls.add(call);
        return null;
      });

      final sink = BtcStreamSink(connectionId: 9, methodChannel: methodChannel);
      await sink.writeLine('AT');

      expect(
        String.fromCharCodes(calls.single.arguments['data'] as Uint8List),
        'AT\r\n',
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, null);
    });

    test('writes are chained in order', () async {
      final methodChannel =
          const MethodChannel('flutter_classic_bluetooth/methods');
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

    test('sendAndReceive writes the command and returns the response line',
        () async {
      const method = MethodChannel('flutter_classic_bluetooth/methods');
      const dataChannel =
          EventChannel('flutter_classic_bluetooth/connection/1');
      const stateChannel =
          EventChannel('flutter_classic_bluetooth/connection_state/1');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

      final writes = <String>[];
      messenger.setMockMethodCallHandler(method, (call) async {
        if (call.method == 'write') {
          writes.add(String.fromCharCodes(call.arguments['data'] as Uint8List));
        }
        return null;
      });
      MockStreamHandlerEventSink? dataSink;
      messenger.setMockStreamHandler(
        dataChannel,
        MockStreamHandler.inline(onListen: (args, sink) => dataSink = sink),
      );
      messenger.setMockStreamHandler(
        stateChannel,
        MockStreamHandler.inline(onListen: (args, sink) {}),
      );

      final conn = BtcConnection(
        id: 1,
        address: 'AA:BB:CC:DD:EE:FF',
        methodChannel: method,
      );

      final future =
          conn.sendAndReceive('AT', timeout: const Duration(seconds: 2));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      dataSink!.success(Uint8List.fromList('OK\r\n'.codeUnits));

      expect(await future, 'OK');
      expect(writes, ['AT\r\n']);

      conn.dispose();
      messenger.setMockMethodCallHandler(method, null);
      messenger.setMockStreamHandler(dataChannel, null);
      messenger.setMockStreamHandler(stateChannel, null);
    });

    test('sendAndReceive throws BtcTimeoutException when no response arrives',
        () async {
      const method = MethodChannel('flutter_classic_bluetooth/methods');
      const dataChannel =
          EventChannel('flutter_classic_bluetooth/connection/2');
      const stateChannel =
          EventChannel('flutter_classic_bluetooth/connection_state/2');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

      messenger.setMockMethodCallHandler(method, (call) async => null);
      messenger.setMockStreamHandler(
        dataChannel,
        MockStreamHandler.inline(onListen: (args, sink) {}),
      );
      messenger.setMockStreamHandler(
        stateChannel,
        MockStreamHandler.inline(onListen: (args, sink) {}),
      );

      final conn = BtcConnection(
        id: 2,
        address: 'AA:BB:CC:DD:EE:FF',
        methodChannel: method,
      );

      await expectLater(
        conn.sendAndReceive('AT', timeout: const Duration(milliseconds: 50)),
        throwsA(isA<BtcTimeoutException>()),
      );

      conn.dispose();
      messenger.setMockMethodCallHandler(method, null);
      messenger.setMockStreamHandler(dataChannel, null);
      messenger.setMockStreamHandler(stateChannel, null);
    });

    test('readRssi sends getConnectionRssi and returns the value', () async {
      const method = MethodChannel('flutter_classic_bluetooth/methods');
      const dataChannel =
          EventChannel('flutter_classic_bluetooth/connection/7');
      const stateChannel =
          EventChannel('flutter_classic_bluetooth/connection_state/7');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

      MethodCall? seen;
      messenger.setMockMethodCallHandler(method, (call) async {
        seen = call;
        return -42;
      });
      messenger.setMockStreamHandler(
          dataChannel, MockStreamHandler.inline(onListen: (args, sink) {}));
      messenger.setMockStreamHandler(
          stateChannel, MockStreamHandler.inline(onListen: (args, sink) {}));

      final conn = BtcConnection(
          id: 7, address: 'AA:BB:CC:DD:EE:FF', methodChannel: method);

      expect(await conn.readRssi(), -42);
      expect(seen?.method, 'getConnectionRssi');
      expect(seen?.arguments['id'], 7);

      conn.dispose();
      messenger.setMockMethodCallHandler(method, null);
      messenger.setMockStreamHandler(dataChannel, null);
      messenger.setMockStreamHandler(stateChannel, null);
    });

    test('readRssi returns null when the platform has no sample', () async {
      const method = MethodChannel('flutter_classic_bluetooth/methods');
      const dataChannel =
          EventChannel('flutter_classic_bluetooth/connection/8');
      const stateChannel =
          EventChannel('flutter_classic_bluetooth/connection_state/8');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

      messenger.setMockMethodCallHandler(method, (call) async => null);
      messenger.setMockStreamHandler(
          dataChannel, MockStreamHandler.inline(onListen: (args, sink) {}));
      messenger.setMockStreamHandler(
          stateChannel, MockStreamHandler.inline(onListen: (args, sink) {}));

      final conn = BtcConnection(
          id: 8, address: 'AA:BB:CC:DD:EE:FF', methodChannel: method);

      expect(await conn.readRssi(), isNull);

      conn.dispose();
      messenger.setMockMethodCallHandler(method, null);
      messenger.setMockStreamHandler(dataChannel, null);
      messenger.setMockStreamHandler(stateChannel, null);
    });

    test('readRssi maps an unsupported PlatformException to unsupported',
        () async {
      const method = MethodChannel('flutter_classic_bluetooth/methods');
      const dataChannel =
          EventChannel('flutter_classic_bluetooth/connection/9');
      const stateChannel =
          EventChannel('flutter_classic_bluetooth/connection_state/9');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

      messenger.setMockMethodCallHandler(method, (call) async {
        throw PlatformException(
          code: 'unsupported',
          message: 'no RSSI on Windows',
          details: {'feature': 'getConnectionRssi', 'platform': 'Windows'},
        );
      });
      messenger.setMockStreamHandler(
          dataChannel, MockStreamHandler.inline(onListen: (args, sink) {}));
      messenger.setMockStreamHandler(
          stateChannel, MockStreamHandler.inline(onListen: (args, sink) {}));

      final conn = BtcConnection(
          id: 9, address: 'AA:BB:CC:DD:EE:FF', methodChannel: method);

      await expectLater(
        conn.readRssi(),
        throwsA(isA<BtcUnsupportedException>()
            .having((e) => e.platform, 'platform', 'Windows')),
      );

      conn.dispose();
      messenger.setMockMethodCallHandler(method, null);
      messenger.setMockStreamHandler(dataChannel, null);
      messenger.setMockStreamHandler(stateChannel, null);
    });

    test('readRssi maps a MissingPluginException to unsupported', () async {
      const method = MethodChannel('flutter_classic_bluetooth/methods');
      const dataChannel =
          EventChannel('flutter_classic_bluetooth/connection/10');
      const stateChannel =
          EventChannel('flutter_classic_bluetooth/connection_state/10');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

      // No method handler → invokeMethod throws MissingPluginException.
      messenger.setMockMethodCallHandler(method, null);
      messenger.setMockStreamHandler(
          dataChannel, MockStreamHandler.inline(onListen: (args, sink) {}));
      messenger.setMockStreamHandler(
          stateChannel, MockStreamHandler.inline(onListen: (args, sink) {}));

      final conn = BtcConnection(
          id: 10, address: 'AA:BB:CC:DD:EE:FF', methodChannel: method);

      await expectLater(
        conn.readRssi(),
        throwsA(isA<BtcUnsupportedException>()),
      );

      conn.dispose();
      messenger.setMockStreamHandler(dataChannel, null);
      messenger.setMockStreamHandler(stateChannel, null);
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
      final methodChannel =
          const MethodChannel('flutter_classic_bluetooth/methods');
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

  // ── BtcUuid Constants ─────────────────────────────────────────────────

  group('BtcUuid', () {
    test('spp is the canonical Serial Port Profile UUID', () {
      expect(BtcUuid.spp, '00001101-0000-1000-8000-00805F9B34FB');
    });
  });

  group('scan', () {
    test('collects, de-dupes and sorts results by signal', () async {
      final platform = _ScanPlatform();
      FlutterClassicBluetoothPlatform.instance = platform;
      addTearDown(platform.controller.close);
      final bluetooth = FlutterClassicBluetooth();

      final devices =
          await bluetooth.scan(timeout: const Duration(milliseconds: 60));

      expect(
        devices.map((d) => d.address).toList(),
        ['AA:BB:CC:DD:EE:F1', 'AA:BB:CC:DD:EE:F2'], // strongest first
      );
      expect(
          devices.first.name, 'One'); // preserved across the rssi-only update
      expect(devices.first.rssi, -35); // updated
    });
  });

  // ── Frame splitting / line reading ────────────────────────────────────

  group('BtcFrameSplitter', () {
    Uint8List b(String s) => Uint8List.fromList(s.codeUnits);

    test('emits frames split on the delimiter, delimiter stripped', () async {
      final src = StreamController<Uint8List>();
      final out = src.stream.frames().map(String.fromCharCodes).toList();
      src
        ..add(b('one\ntwo\n'))
        ..add(b('three\n'));
      await src.close();
      expect(await out, ['one', 'two', 'three']);
    });

    test('reassembles a frame split across chunks', () async {
      final src = StreamController<Uint8List>();
      final out = src.stream.frames().map(String.fromCharCodes).toList();
      src
        ..add(b('hel'))
        ..add(b('lo\nwor'))
        ..add(b('ld\n'));
      await src.close();
      expect(await out, ['hello', 'world']);
    });

    test('does not emit a trailing un-terminated remainder', () async {
      final src = StreamController<Uint8List>();
      final out = src.stream.frames().map(String.fromCharCodes).toList();
      src.add(b('done\npartial'));
      await src.close();
      expect(await out, ['done']);
    });

    test('supports a multi-byte delimiter', () async {
      final src = StreamController<Uint8List>();
      final out = src.stream
          .frames(delimiter: const [0x0D, 0x0A]) // \r\n
          .map(String.fromCharCodes)
          .toList();
      src.add(b('a\r\nb\r\n'));
      await src.close();
      expect(await out, ['a', 'b']);
    });

    test('lines() decodes and strips a trailing CR (\\r\\n)', () async {
      final src = StreamController<Uint8List>();
      final out = src.stream.lines().toList();
      src.add(b('crlf\r\nlf\n'));
      await src.close();
      expect(await out, ['crlf', 'lf']);
    });

    test('errors and drops the buffer past maxFrameLength', () async {
      final src = StreamController<Uint8List>();
      final errors = <Object>[];
      final frames = <String>[];
      final done = Completer<void>();
      src.stream.frames(maxFrameLength: 4).listen(
            (f) => frames.add(String.fromCharCodes(f)),
            onError: errors.add,
            onDone: done.complete,
          );
      src.add(b('toolong')); // 7 bytes, no delimiter
      src.add(b('ok\n'));
      await src.close();
      await done.future;
      expect(errors, hasLength(1));
      expect(errors.first, isA<StateError>());
      expect(frames, ['ok']); // recovered after the buffer was dropped
    });
  });

  // ── Auto-reconnect ────────────────────────────────────────────────────

  group('BtcReconnectPolicy', () {
    test('defaults retry forever with 1s→30s backoff', () {
      const p = BtcReconnectPolicy();
      expect(p.maxAttempts, isNull);
      expect(p.initialBackoff, const Duration(seconds: 1));
      expect(p.maxBackoff, const Duration(seconds: 30));
      expect(p.connectTimeout, const Duration(seconds: 15));
    });

    test('backoffForAttempt is exponential and capped', () {
      const p = BtcReconnectPolicy(
        initialBackoff: Duration(seconds: 1),
        maxBackoff: Duration(seconds: 8),
        backoffMultiplier: 2.0,
      );
      expect(p.backoffForAttempt(1), const Duration(seconds: 1));
      expect(p.backoffForAttempt(2), const Duration(seconds: 2));
      expect(p.backoffForAttempt(3), const Duration(seconds: 4));
      expect(p.backoffForAttempt(4), const Duration(seconds: 8));
      expect(p.backoffForAttempt(5), const Duration(seconds: 8)); // capped
      expect(p.backoffForAttempt(0), const Duration(seconds: 1)); // guarded
    });
  });

  group('connectWithReconnect validation', () {
    setUp(() {
      FlutterClassicBluetoothPlatform.instance =
          MockFlutterClassicBluetoothPlatform();
    });

    test('throws on invalid address', () {
      expect(
        () => FlutterClassicBluetooth().connectWithReconnect(address: 'bad'),
        throwsA(isA<BtcAddressException>()),
      );
    });

    test('throws on invalid uuid', () {
      expect(
        () => FlutterClassicBluetooth().connectWithReconnect(
          address: 'AA:BB:CC:DD:EE:FF',
          uuid: 'nope',
        ),
        throwsA(isA<BtcUuidException>()),
      );
    });
  });

  group('BtcReconnectingConnection', () {
    test('initial state is connecting before it is started', () {
      final link = BtcReconnectingConnection(
        address: 'AA:BB:CC:DD:EE:FF',
        connector: () async => throw const BtcConnectionException('not called'),
      );
      addTearDown(link.close);
      expect(link.currentState, BtcReconnectState.connecting);
      expect(link.isConnected, isFalse);
      expect(link.connection, isNull);
    });

    test('send throws when not connected', () {
      final link = BtcReconnectingConnection(
        address: 'AA:BB:CC:DD:EE:FF',
        connector: () async => throw const BtcConnectionException('not called'),
      );
      addTearDown(link.close);
      expect(
        () => link.sendString('hi'),
        throwsA(isA<BtcConnectionException>()),
      );
    });

    test('retries with backoff then fails after maxAttempts', () async {
      var calls = 0;
      final link = BtcReconnectingConnection(
        address: 'AA:BB:CC:DD:EE:FF',
        connector: () async {
          calls++;
          throw const BtcConnectionException('refused');
        },
        policy: const BtcReconnectPolicy(
          maxAttempts: 2,
          initialBackoff: Duration(milliseconds: 5),
          maxBackoff: Duration(milliseconds: 5),
          backoffMultiplier: 1.0,
          connectTimeout: null,
        ),
      )..start();
      addTearDown(link.close);

      final states = <BtcReconnectState>[];
      link.state.listen(states.add);

      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(calls, 3); // initial attempt + 2 retries
      expect(link.currentState, BtcReconnectState.failed);
      expect(states, contains(BtcReconnectState.reconnecting));
      expect(states.last, BtcReconnectState.failed);
    });

    test('exposes attempts and lastError after failures', () async {
      final link = BtcReconnectingConnection(
        address: 'AA:BB:CC:DD:EE:FF',
        connector: () async => throw const BtcConnectionException('refused'),
        policy: const BtcReconnectPolicy(
          maxAttempts: 1,
          initialBackoff: Duration(milliseconds: 5),
          maxBackoff: Duration(milliseconds: 5),
          backoffMultiplier: 1.0,
          connectTimeout: null,
        ),
      )..start();
      addTearDown(link.close);

      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(link.currentState, BtcReconnectState.failed);
      expect(link.attempts, greaterThan(0));
      expect(link.lastError, isA<BtcConnectionException>());
    });

    test('close() stops further reconnects', () async {
      var calls = 0;
      final link = BtcReconnectingConnection(
        address: 'AA:BB:CC:DD:EE:FF',
        connector: () async {
          calls++;
          throw const BtcConnectionException('refused');
        },
        policy: const BtcReconnectPolicy(
          initialBackoff: Duration(milliseconds: 5),
          maxBackoff: Duration(milliseconds: 5),
          backoffMultiplier: 1.0,
          connectTimeout: null,
        ),
      )..start();

      await Future<void>.delayed(const Duration(milliseconds: 15));
      await link.close();
      final after = calls;
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(link.currentState, BtcReconnectState.closed);
      expect(calls, after); // no attempts after close
    });
  });
}

/// A platform that doesn't implement anything, used to verify
/// that all methods throw [UnimplementedError].
class _UnimplementedPlatform extends FlutterClassicBluetoothPlatform {}

/// A platform that emits a few discovery results (including a name-less RSSI
/// update) when discovery starts, used to exercise [FlutterClassicBluetooth.scan].
class _ScanPlatform extends MockFlutterClassicBluetoothPlatform {
  final StreamController<BtcDevice> controller =
      StreamController<BtcDevice>.broadcast();

  @override
  Stream<BtcDevice> discoveryResults() => controller.stream;

  @override
  Future<void> startDiscovery() async {
    controller.add(
      const BtcDevice(address: 'AA:BB:CC:DD:EE:F1', name: 'One', rssi: -40),
    );
    controller.add(
      const BtcDevice(address: 'AA:BB:CC:DD:EE:F2', name: 'Two', rssi: -70),
    );
    // A follow-up sighting of F1 with only a stronger RSSI (no name).
    controller.add(const BtcDevice(address: 'AA:BB:CC:DD:EE:F1', rssi: -35));
  }
}

/// Connecting to an explicit RFCOMM channel.
///
/// Both UUID-based factory methods perform an SDP lookup and fail when the
/// device publishes no usable SPP record. A large family of cheap serial
/// adapters — ELM327 OBD-II clones above all — listen on channel 1 and
/// advertise nothing, so they pair normally and cannot be connected to by UUID
/// at all. `channel:` is the escape hatch for exactly those devices.
void explicitChannelTests() {
  group('connect(channel:)', () {
    late MethodChannelFlutterClassicBluetooth platform;
    late List<MethodCall> log;

    setUp(() {
      platform = MethodChannelFlutterClassicBluetooth();
      log = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel,
              (MethodCall call) async {
        log.add(call);
        if (call.method == 'connect') {
          return {'id': 1, 'address': call.arguments['address']};
        }
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, null);
    });

    test('is forwarded to the platform', () async {
      await platform.connect(address: '11:22:33:44:55:66', channel: 1);
      expect(log.single.arguments['channel'], 1);
    });

    test('is omitted entirely when not given', () async {
      // Absent rather than null, so a native build that predates this key
      // behaves exactly as it did before.
      await platform.connect(address: '11:22:33:44:55:66');
      expect(log.single.arguments.containsKey('channel'), isFalse);
    });

    test('an out-of-range channel is refused before any I/O', () {
      // A programming error should read as one, not as a connection failure to
      // be diagnosed against the adapter.
      final btc = FlutterClassicBluetooth();
      for (final bad in [0, -1, 31]) {
        expect(
          () => btc.connect(address: '11:22:33:44:55:66', channel: bad),
          throwsA(isA<ArgumentError>()),
          reason: 'channel $bad',
        );
      }
    });

    test('the UUID is not validated when a channel is given', () async {
      // The UUID is unused on this path, so rejecting a malformed one would
      // block a call that is perfectly well formed.
      final btc = FlutterClassicBluetooth();
      await expectLater(
        btc.connect(
          address: '11:22:33:44:55:66',
          uuid: 'not-a-uuid',
          channel: 1,
        ),
        completes,
      );
    });
  });

  group('connect timeout', () {
    test('aborts the native attempt rather than only giving up on it',
        () async {
      // `BluetoothSocket.connect()` has no timeout and no interrupt, so a
      // Dart-side `Future.timeout` used to stop the caller waiting while the
      // native call stayed blocked — holding the device against every later
      // attempt until the app was restarted, and letting a late success
      // register a connection Dart could no longer close. A caller walking a
      // fallback cascade would stack one of these per tier.
      final previous = FlutterClassicBluetoothPlatform.instance;
      addTearDown(() => FlutterClassicBluetoothPlatform.instance = previous);

      final mock = MockFlutterClassicBluetoothPlatform();
      // Never completes, which is exactly what a wedged adapter looks like.
      mock.connectResponse = () => Completer<BtcConnection>().future;
      FlutterClassicBluetoothPlatform.instance = mock;

      final btc = FlutterClassicBluetooth();
      await expectLater(
        btc.connect(
          address: 'AA:BB:CC:DD:EE:FF',
          timeout: const Duration(milliseconds: 50),
        ),
        throwsA(isA<BtcTimeoutException>()),
      );

      expect(
        mock.cancelledConnects,
        equals(['AA:BB:CC:DD:EE:FF']),
        reason: 'the socket must be closed, because closing it is the only '
            'thing that releases a blocked connect()',
      );
    });
  });
}
