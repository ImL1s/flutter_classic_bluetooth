// Smoke test for the example app. It mocks the plugin's method channel so the
// reactive controller initialises cleanly without a real Bluetooth stack.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_classic_bluetooth_example/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_classic_bluetooth/methods');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'isSupported':
              return true;
            case 'isEnabled':
              return false;
            case 'getPlatformCapabilities':
              return <String, dynamic>{
                'canDiscoverDevices': true,
                'canGetPairedDevices': true,
                'canCreateServer': true,
              };
            case 'getPairedDevices':
              return <dynamic>[];
            case 'getAdapterName':
              return 'Test Adapter';
            case 'getAdapterAddress':
              return '00:11:22:33:44:55';
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('App builds and shows the title bar', (tester) async {
    await tester.pumpWidget(const BluetoothExampleApp());
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(BluetoothExampleApp), findsOneWidget);
    expect(find.text('Bluetooth Classic'), findsOneWidget);
  });
}
