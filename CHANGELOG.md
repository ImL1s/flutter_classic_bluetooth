## 0.1.2

### Added
* **Auto-reconnect**: `connectWithReconnect()` returns a `BtcReconnectingConnection`
  that transparently re-establishes the link when it drops, with a configurable
  `BtcReconnectPolicy` (exponential backoff, max attempts, per-attempt timeout).
  Its `input` and `state` streams are stable across reconnects, so you subscribe
  once. New `BtcReconnectState` enum.

### Changed
* Discoverability: lead the package `description`, README title and opening with
  the terms developers actually search (Bluetooth Classic, RFCOMM/SPP, serial,
  ESP32, HC-05) so the package surfaces for those queries.
* Docs: add a **Roadmap** section to the README — a checked list of shipped
  capabilities plus planned items.

## 0.1.1

Reliability and completeness pass across all five platforms, plus API ergonomics.

### Added
* `BtcUuid.spp`, and `connect()` / `startServer()` now default `uuid` to it — the
  common case is just `connect(address: ...)` (HC-05/06, ESP32, Arduino, …).
* `connect()` gains an optional `timeout` (throws `BtcTimeoutException`).
* `BtcConnection.stateStream` emits `disconnecting` → `disconnected` on `finish()`/`close()`.
* `BtcStreamSink` gains `writeString`, `writeBytes`, `addStream` and `allSent`.
* `BtcDiscoveryException` for `discoveryFailed` errors.

### Fixed
* **Android**: marshal method/event-channel work to the main thread; shared atomic
  connection ids; receivers emit an initial snapshot and use the API 34
  exported-receiver flag; no more orphaned permission/activity futures.
* **Windows**: register the per-connection/server/`bond_state` event channels
  (inbound data was dropped); deliver accepted clients; publish an SDP record;
  honor `secure`; surface `WSAStartup` failure; `setDiscoverable` via
  `BluetoothEnableDiscovery`.
* **Linux**: discovery, adapter state/power, discoverability, paired-device listing
  and pairing now run over the **BlueZ D-Bus API** (`org.bluez`) as the primary
  path, so they work for an **unprivileged** user (no root / CAP_NET_RAW).
  Discovery is event-driven via BlueZ signals (BR/EDR-filtered) with live adapter
  on/off; raw HCI is an automatic fallback. Connect/server/data use AF_BLUETOOTH
  RFCOMM, with the channel resolved from the UUID via SDP. Bundled GoogleTest
  bumped to v1.15.2 so the example configures on CMake 4.x.
* **macOS**: device discovery, accepted-client delivery, async connect/write,
  main-thread events, and pairing via `IOBluetoothDevicePair` (unpair via System
  Settings).
* **iOS**: real adapter-state stream via CoreBluetooth; `isEnabled` from the radio
  state with an MFi-accessory fallback.

### Changed
* Capability flags and the documentation tables reflect each platform's real support.
* SDK constraint set to `>=3.3.0 <4.0.0`.

> Note: Android, Windows and Linux are verified on-device. macOS native code is
> reviewed but should be compiled on macOS before production use.

## 0.1.0

* Initial release.
* Unified Dart API for Bluetooth Classic (RFCOMM) communication.
* **Android**: Full support — discovery, pairing, connect, server, discoverability.
* **Windows**: Discovery, pairing, connect, server via Winsock2/AF_BTH.
* **macOS**: Discovery, pairing, connect, server via IOBluetooth.
* **Linux**: Discovery, connect, server via BlueZ/RFCOMM. Pairing requires external tools.
* **iOS**: MFi accessory support via ExternalAccessory framework.
* Platform capabilities API for runtime feature detection.
* Multiple simultaneous RFCOMM connections.
* Stream-based data I/O with `BtcConnection`.
* Typed exception hierarchy (`BtcException` and subtypes).
* Example app with 7 screens demonstrating all features.
