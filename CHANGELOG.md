## 0.1.1

Reliability and completeness pass across all five platforms.

### Fixed
* **Android**: `connect()` and every event stream now marshal `MethodChannel.Result`,
  `EventSink` and channel registration to the main thread (modern Flutter threw
  *"Methods marked with @UiThread must be executed on the main thread"*). Client and
  server connection ids share one atomic source. Adapter/bond/discovery receivers
  emit an initial snapshot and use the Android 14 (API 34) exported-receiver flag.
  Re-entrant permission/activity requests no longer orphan the Dart future.
* **Windows**: register the per-connection `connection/{id}`, `connection_state/{id}`,
  `server/{id}` and `bond_state` event channels (inbound data was silently dropped);
  deliver server-accepted clients; publish an SDP record; honor the `secure` flag;
  crash-safe id extraction; consistent device-map keys; surface `WSAStartup` failure;
  implement `setDiscoverable` via `BluetoothEnableDiscovery` (with a duration timer).
* **Linux**: wire all event channels (discovery results/state, connection data,
  connection state, server-accepted clients, adapter and bond snapshots) on the GLib
  main loop; resolve the RFCOMM channel from the service UUID via SDP; honor `secure`
  (RFCOMM link mode) and `setDiscoverable` duration; atomic socket shutdown; consistent
  device-map keys. Add a BlueZ **D-Bus** layer (`org.bluez`) for adapter enable/disable,
  paired-device listing, and pairing/unpairing. Bump the bundled GoogleTest to
  v1.15.2 so the example configures on CMake 4.x (older releases declared a
  `cmake_minimum_required` below 3.5, which CMake 4 rejects).
* **macOS**: implement device discovery (inquiry delegate + channels), deliver
  server-accepted clients via channel-open notifications, async (non-blocking)
  connect/write, main-thread event delivery, and programmatic pairing via
  `IOBluetoothDevicePair` (unpairing has no public API — use System Settings).
* **iOS**: real adapter-state stream via CoreBluetooth; `isEnabled` uses the radio
  state with an MFi-accessory fallback.

### Added
* `BtcUuid.spp` constant for the Serial Port Profile UUID, and `connect()` /
  `startServer()` now default `uuid` to it — so the common case is just
  `connect(address: ...)` (HC-05/06, ESP32, Arduino, etc.).
* **Linux**: discovery, adapter state/power, discoverability, paired-device
  listing and pairing now run over the **BlueZ D-Bus API** (`org.bluez`) as the
  primary path, so they work for an **unprivileged** desktop user (no root /
  CAP_NET_RAW). Device discovery is event-driven via BlueZ `InterfacesAdded` /
  `PropertiesChanged` signals (filtered to BR/EDR), and adapter on/off changes
  now stream live. Raw HCI remains an automatic fallback when no system bus is
  present. (Connect, server and data I/O continue to use AF_BLUETOOTH RFCOMM.)
* `connect()` gains an optional `timeout` (throws `BtcTimeoutException`).
* `BtcConnection.stateStream` emits `disconnecting` → `disconnected` on `finish()`/`close()`.
* `BtcStreamSink` gains `writeString`, `writeBytes`, `addStream` and `allSent`.
* `BtcDiscoveryException` for `discoveryFailed` errors.

### Changed
* Capability flags and the documentation tables now reflect each platform's real
  support (notably: macOS/Linux pairing is via the OS; Linux paired-device listing
  needs the BlueZ D-Bus API).
* SDK constraint relaxed to the advertised `>=3.3.0 <4.0.0`.

> Note: the macOS and Linux native code is reviewed but should be compiled on its
> target OS before production use.

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
