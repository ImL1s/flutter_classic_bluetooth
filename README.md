<p align="center">
  <a href="https://pub.dev/packages/flutter_classic_bluetooth"><img src="https://img.shields.io/pub/v/flutter_classic_bluetooth.svg" alt="pub version"></a>
  <a href="https://pub.dev/packages/flutter_classic_bluetooth/score"><img src="https://img.shields.io/pub/points/flutter_classic_bluetooth" alt="pub points"></a>
  <a href="https://pub.dev/packages/flutter_classic_bluetooth"><img src="https://img.shields.io/pub/likes/flutter_classic_bluetooth" alt="pub likes"></a>
  <a href="https://github.com/almasumdev/flutter_classic_bluetooth/stargazers"><img src="https://badgen.net/github/stars/almasumdev/flutter_classic_bluetooth?icon=github" alt="GitHub stars"></a>
  <a href="https://github.com/almasumdev/flutter_classic_bluetooth/network/members"><img src="https://badgen.net/github/forks/almasumdev/flutter_classic_bluetooth?icon=github" alt="GitHub forks"></a>
  <a href="https://github.com/almasumdev/flutter_classic_bluetooth/issues"><img src="https://badgen.net/github/open-issues/almasumdev/flutter_classic_bluetooth?icon=github" alt="GitHub issues"></a>
  <a href="https://github.com/almasumdev/flutter_classic_bluetooth/actions/workflows/ci.yml"><img src="https://github.com/almasumdev/flutter_classic_bluetooth/actions/workflows/ci.yml/badge.svg" alt="CI status"></a>
  <a href="https://github.com/almasumdev/flutter_classic_bluetooth/commits/main"><img src="https://badgen.net/github/last-commit/almasumdev/flutter_classic_bluetooth?icon=github" alt="Last commit"></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT"></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.3+-0175C2?logo=dart" alt="Dart"></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.3+-02569B?logo=flutter" alt="Flutter"></a>
</p>

# Bluetooth Classic Serial (RFCOMM/SPP) Plugin for Flutter

**flutter_classic_bluetooth** is a Flutter plugin for **Bluetooth Classic
serial communication over RFCOMM (the Serial Port Profile, SPP)**. It lets you
**discover, pair, connect to, and exchange data with** Bluetooth Classic devices
— **ESP32**, **ESP8266**, **Arduino** boards, **HC-05** / **HC-06** modules,
barcode scanners, thermal printers, OBD-II adapters, and other serial / UART
peripherals — from a single Dart API on **Android, Windows, macOS, Linux, and
iOS (MFi)**. Connections are exposed as Dart streams, so reading and writing
bytes feels like any other `Stream`/`Sink`.

> ⭐ **Find this useful?** [Star it on GitHub](https://github.com/almasumdev/flutter_classic_bluetooth)
> and 👍 [like it on pub.dev](https://pub.dev/packages/flutter_classic_bluetooth) —
> it helps other Flutter developers find a maintained Bluetooth Classic plugin.

## Overview

flutter_classic_bluetooth speaks **RFCOMM/SPP**, the classic Bluetooth serial
transport — not Bluetooth Low Energy (BLE). It wraps each platform's native
stack (Android `BluetoothSocket`, Windows Winsock2 `AF_BTH`, Linux BlueZ
RFCOMM sockets, macOS IOBluetooth, iOS ExternalAccessory) behind one consistent
Dart interface. You can act as a **client** (connect out to a device) or as a
**server** (advertise an SDP service and accept incoming connections), run
several connections at once, and observe adapter, discovery, and bond state
through broadcast streams.

**What you can do with it:**

- Discover nearby devices and list paired/bonded devices.
- Connect over RFCOMM by MAC address + service UUID, then read and write a byte stream.
- Run an RFCOMM server that accepts incoming client connections.
- Pair/unpair devices, toggle the adapter, and make the device discoverable (where the platform allows).
- Query per-platform capabilities at runtime so your UI only offers what works.

## Table of contents

- [Key features](#key-features)
- [Platform support](#platform-support)
- [Roadmap](#roadmap)
- [Example](#example)
- [Other useful links](#other-useful-links)
- [Installation](#installation)
- [Platform setup](#platform-setup)
- [Getting started](#getting-started)
  - [Initialize and check support](#initialize-and-check-support)
  - [Discover nearby devices](#discover-nearby-devices)
  - [List paired devices](#list-paired-devices)
  - [Connect to a device](#connect-to-a-device)
  - [Receive data](#receive-data)
  - [Send data](#send-data)
  - [Watch the connection state](#watch-the-connection-state)
  - [Disconnect and dispose](#disconnect-and-dispose)
  - [Reconnect automatically](#reconnect-automatically)
  - [Run an RFCOMM server](#run-an-rfcomm-server)
  - [Pair and unpair](#pair-and-unpair)
  - [Adapter state and control](#adapter-state-and-control)
  - [Handle errors](#handle-errors)
- [FAQ](#faq)
- [Support and feedback](#support-and-feedback)
- [About](#about)
  - [Contributors](#contributors)

## Key features

A complete Bluetooth Classic (RFCOMM/SPP) client + server toolkit behind one
Dart API. Expand a group for details:

<details>
<summary><b>📡 Connectivity</b></summary>

- RFCOMM/SPP **client** — connect by address + service UUID, secure or insecure
- RFCOMM **server** — advertise an SDP service and accept incoming clients
- **Multiple simultaneous** connections, each with its own id
- Optional **connection timeout**
- Optional **auto-reconnect** with exponential backoff (`connectWithReconnect`)

</details>

<details>
<summary><b>🔍 Discovery & pairing</b></summary>

- Device **discovery** with results and start/stop state streams
- **Paired/bonded** device listing
- **Bond / unbond** devices and observe bond-state changes
- **Make discoverable** (where supported)

</details>

<details>
<summary><b>🔀 Streamed I/O</b></summary>

- Incoming bytes as a Dart `Stream<Uint8List>`
- Ordered write sink — `add`, `writeBytes`, `writeString`, `addStream`, `allSent`
- Connection-state stream (`connecting` → `connected` → `disconnecting` → `disconnected`)

</details>

<details>
<summary><b>🧩 Adapter & capabilities</b></summary>

- Adapter **state stream**, name, and address
- **Enable/disable** the adapter (Android)
- Runtime **platform-capability** matrix so the UI adapts per platform

</details>

<details>
<summary><b>🛡️ Reliability</b></summary>

- Typed exception hierarchy — `BtcException` + subtypes
- Main-thread-safe event delivery on every platform
- Honest per-platform capability reporting (no dead code paths)

</details>

## Platform support

Bluetooth Classic capabilities differ by OS, so the plugin reports what each one
can actually do (also queryable at runtime via `getPlatformCapabilities()`):

| Feature | Android | Windows | macOS | Linux | iOS |
|---------|---------|---------|-------|-------|-----|
| Adapter state stream | ✅ | ✅ | ✅ | ✅ | ✅ |
| Discover devices | ✅ | ✅ | ✅ | ✅ | ❌ |
| Get paired devices | ✅ | ✅ | ✅ | ✅ | ✅¹ |
| Pair (bond) | ✅ | ✅ | ✅² | ✅³ | ❌ |
| Unpair (unbond) | ✅ | ✅ | ❌⁴ | ✅³ | ❌ |
| Connect (RFCOMM) | ✅ | ✅ | ✅ | ✅ | ✅¹ |
| Server mode | ✅ | ✅ | ✅ | ✅ | ❌ |
| Enable / Disable | ✅ | ❌ | ❌ | ✅³ | ❌ |
| Set discoverable | ✅ | ✅ | ❌ | ✅ | ❌ |

¹ iOS uses the ExternalAccessory framework — only **MFi-certified** accessories are supported, and the `uuid` argument is treated as the MFi protocol string.<br/>
² macOS pairs via `IOBluetoothDevicePair` and may show a system pairing prompt.<br/>
³ Linux uses the BlueZ D-Bus API (`org.bluez`); pairing a device that needs a PIN/passkey requires a system pairing agent.<br/>
⁴ macOS has no public API to remove an existing pairing — unpair via System Settings.

## Roadmap

What's shipped and what's next. Completed items are checked; the rest is on the
list — [contributions](#support-and-feedback) welcome.

**Shipped**

- [x] RFCOMM/SPP **client** — connect by address + UUID, secure/insecure, optional timeout
- [x] RFCOMM **server** — advertise an SDP service and accept incoming clients
- [x] **Multiple simultaneous** connections, each with its own id
- [x] Device **discovery** with results and start/stop state streams
- [x] **Paired/bonded** device listing
- [x] **Pair / unpair** with a bond-state stream
- [x] Adapter **state stream**, **enable/disable**, and **set discoverable**
- [x] Streamed byte I/O with an ordered write sink (`writeString` / `writeBytes` / `addStream`)
- [x] **Connection-state** lifecycle stream
- [x] Runtime **platform-capability** matrix
- [x] Typed **exception hierarchy** (`BtcException` + subtypes)
- [x] `BtcUuid.spp` default — `connect(address: ...)` just works for serial devices
- [x] Optional **auto-reconnect** with exponential backoff (`connectWithReconnect`)
- [x] **Five platforms** — Android, Windows, macOS, Linux, iOS (MFi)
- [x] Linux via **BlueZ D-Bus** — discovery, adapter and pairing work without root

**Planned**

- [ ] Live RSSI updates on an active connection
- [ ] Linux: built-in pairing agent for PIN/passkey devices
- [ ] macOS: programmatic unpair (pending a public Apple API)
- [ ] Expanded on-device integration tests

**Out of scope** — use a dedicated package instead: Bluetooth Low Energy (BLE),
and Web (Bluetooth Classic is not available in browsers).

## Example

A complete, runnable demo app lives in the
[`example/`](https://github.com/almasumdev/flutter_classic_bluetooth/tree/main/example)
directory, with screens for adapter control, device discovery, paired devices,
RFCOMM client/server, and the platform-capabilities matrix. Clone the repository
and run it, or copy any snippet from [Getting started](#getting-started) below.

## Other useful links

- [API reference](https://pub.dev/documentation/flutter_classic_bluetooth/latest/)
- [Source code on GitHub](https://github.com/almasumdev/flutter_classic_bluetooth)
- [Changelog](https://github.com/almasumdev/flutter_classic_bluetooth/blob/main/CHANGELOG.md)
- [Issue tracker](https://github.com/almasumdev/flutter_classic_bluetooth/issues)

## Installation

```bash
flutter pub add flutter_classic_bluetooth
```

Then import it:

```dart
import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';
```

## Platform setup

**Android** — add the Bluetooth permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Android 11 (API 30) and below -->
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" android:maxSdkVersion="30" />
<!-- Android 12 (API 31) and above -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />
```

**iOS** — declare the MFi protocol(s) and a usage string in `ios/Runner/Info.plist`:

```xml
<key>UISupportedExternalAccessoryProtocols</key>
<array>
  <string>com.example.spp</string>
</array>
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app communicates with Bluetooth accessories.</string>
```

**macOS** — add the Bluetooth entitlement to `macos/Runner/*.entitlements` and a
usage string to `Info.plist`:

```xml
<key>com.apple.security.device.bluetooth</key>
<true/>
```

**Linux** — install the GTK and BlueZ development packages the native plugin
builds against (Debian/Ubuntu shown; the build fails with a `gtk+-3.0` or
`bluetooth/bluetooth.h` CMake error if they're missing):

```bash
sudo apt-get install -y libgtk-3-dev libbluetooth-dev ninja-build cmake pkg-config clang
```

On Fedora use `gtk3-devel bluez-libs-devel ninja-build cmake clang`; on Arch,
`gtk3 bluez-libs ninja cmake clang`.

## Getting started

### Initialize and check support

```dart
final bluetooth = FlutterClassicBluetooth();

final supported = await bluetooth.isSupported();
final enabled = await bluetooth.isEnabled();
final caps = await bluetooth.getPlatformCapabilities();

if (caps.canDiscoverDevices) {
  // safe to call startDiscovery() on this platform
}
```

### Discover nearby devices

```dart
final sub = bluetooth.discoveryResults.listen((device) {
  print('Found: ${device.displayName} (${device.address})');
});

await bluetooth.startDiscovery();
// ...later
await bluetooth.stopDiscovery();
await sub.cancel();
```

### List paired devices

```dart
final devices = await bluetooth.getPairedDevices();
for (final device in devices) {
  print('${device.displayName} — ${device.address} [${device.bondState.name}]');
}
```

### Connect to a device

```dart
// SPP is the default — for HC-05/06, ESP32, Arduino, etc. this is all you need:
final connection = await bluetooth.connect(address: 'AA:BB:CC:DD:EE:FF');
print('Connected: id=${connection.id}');

// Override the UUID and tune the attempt only when you need to:
final custom = await bluetooth.connect(
  address: 'AA:BB:CC:DD:EE:FF',
  uuid: BtcUuid.spp, // or any service UUID string
  secure: true,
  timeout: const Duration(seconds: 15), // optional
);
```

### Receive data

```dart
connection.input.listen(
  (Uint8List data) => print('Received ${data.length} bytes: $data'),
  onDone: () => print('Remote closed the connection'),
);
```

### Send data

```dart
// Raw bytes
await connection.output.add(Uint8List.fromList([0x01, 0x02, 0x03]));

// Convenience helpers
await connection.output.writeBytes([0x04, 0x05]);
await connection.output.writeString('AT+RESET\r\n');

// Wait until everything queued so far has been written
await connection.output.allSent;
```

### Watch the connection state

```dart
connection.stateStream.listen((state) {
  print('State: ${state.name}'); // connected, disconnecting, disconnected, ...
});

print(connection.isConnected); // true while connected
```

### Disconnect and dispose

```dart
await connection.finish(); // flush pending writes, then disconnect
// or: await connection.close(); // disconnect immediately

connection.dispose(); // always release resources when done
```

### Reconnect automatically

For long-lived links to a flaky device, `connectWithReconnect` keeps the
connection alive across drops. Its `input` and `state` streams are **stable** —
subscribe once and keep receiving data as the underlying connection is replaced.

```dart
final link = bluetooth.connectWithReconnect(
  address: 'AA:BB:CC:DD:EE:FF',
  policy: const BtcReconnectPolicy(
    maxAttempts: null, // retry forever (default)
    initialBackoff: Duration(seconds: 1),
    maxBackoff: Duration(seconds: 30),
  ),
);

link.state.listen((s) => print('Link: ${s.name}')); // connecting/connected/reconnecting/…
link.input.listen((bytes) => print('RX ${bytes.length} bytes'));

if (link.isConnected) await link.sendString('PING\r\n');

// ...when done
await link.close(); // stop reconnecting and release everything
```

### Run an RFCOMM server

```dart
final server = await bluetooth.startServer(
  serviceName: 'MyService',
  uuid: BtcUuid.spp, // optional — SPP is the default
  secure: true,
);

server.connections.listen((client) {
  print('Client connected: ${client.address}');
  client.input.listen((data) => client.output.writeString('echo: '));
});

// ...later
await server.close();
```

### Pair and unpair

```dart
if (caps.canBondDevices) {
  final ok = await bluetooth.bondDevice('AA:BB:CC:DD:EE:FF');
  print('Bonded: $ok');
}

bluetooth.bondState('AA:BB:CC:DD:EE:FF').listen((state) {
  print('Bond state: ${state.name}');
});

await bluetooth.unbondDevice('AA:BB:CC:DD:EE:FF');
```

### Adapter state and control

```dart
bluetooth.adapterState.listen((state) {
  print('Adapter: ${state.name}'); // on, off, turningOn, ...
});

if (caps.canEnableBluetooth) {
  await bluetooth.enableBluetooth(); // Android: shows the system dialog
}

if (caps.canSetDiscoverable) {
  await bluetooth.setDiscoverable(120); // seconds
}
```

### Handle errors

```dart
try {
  await bluetooth.connect(address: addr, uuid: uuid);
} on BtcUnsupportedException catch (e) {
  print('${e.feature} not supported on ${e.platform}');
} on BtcDisabledException {
  print('Turn on Bluetooth first');
} on BtcTimeoutException {
  print('Connection timed out');
} on BtcConnectionException catch (e) {
  print('Connection failed: ${e.message}');
} on BtcException catch (e) {
  print('Bluetooth error: ${e.message}');
}
```

Every failure throws a typed `BtcException` (or a subtype): `BtcUnsupportedException`,
`BtcPermissionException`, `BtcDisabledException`, `BtcConnectionException`,
`BtcWriteException`, `BtcDiscoveryException`, `BtcTimeoutException`,
`BtcAddressException`, and `BtcUuidException`.

## FAQ

**Is this Bluetooth Classic or Bluetooth Low Energy (BLE)?**
Bluetooth **Classic** — RFCOMM/SPP serial communication. For BLE, use a
BLE-specific package; this plugin targets classic serial peripherals like
ESP32, HC-05/HC-06, printers, and scanners.

**Does it work with ESP32, ESP8266, Arduino, and HC-05/HC-06 modules?**
Yes. Any device that exposes a Bluetooth Classic **RFCOMM/SPP serial** profile
works: an **ESP32** using `BluetoothSerial`, an **Arduino** or **ESP8266** wired
to an **HC-05**/**HC-06** module, and other UART-over-Bluetooth peripherals
(thermal printers, barcode scanners, OBD-II adapters). Pair the device, then
just `connect(address: ...)` — the SPP UUID (`BtcUuid.spp`) is used by default.

**Which platforms are supported?**
Android, Windows, macOS, and Linux for full client/server RFCOMM; iOS supports
only **MFi-certified** accessories via the ExternalAccessory framework (no
discovery or server mode). See [Platform support](#platform-support).

**Why does iOS behave differently?**
Apple restricts general Bluetooth Classic access to MFi-certified accessories.
On iOS the `uuid` you pass to `connect()` is treated as the MFi protocol string,
and discovery/pairing/server features are unavailable by platform design.

**Can I have several connections open at once?**
Yes. Each `connect()` (and each accepted server client) returns an independent
`BtcConnection` with its own input/output streams.

**How do I know if a feature works on the current device?**
Call `getPlatformCapabilities()` and check the matching flag (e.g.
`canDiscoverDevices`, `canCreateServer`) before invoking it — the plugin reports
capabilities honestly per platform.

**How does pairing work on macOS and Linux?**
On macOS, `bondDevice` pairs via `IOBluetoothDevicePair` (which may show a system
prompt for PIN/passkey devices); removing a pairing has no public API, so unpair
through System Settings. On Linux, `bondDevice`/`unbondDevice` use the BlueZ
D-Bus API directly; devices that require a PIN or passkey additionally need a
system pairing agent (e.g. a running desktop Bluetooth applet).

## Support and feedback

- Found a bug or want a feature? Open an issue on the
  [issue tracker](https://github.com/almasumdev/flutter_classic_bluetooth/issues).
- Questions and ideas are welcome via
  [GitHub Discussions](https://github.com/almasumdev/flutter_classic_bluetooth/discussions).
- Pull requests are welcome — see the repository for contribution guidelines.

## About

flutter_classic_bluetooth is an open-source, MIT-licensed Flutter plugin for
Bluetooth Classic (RFCOMM/SPP) serial communication across Android, Windows,
macOS, Linux, and iOS (MFi), exposing native Bluetooth stacks through one
stream-based Dart API.

flutter_classic_bluetooth is created and owned by **Nurullah Al Masum**.

### Contributors

flutter_classic_bluetooth grows with its community — every contributor is listed here:

<a href="https://github.com/almasumdev/flutter_classic_bluetooth/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=almasumdev/flutter_classic_bluetooth" alt="flutter_classic_bluetooth contributors"/>
</a>

Want to help? Pull requests are welcome — see [Support and feedback](#support-and-feedback).
