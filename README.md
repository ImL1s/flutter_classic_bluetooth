<p align="center">
  <img src="https://raw.githubusercontent.com/Masum-MSNR/flutter_classic_bluetooth/main/images/logo.png" alt="Flutter Classic Bluetooth" width="120"/>
</p>

<p align="center">
  <a href="https://pub.dev/packages/flutter_classic_bluetooth"><img src="https://img.shields.io/pub/v/flutter_classic_bluetooth.svg" alt="pub package"></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT"></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.22+-02569B?logo=flutter" alt="Flutter"></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.3+-0175C2?logo=dart" alt="Dart"></a>
</p>

<p align="center">
A Flutter plugin for <strong>Bluetooth Classic (RFCOMM)</strong> communication.<br/>
Discover, pair, connect, and exchange data across Android, iOS (MFi), Windows, macOS, and Linux.
</p>

## Features

- 🔍 **Device Discovery** — Scan for nearby Bluetooth Classic devices
- 🔗 **Pair / Unpair** — Bond and unbond devices programmatically
- 📡 **RFCOMM Connect** — Establish serial connections with data streaming
- 🖥️ **Server Mode** — Accept incoming RFCOMM connections
- 🔄 **Multiple Connections** — Manage several simultaneous connections
- 📊 **Stream-Based I/O** — Read/write with Dart streams and ordered sinks
- 🧩 **Platform Capabilities** — Query feature support at runtime per platform
- ⚡ **Typed Exceptions** — Structured error hierarchy for clean error handling

## Platform Support

| Feature | Android | Windows | macOS | Linux | iOS |
|---------|---------|---------|-------|-------|-----|
| Adapter state stream | ✅ | ✅ | ✅ | ✅ | ✅ |
| Discover devices | ✅ | ✅ | ✅ | ✅ | ❌ |
| Get paired devices | ✅ | ✅ | ✅ | ❌³ | ✅¹ |
| Pair / Unpair | ✅ | ✅ | ❌² | ❌² | ❌ |
| Connect (RFCOMM) | ✅ | ✅ | ✅ | ✅ | ✅¹ |
| Server mode | ✅ | ✅ | ✅ | ✅ | ❌ |
| Enable / Disable | ✅ | ❌ | ❌ | ❌ | ❌ |
| Set discoverable | ✅ | ❌ | ❌ | ✅ | ❌ |

¹ iOS uses the ExternalAccessory framework — only MFi-certified accessories are supported.<br/>
² macOS / Linux pairing is done through the OS (System Settings / `bluetoothctl`).<br/>
³ Linux paired-device listing requires the BlueZ D-Bus API.

## Installation

```yaml
dependencies:
  flutter_classic_bluetooth: ^0.1.0
```

## Quick Start

```dart
import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';

final bluetooth = FlutterClassicBluetooth();
```

### Check Support & Capabilities

```dart
final supported = await bluetooth.isSupported();
final enabled = await bluetooth.isEnabled();
final caps = await bluetooth.getPlatformCapabilities();

if (caps.canDiscoverDevices) {
  await bluetooth.startDiscovery();
}
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

## API Overview

### Core Classes

| Class | Purpose |
|-------|---------|
| `FlutterClassicBluetooth` | Main entry point — adapter, discovery, pairing, connection, server |
| `BtcDevice` | Represents a remote Bluetooth device |
| `BtcConnection` | Active RFCOMM connection with input/output streams |
| `BtcServerSocket` | Listens for incoming RFCOMM connections |
| `BtcStreamSink` | Ordered write sink for a connection |
| `BtcPlatformCapabilities` | Platform feature support matrix |

### Enums

| Enum | Purpose |
|------|---------|
| `BtcAdapterState` | Adapter on/off/transitioning states |
| `BtcBondState` | Device pairing state |
| `BtcDeviceType` | Classic, LE, or Dual-mode |
| `BtcConnectionState` | Connection lifecycle states |

### Exceptions

All exceptions extend `BtcException`:

| Exception | When |
|-----------|------|
| `BtcUnsupportedException` | Feature not available on platform |
| `BtcPermissionException` | Permission denied |
| `BtcDisabledException` | Adapter is off |
| `BtcConnectionException` | Connection failed |
| `BtcWriteException` | Write failed |
| `BtcTimeoutException` | Operation timed out |
| `BtcAddressException` | Invalid MAC address |
| `BtcUuidException` | Invalid UUID |

## Error Handling

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

## Examples

Check out the [example](example/) directory for a complete demo app, with screens for adapter control, device discovery, paired devices, RFCOMM client/server, and the platform-capabilities matrix.

## License

MIT License — see [LICENSE](LICENSE) for details.

---

<p align="center">
  Made with ❤️ by <a href="https://github.com/Masum-MSNR">Masum</a>
</p>

