import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';
import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth_platform_interface.dart';
import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterClassicBluetoothPlatform
    with MockPlatformInterfaceMixin
    implements FlutterClassicBluetoothPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterClassicBluetoothPlatform initialPlatform = FlutterClassicBluetoothPlatform.instance;

  test('$MethodChannelFlutterClassicBluetooth is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterClassicBluetooth>());
  });

  test('getPlatformVersion', () async {
    FlutterClassicBluetooth flutterClassicBluetoothPlugin = FlutterClassicBluetooth();
    MockFlutterClassicBluetoothPlatform fakePlatform = MockFlutterClassicBluetoothPlatform();
    FlutterClassicBluetoothPlatform.instance = fakePlatform;

    expect(await flutterClassicBluetoothPlugin.getPlatformVersion(), '42');
  });
}
