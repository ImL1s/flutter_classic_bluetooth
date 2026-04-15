import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';
import 'package:flutter_classic_bluetooth_example/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Plugin API', () {
    late FlutterClassicBluetooth bluetooth;

    setUp(() {
      bluetooth = FlutterClassicBluetooth();
    });

    testWidgets('isSupported returns a bool', (tester) async {
      final result = await bluetooth.isSupported();
      expect(result, isA<bool>());
    });

    testWidgets('isEnabled returns a bool', (tester) async {
      final result = await bluetooth.isEnabled();
      expect(result, isA<bool>());
    });

    testWidgets('getAdapterName returns String or null', (tester) async {
      final name = await bluetooth.getAdapterName();
      expect(name, anyOf(isA<String>(), isNull));
    });

    testWidgets('getAdapterAddress returns String or null', (tester) async {
      final address = await bluetooth.getAdapterAddress();
      expect(address, anyOf(isA<String>(), isNull));
    });

    testWidgets('isDiscovering returns a bool', (tester) async {
      final result = await bluetooth.isDiscovering();
      expect(result, isA<bool>());
    });

    testWidgets('getPairedDevices returns a list', (tester) async {
      try {
        final devices = await bluetooth.getPairedDevices();
        expect(devices, isA<List<BluetoothDevice>>());
      } on BluetoothException {
        // BT may be disabled - still valid
      }
    });

    testWidgets('getPlatformCapabilities returns capabilities',
        (tester) async {
      final caps = await bluetooth.getPlatformCapabilities();
      expect(caps, isA<PlatformCapabilities>());
      expect(caps.canDiscoverDevices, isA<bool>());
      expect(caps.canGetPairedDevices, isA<bool>());
    });
  });

  group('App UI', () {
    testWidgets('app builds and shows home screen', (tester) async {
      await tester.pumpWidget(const BluetoothExampleApp());
      await tester.pumpAndSettle();

      expect(find.text('Bluetooth Classic'), findsAtLeast(1));
    });

    testWidgets('home screen shows navigation tiles', (tester) async {
      await tester.pumpWidget(const BluetoothExampleApp());
      await tester.pumpAndSettle();

      expect(find.text('Adapter'), findsAtLeast(1));
      expect(find.text('Discovery'), findsAtLeast(1));
      expect(find.text('Paired Devices'), findsAtLeast(1));
      expect(find.text('Server'), findsAtLeast(1));
      expect(find.text('Platform Capabilities'), findsAtLeast(1));
    });

    testWidgets('home screen shows status card', (tester) async {
      await tester.pumpWidget(const BluetoothExampleApp());
      await tester.pumpAndSettle();

      expect(
        find.textContaining(RegExp('supported|Not supported')),
        findsAtLeast(1),
      );
    });

    testWidgets('can navigate to Adapter screen', (tester) async {
      await tester.pumpWidget(const BluetoothExampleApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Adapter').first);
      await tester.pumpAndSettle();

      expect(find.text('Adapter'), findsAtLeast(1));
      expect(
        find.textContaining(RegExp('Enabled|Disabled|Error')),
        findsAtLeast(1),
      );
    });

    testWidgets('can navigate to Platform Capabilities screen',
        (tester) async {
      await tester.pumpWidget(const BluetoothExampleApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Platform Capabilities').first);
      await tester.pumpAndSettle();

      expect(find.text('Platform Capabilities'), findsAtLeast(1));
      expect(find.text('Discover Devices'), findsOneWidget);
      expect(find.text('Get Paired Devices'), findsOneWidget);
      expect(find.text('Create Server'), findsOneWidget);
    });

    testWidgets('can navigate to Paired Devices screen', (tester) async {
      await tester.pumpWidget(const BluetoothExampleApp());
      await tester.pumpAndSettle();

      final tile = find.text('Paired Devices');
      expect(tile, findsAtLeast(1));
      await tester.tap(tile.first);
      await tester.pumpAndSettle();

      expect(
        find.textContaining(RegExp('Paired Devices|Bluetooth Classic')),
        findsAtLeast(1),
      );
    });
  });
}
