# flutter_classic_bluetooth

A Flutter plugin for **Bluetooth Classic (RFCOMM)** communication across Android, iOS (MFi), Windows, macOS, and Linux.

## Features

- Discover nearby Bluetooth Classic devices
- Pair/unpair devices
- Connect and exchange data over RFCOMM
- Server mode — accept incoming connections
- Multiple simultaneous connections
- Stream-based data I/O
- Platform capabilities API for runtime feature detection

## Platform Support

| Feature | Android | Windows | macOS | Linux | iOS |
|---------|---------|---------|-------|-------|-----|
| Discover devices | ✅ | ✅ | ✅ | ✅ | ❌ |
| Get paired devices | ✅ | ✅ | ✅ | ✅ | ✅¹ |
| Pair / Unpair | ✅ | ✅ | ✅ | ❌² | ❌ |
| Connect (RFCOMM) | ✅ | ✅ | ✅ | ✅ | ✅¹ |
| Server mode | ✅ | ✅ | ✅ | ✅ | ❌ |
| Enable/Disable BT | ✅ | ❌ | ❌ | ❌ | ❌ |
| Set discoverable | ✅ | ❌ | ❌ | ✅ | ❌ |

¹ iOS uses the ExternalAccessory framework — only MFi-certified accessories are supported.
² Linux pairing requires BlueZ D-Bus agent (use `bluetoothctl` or system settings).

## Getting Started

```dart
import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';
```

### Check Support & Capabilities

```dart
final bluetooth = FlutterClassicBluetooth();

final supported = await bluetooth.isSupported();
final enabled = await bluetooth.isEnabled();
final caps = await bluetooth.getPlatformCapabilities();
```

### Discover Devices

```dart
bluetooth.discoveryResults.listen((device) {
  print('Found: ${device.displayName} (${device.address})');
});

await bluetooth.startDiscovery();
// ...
await bluetooth.stopDiscovery();
```

### Connect & Communicate

```dart
final connection = await bluetooth.connect(
  address: 'AA:BB:CC:DD:EE:FF',
  uuid: '00001101-0000-1000-8000-00805F9B34FB',
);

// Receive data
connection.input.listen((data) {
  print('Received ${data.length} bytes');
});

// Send data
await connection.output.add(Uint8List.fromList([0x01, 0x02, 0x03]));

// Disconnect (waits for pending writes)
await connection.finish();
```

### Server Mode

```dart
final server = await bluetooth.startServer(
  uuid: '00001101-0000-1000-8000-00805F9B34FB',
  serviceName: 'MyService',
);

server.connections.listen((connection) {
  print('Client connected: ${connection.address}');
  connection.input.listen((data) => print('Data: $data'));
});
```

### Paired Devices

```dart
final devices = await bluetooth.getPairedDevices();
for (final device in devices) {
  print('${device.displayName} — ${device.address}');
}
```

## Android Setup

Add Bluetooth permissions to `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

## iOS Setup

Add to `Info.plist`:

```xml
<key>UISupportedExternalAccessoryProtocols</key>
<array>
  <string>com.example.protocol</string>
</array>
```

> **Note:** iOS only supports MFi-certified Bluetooth accessories via the ExternalAccessory framework. The `uuid` parameter in `connect()` is used as the MFi protocol string on iOS.

## Error Handling

All errors are typed exceptions extending `BtcException`:

```dart
try {
  await bluetooth.connect(address: addr, uuid: uuid);
} on BtcUnsupportedException catch (e) {
  print('${e.feature} not supported on ${e.platform}');
} on BtcDisabledException {
  print('Turn on Bluetooth first');
} on BtcConnectionException catch (e) {
  print('Connection failed: ${e.message}');
}
```

## License

See [LICENSE](LICENSE) for details.

