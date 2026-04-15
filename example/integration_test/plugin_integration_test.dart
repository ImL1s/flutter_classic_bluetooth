import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';
import 'package:flutter_classic_bluetooth_example/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ── Plugin API Tests ─────────────────────────────────────────────────

  group('Plugin API — Adapter', () {
    late FlutterClassicBluetooth bluetooth;

    setUp(() {
      bluetooth = FlutterClassicBluetooth();
    });

    testWidgets('singleton instance', (tester) async {
      final a = FlutterClassicBluetooth();
      final b = FlutterClassicBluetooth();
      expect(identical(a, b), isTrue);
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

    testWidgets('enableBluetooth returns bool or throws', (tester) async {
      try {
        final result = await bluetooth.enableBluetooth();
        expect(result, isA<bool>());
      } on BluetoothUnsupportedException {
        // Expected on platforms that don't support this
      } on BluetoothException {
        // BT error is acceptable
      }
    });

    testWidgets('disableBluetooth returns bool or throws', (tester) async {
      try {
        final result = await bluetooth.disableBluetooth();
        expect(result, isA<bool>());
      } on BluetoothUnsupportedException {
        // Expected on platforms that don't support this
      } on BluetoothException {
        // BT error is acceptable
      }
    });
  });

  group('Plugin API — Discovery', () {
    late FlutterClassicBluetooth bluetooth;

    setUp(() {
      bluetooth = FlutterClassicBluetooth();
    });

    testWidgets('isDiscovering returns a bool', (tester) async {
      final result = await bluetooth.isDiscovering();
      expect(result, isA<bool>());
    });

    testWidgets('startDiscovery and stopDiscovery do not throw',
        (tester) async {
      try {
        await bluetooth.startDiscovery();
        // Give it a moment then stop
        await bluetooth.stopDiscovery();
      } on BluetoothUnsupportedException {
        // Unsupported on iOS
      } on BluetoothDisabledException {
        // BT may be off
      } on BluetoothException {
        // Acceptable
      }
    });
  });

  group('Plugin API — Pairing', () {
    late FlutterClassicBluetooth bluetooth;

    setUp(() {
      bluetooth = FlutterClassicBluetooth();
    });

    testWidgets('getPairedDevices returns a list', (tester) async {
      try {
        final devices = await bluetooth.getPairedDevices();
        expect(devices, isA<List<BluetoothDevice>>());
        for (final device in devices) {
          expect(device.address, isNotEmpty);
        }
      } on BluetoothException {
        // BT may be disabled
      }
    });

    testWidgets('bondDevice validates MAC address', (tester) async {
      expect(
        () => bluetooth.bondDevice('invalid'),
        throwsA(isA<BluetoothAddressException>()),
      );
    });

    testWidgets('unbondDevice validates MAC address', (tester) async {
      expect(
        () => bluetooth.unbondDevice('not-a-mac'),
        throwsA(isA<BluetoothAddressException>()),
      );
    });
  });

  group('Plugin API — Connection validation', () {
    late FlutterClassicBluetooth bluetooth;

    setUp(() {
      bluetooth = FlutterClassicBluetooth();
    });

    testWidgets('connect validates MAC address', (tester) async {
      expect(
        () => bluetooth.connect(
          address: 'bad-address',
          uuid: '00001101-0000-1000-8000-00805F9B34FB',
        ),
        throwsA(isA<BluetoothAddressException>()),
      );
    });

    testWidgets('connect validates UUID format', (tester) async {
      expect(
        () => bluetooth.connect(
          address: 'AA:BB:CC:DD:EE:FF',
          uuid: 'not-a-uuid',
        ),
        throwsA(isA<BluetoothUuidException>()),
      );
    });

    testWidgets('startServer validates UUID format', (tester) async {
      expect(
        () => bluetooth.startServer(
          uuid: 'bad-uuid',
          serviceName: 'Test',
        ),
        throwsA(isA<BluetoothUuidException>()),
      );
    });
  });

  group('Plugin API — Capabilities', () {
    late FlutterClassicBluetooth bluetooth;

    setUp(() {
      bluetooth = FlutterClassicBluetooth();
    });

    testWidgets('getPlatformCapabilities returns all fields',
        (tester) async {
      final caps = await bluetooth.getPlatformCapabilities();
      expect(caps, isA<PlatformCapabilities>());
      expect(caps.canEnableBluetooth, isA<bool>());
      expect(caps.canDisableBluetooth, isA<bool>());
      expect(caps.canDiscoverDevices, isA<bool>());
      expect(caps.canGetPairedDevices, isA<bool>());
      expect(caps.canBondDevices, isA<bool>());
      expect(caps.canUnbondDevices, isA<bool>());
      expect(caps.canCreateServer, isA<bool>());
      expect(caps.canSetDiscoverable, isA<bool>());
      expect(caps.supportsMultipleConnections, isA<bool>());
      expect(caps.supportsSecureConnection, isA<bool>());
      expect(caps.supportsInsecureConnection, isA<bool>());
      expect(caps.requiresMfiCertification, isA<bool>());
    });

    testWidgets('platformNote is String or null', (tester) async {
      final caps = await bluetooth.getPlatformCapabilities();
      expect(caps.platformNote, anyOf(isA<String>(), isNull));
    });

    testWidgets('setDiscoverable returns bool or throws', (tester) async {
      try {
        final result = await bluetooth.setDiscoverable(60);
        expect(result, isA<bool>());
      } on BluetoothUnsupportedException {
        // Expected on some platforms
      } on BluetoothException {
        // Acceptable
      }
    });
  });

  // ── App UI Tests — Home Screen ───────────────────────────────────────

  group('App UI — Home Screen', () {
    testWidgets('app builds and shows home screen', (tester) async {
      await tester.pumpWidget(const BluetoothExampleApp());
      await tester.pumpAndSettle();

      expect(find.text('Bluetooth Classic'), findsAtLeast(1));
    });

    testWidgets('shows all 5 navigation tiles', (tester) async {
      await tester.pumpWidget(const BluetoothExampleApp());
      await tester.pumpAndSettle();

      expect(find.text('Adapter'), findsAtLeast(1));
      expect(find.text('Discovery'), findsAtLeast(1));
      expect(find.text('Paired Devices'), findsAtLeast(1));
      expect(find.text('Server'), findsAtLeast(1));
      expect(find.text('Platform Capabilities'), findsAtLeast(1));
    });

    testWidgets('shows tile subtitles', (tester) async {
      await tester.pumpWidget(const BluetoothExampleApp());
      await tester.pumpAndSettle();

      expect(find.text('Adapter info, enable/disable'), findsAtLeast(1));
      expect(find.text('Scan for nearby devices'), findsAtLeast(1));
      expect(find.text('List bonded devices, connect'), findsAtLeast(1));
      expect(find.text('Start RFCOMM server'), findsAtLeast(1));
      expect(find.text('Feature support matrix'), findsAtLeast(1));
    });

    testWidgets('shows hardware support status', (tester) async {
      await tester.pumpWidget(const BluetoothExampleApp());
      await tester.pumpAndSettle();

      expect(
        find.textContaining(RegExp('Hardware supported|Not supported')),
        findsAtLeast(1),
      );
    });

    testWidgets('shows adapter enabled/disabled status', (tester) async {
      await tester.pumpWidget(const BluetoothExampleApp());
      await tester.pumpAndSettle();

      expect(
        find.textContaining(RegExp('Adapter enabled|Adapter disabled')),
        findsAtLeast(1),
      );
    });
  });

  // ── App UI Tests — Adapter Screen ────────────────────────────────────

  group('App UI — Adapter Screen', () {
    testWidgets('navigate and shows status', (tester) async {
      await tester.pumpWidget(const BluetoothExampleApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Adapter').first);
      await tester.pumpAndSettle();

      // AppBar title
      expect(find.text('Adapter'), findsAtLeast(1));
      // Status row
      expect(
        find.textContaining(RegExp('Enabled|Disabled|Error')),
        findsAtLeast(1),
      );
    });

    testWidgets('shows Enable and Disable buttons', (tester) async {
      await tester.pumpWidget(const BluetoothExampleApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Adapter').first);
      await tester.pumpAndSettle();

      expect(find.text('Enable'), findsOneWidget);
      expect(find.text('Disable'), findsOneWidget);
    });

    testWidgets('shows Refresh button', (tester) async {
      await tester.pumpWidget(const BluetoothExampleApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Adapter').first);
      await tester.pumpAndSettle();

      expect(find.text('Refresh'), findsOneWidget);
    });

    testWidgets('shows Name and Address when enabled', (tester) async {
      await tester.pumpWidget(const BluetoothExampleApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Adapter').first);
      await tester.pumpAndSettle();

      // Status label always present
      expect(find.text('Status'), findsOneWidget);

      // If enabled, Name and Address rows should appear
      final enabled = find.text('Enabled');
      if (enabled.evaluate().isNotEmpty) {
        expect(find.text('Name'), findsOneWidget);
        expect(find.text('Address'), findsOneWidget);
      }
    });

    testWidgets('can navigate back to home', (tester) async {
      await tester.pumpWidget(const BluetoothExampleApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Adapter').first);
      await tester.pumpAndSettle();

      // Navigate back
      final backButton = find.byTooltip('Back');
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
      } else {
        await tester.pageBack();
      }
      await tester.pumpAndSettle();

      expect(find.text('Bluetooth Classic'), findsAtLeast(1));
    });
  });

  // ── App UI Tests — Discovery Screen ──────────────────────────────────

  group('App UI — Discovery Screen', () {
    Future<void> navigateToDiscovery(WidgetTester tester) async {
      await tester.pumpWidget(const BluetoothExampleApp());
      await tester.pumpAndSettle();

      // Discovery tile may be disabled if BT is off — try to tap it
      final tile = find.text('Discovery');
      expect(tile, findsAtLeast(1));

      // Check if the ListTile is enabled
      final listTile = find.ancestor(
        of: find.text('Discovery'),
        matching: find.byType(ListTile),
      );
      if (listTile.evaluate().isEmpty) return;

      final widget = tester.widget<ListTile>(listTile.first);
      if (widget.enabled) {
        await tester.tap(tile.first);
        await tester.pumpAndSettle();
      }
    }

    testWidgets('shows empty state with Scan FAB', (tester) async {
      await navigateToDiscovery(tester);

      // If we navigated successfully
      if (find.text('Discovery').evaluate().isNotEmpty &&
          find.text('Scan').evaluate().isNotEmpty) {
        expect(find.text('Scan'), findsOneWidget);
        expect(
          find.textContaining(RegExp('Tap Scan to find devices|Scanning')),
          findsAtLeast(1),
        );
      }
    });

    testWidgets('can tap Scan to start discovery', (tester) async {
      await navigateToDiscovery(tester);

      final scanButton = find.text('Scan');
      if (scanButton.evaluate().isNotEmpty) {
        await tester.tap(scanButton);
        // Pump several frames — native call may take time
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 500));
        }

        // Verify the tap was processed — the FAB should either:
        // 1. Change to "Stop" (discovery started)
        // 2. Still show "Scan" (if blocked by system dialog/permission)
        // 3. Show a SnackBar (error from native side)
        // All outcomes are valid on different platforms.
        final hasFab = find.byType(FloatingActionButton).evaluate().isNotEmpty;
        expect(hasFab, isTrue, reason: 'FAB should always be present');

        // Stop discovery to clean up (if it started)
        final stopButton = find.text('Stop');
        if (stopButton.evaluate().isNotEmpty) {
          await tester.tap(stopButton);
          await tester.pumpAndSettle();
        }
      }
    });
  });

  // ── App UI Tests — Paired Devices Screen ─────────────────────────────

  group('App UI — Paired Devices Screen', () {
    Future<bool> navigateToPaired(WidgetTester tester) async {
      await tester.pumpWidget(const BluetoothExampleApp());
      await tester.pumpAndSettle();

      final tile = find.text('Paired Devices');
      expect(tile, findsAtLeast(1));

      final listTile = find.ancestor(
        of: tile,
        matching: find.byType(ListTile),
      );
      if (listTile.evaluate().isEmpty) return false;

      final widget = tester.widget<ListTile>(listTile.first);
      if (!widget.enabled) return false;

      await tester.tap(tile.first);
      await tester.pumpAndSettle();
      return true;
    }

    testWidgets('shows paired devices or empty message', (tester) async {
      final navigated = await navigateToPaired(tester);
      if (!navigated) return;

      // Should show either device list or empty message
      expect(
        find.textContaining(RegExp('Paired Devices|No paired devices|Error')),
        findsAtLeast(1),
      );
    });

    testWidgets('shows refresh button in AppBar', (tester) async {
      final navigated = await navigateToPaired(tester);
      if (!navigated) return;

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('paired devices show address', (tester) async {
      final navigated = await navigateToPaired(tester);
      if (!navigated) return;

      // If there are paired devices, they should show MAC addresses
      final macPattern = find.textContaining(
        RegExp(r'[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}'),
      );
      final emptyMsg = find.text('No paired devices');

      // Either we have devices with MACs or the empty message
      expect(
        macPattern.evaluate().isNotEmpty || emptyMsg.evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('can navigate back to home', (tester) async {
      final navigated = await navigateToPaired(tester);
      if (!navigated) return;

      final backButton = find.byTooltip('Back');
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
      } else {
        await tester.pageBack();
      }
      await tester.pumpAndSettle();

      expect(find.text('Bluetooth Classic'), findsAtLeast(1));
    });
  });

  // ── App UI Tests — Platform Capabilities Screen ──────────────────────

  group('App UI — Capabilities Screen', () {
    Future<void> navigateToCaps(WidgetTester tester) async {
      await tester.pumpWidget(const BluetoothExampleApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Platform Capabilities').first);
      await tester.pumpAndSettle();
    }

    testWidgets('shows all 12 capability labels', (tester) async {
      await navigateToCaps(tester);

      expect(find.text('Platform Capabilities'), findsAtLeast(1));
      expect(find.text('Enable Bluetooth'), findsOneWidget);
      expect(find.text('Disable Bluetooth'), findsOneWidget);
      expect(find.text('Discover Devices'), findsOneWidget);
      expect(find.text('Get Paired Devices'), findsOneWidget);
      expect(find.text('Bond Devices'), findsOneWidget);
      expect(find.text('Unbond Devices'), findsOneWidget);
      expect(find.text('Create Server'), findsOneWidget);
      expect(find.text('Set Discoverable'), findsOneWidget);
      expect(find.text('Multiple Connections'), findsOneWidget);
      expect(find.text('Secure Connection'), findsOneWidget);
      expect(find.text('Insecure Connection'), findsOneWidget);
      expect(find.text('Requires MFi'), findsOneWidget);
    });

    testWidgets('shows check or cancel icons for each capability',
        (tester) async {
      await navigateToCaps(tester);

      // Should have a mix of check_circle and cancel icons (12 total)
      final checks = find.byIcon(Icons.check_circle);
      final cancels = find.byIcon(Icons.cancel);

      final total =
          checks.evaluate().length + cancels.evaluate().length;
      expect(total, equals(12));
    });

    testWidgets('shows platform note card', (tester) async {
      await navigateToCaps(tester);

      // Platform note should be present (all our platforms have one)
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('can navigate back to home', (tester) async {
      await navigateToCaps(tester);

      final backButton = find.byTooltip('Back');
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
      } else {
        await tester.pageBack();
      }
      await tester.pumpAndSettle();

      expect(find.text('Bluetooth Classic'), findsAtLeast(1));
    });
  });

  // ── App UI Tests — Server Screen ─────────────────────────────────────

  group('App UI — Server Screen', () {
    Future<bool> navigateToServer(WidgetTester tester) async {
      await tester.pumpWidget(const BluetoothExampleApp());
      await tester.pumpAndSettle();

      final tile = find.text('Server');
      expect(tile, findsAtLeast(1));

      final listTile = find.ancestor(
        of: tile,
        matching: find.byType(ListTile),
      );
      if (listTile.evaluate().isEmpty) return false;

      final widget = tester.widget<ListTile>(listTile.first);
      if (!widget.enabled) return false;

      await tester.tap(tile.first);
      await tester.pumpAndSettle();
      return true;
    }

    testWidgets('shows empty state with Start FAB', (tester) async {
      final navigated = await navigateToServer(tester);
      if (!navigated) return;

      expect(find.text('RFCOMM Server'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
      expect(find.text('Tap Start to begin listening'), findsOneWidget);
    });

    testWidgets('can navigate back to home', (tester) async {
      final navigated = await navigateToServer(tester);
      if (!navigated) return;

      final backButton = find.byTooltip('Back');
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
      } else {
        await tester.pageBack();
      }
      await tester.pumpAndSettle();

      expect(find.text('Bluetooth Classic'), findsAtLeast(1));
    });
  });

  // ── App UI Tests — Navigation Flow ───────────────────────────────────

  group('App UI — Navigation Flow', () {
    testWidgets('navigate Adapter → back → Capabilities → back',
        (tester) async {
      await tester.pumpWidget(const BluetoothExampleApp());
      await tester.pumpAndSettle();

      // Go to Adapter
      await tester.tap(find.text('Adapter').first);
      await tester.pumpAndSettle();
      expect(find.text('Enable'), findsOneWidget);

      // Back to home
      final back1 = find.byTooltip('Back');
      if (back1.evaluate().isNotEmpty) {
        await tester.tap(back1);
      } else {
        await tester.pageBack();
      }
      await tester.pumpAndSettle();
      expect(find.text('Bluetooth Classic'), findsAtLeast(1));

      // Go to Capabilities
      await tester.tap(find.text('Platform Capabilities').first);
      await tester.pumpAndSettle();
      expect(find.text('Discover Devices'), findsOneWidget);

      // Back to home
      final back2 = find.byTooltip('Back');
      if (back2.evaluate().isNotEmpty) {
        await tester.tap(back2);
      } else {
        await tester.pageBack();
      }
      await tester.pumpAndSettle();
      expect(find.text('Bluetooth Classic'), findsAtLeast(1));
    });
  });
}
