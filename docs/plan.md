# Flutter Classic Bluetooth — Complete Implementation Plan

## Package Identity
- **Name**: `flutter_classic_bluetooth`
- **Goal**: The definitive Flutter Bluetooth Classic package — all platforms, unified API, honest capability reporting
- **Platforms**: Android, Windows, macOS, Linux, iOS (MFi only)

---

## PHASE 1: Dart API Layer (Platform-Independent)

### 1.1 Project Setup
- [ ] Create Flutter plugin project with federated plugin structure
- [ ] pubspec.yaml — declare all 5 platforms (android, windows, macos, linux, ios)
- [ ] Set min Dart SDK >=3.3.0, Flutter >=3.22.0
- [ ] Dependencies: plugin_platform_interface, meta
- [ ] analysis_options.yaml — strict lint rules
- [ ] LICENSE (MIT or BSD-3-Clause)

### 1.2 Models (`lib/src/models/`)

#### 1.2.1 BtcDevice
- `address` (String) — MAC address (or UUID on macOS/iOS)
- `name` (String?) — friendly name
- `alias` (String?) — locally set alias (Android 30+)
- `rssi` (int?) — signal strength during discovery
- `type` (BtcDeviceType) — classic, dual, le, unknown
- `bondState` (BtcBondState) — none, bonding, bonded
- `uuids` (List\<String>) — advertised service UUIDs
- `isConnected` (bool) — currently connected
- `fromMap()` factory constructor
- `toMap()` method
- `==` and `hashCode` override (based on address)
- `toString()` override

#### 1.2.2 BtcConnection
- `id` (int) — connection identifier (for multi-connection support)
- `address` (String) — remote device address
- `input` (Stream\<Uint8List>) — incoming data stream
- `output` (BtcStreamSink) — outgoing data sink
- `isConnected` (bool) — connection state
- `writeString(String text)` — helper, UTF-8 encode and send
- `writeBytes(Uint8List data)` — send raw bytes
- `close()` — close immediately
- `finish()` — close gracefully (wait for pending writes)
- `dispose()` — alias for finish

#### 1.2.3 BtcStreamSink (implements EventSink\<Uint8List>)
- `add(Uint8List data)` — queue data to send
- `addStream(Stream\<Uint8List>)` — pipe stream
- `close()` — close the sink
- `allSent` (Future) — resolves when all queued data sent
- Chained futures pattern for ordered writes

#### 1.2.4 BtcServerSocket
- `id` (int) — server socket identifier
- `onConnected` (Stream\<BtcConnection>) — incoming connections
- `close()` — stop listening
- `serviceName` (String) — SDP service name
- `uuid` (String) — SDP service UUID

#### 1.2.5 Enums
- `BtcAdapterState` — unknown, turningOn, on, turningOff, off, unauthorized, unsupported
- `BtcBondState` — none, bonding, bonded
- `BtcDeviceType` — classic, dual, le, unknown
- `BtcConnectionState` — disconnected, connecting, connected, disconnecting

#### 1.2.6 BtcPlatformCapabilities
- `canEnableBluetooth` (bool)
- `canDisableBluetooth` (bool)
- `canDiscoverDevices` (bool)
- `canGetPairedDevices` (bool)
- `canBondDevices` (bool)
- `canUnbondDevices` (bool)
- `canCreateServer` (bool)
- `canSetDiscoverable` (bool)
- `supportsMultipleConnections` (bool)
- `supportsSecureConnection` (bool)
- `supportsInsecureConnection` (bool)
- `requiresMfiCertification` (bool)
- `platformNote` (String?) — e.g. "iOS only supports MFi-certified accessories"

#### 1.2.7 BtcException hierarchy
- `BtcException` (base)
  - `BtcUnsupportedException` — feature not available on platform
  - `BtcPermissionException` — permission denied
  - `BtcDisabledException` — adapter is off
  - `BtcConnectionException` — connection failed
  - `BtcWriteException` — write failed
  - `BtcTimeoutException` — operation timed out
  - `BtcAddressException` — invalid address format
  - `BtcUuidException` — invalid UUID format

### 1.3 Platform Interface (`lib/src/platform_interface.dart`)

Abstract class extending PlatformInterface with all methods:

#### Adapter Methods
- `isSupported()` → Future\<bool>
- `isEnabled()` → Future\<bool>
- `enableBluetooth()` → Future\<bool>
- `disableBluetooth()` → Future\<bool>
- `getAdapterState()` → Future\<BtcAdapterState>
- `adapterStateStream()` → Stream\<BtcAdapterState>
- `getAdapterName()` → Future\<String?>
- `getAdapterAddress()` → Future\<String?>

#### Discovery Methods
- `startDiscovery()` → Future\<void>
- `stopDiscovery()` → Future\<void>
- `isDiscovering()` → Future\<bool>
- `discoveryStateStream()` → Stream\<bool>
- `discoveryResultStream()` → Stream\<BtcDevice>

#### Paired/Bonded Device Methods
- `getPairedDevices()` → Future\<List\<BtcDevice>>
- `bondDevice(String address)` → Future\<bool>
- `unbondDevice(String address)` → Future\<bool>
- `bondStateStream()` → Stream\<BtcDevice> (bond state changes)

#### Connection Methods
- `connect(String address, {String? uuid, bool secure = true, int? timeout})` → Future\<BtcConnection>
- `disconnect(int connectionId)` → Future\<void>
- `write(int connectionId, Uint8List data)` → Future\<void>
- `connectionStateStream(int connectionId)` → Stream\<BtcConnectionState>

#### Server Methods
- `startServer({String? serviceName, String? uuid, bool secure = true})` → Future\<BtcServerSocket>
- `stopServer(int serverId)` → Future\<void>

#### Discoverability
- `setDiscoverable(int durationSeconds)` → Future\<bool>

#### Capability
- `getPlatformCapabilities()` → Future\<BtcPlatformCapabilities>

### 1.4 Method Channel Implementation (`lib/src/method_channel.dart`)

- Namespace: `"flutter_classic_bluetooth"`
- Method channel: `"flutter_classic_bluetooth/methods"`
- Event channels:
  - `"flutter_classic_bluetooth/adapter_state"` — adapter state changes
  - `"flutter_classic_bluetooth/discovery_state"` — scanning on/off
  - `"flutter_classic_bluetooth/discovery_results"` — found devices
  - `"flutter_classic_bluetooth/bond_state"` — bond state changes
  - `"flutter_classic_bluetooth/connection/{id}"` — per-connection data stream
  - `"flutter_classic_bluetooth/connection_state/{id}"` — per-connection state
  - `"flutter_classic_bluetooth/server/{id}"` — per-server incoming connections

### 1.5 Main Plugin Class (`lib/src/flutter_classic_bluetooth.dart`)

- Singleton or instance-based (prefer instance with factory)
- Wraps platform interface with Dart-level convenience
- Constructs BtcConnection objects from connection IDs
- Manages connection lifecycle
- usesFineLocation parameter for Android scan

### 1.6 Barrel Export (`lib/flutter_classic_bluetooth.dart`)

Export all public classes, enums, exceptions.

---

## PHASE 2: Android Implementation (Kotlin)

### 2.1 Project Structure
```
android/src/main/kotlin/com/flutter_classic_bluetooth/
├── FlutterClassicBluetoothPlugin.kt    # Main plugin, MethodCallHandler, ActivityAware
├── BluetoothConnection.kt              # Abstract RFCOMM connection base
├── BluetoothConnectionWrapper.kt       # Concrete connection with event channel
├── BluetoothServerSocket.kt            # RFCOMM server socket
├── PermissionManager.kt                # Automatic permission handling
├── ActivityResultManager.kt            # Activity result callbacks
├── BluetoothHelper.kt                  # Constants, converters, utilities
├── receivers/
│   ├── AdapterStateReceiver.kt         # ACTION_STATE_CHANGED broadcaster
│   ├── ScanResultReceiver.kt           # ACTION_FOUND broadcaster
│   ├── DiscoveryStateReceiver.kt       # DISCOVERY_STARTED/FINISHED broadcaster
│   └── BondStateReceiver.kt            # BOND_STATE_CHANGED broadcaster
```

### 2.2 Methods to Implement
- `isSupported` — PackageManager.FEATURE_BLUETOOTH
- `isEnabled` — adapter.isEnabled
- `enableBluetooth` — ACTION_REQUEST_ENABLE intent
- `disableBluetooth` — adapter.disable() (requires BLUETOOTH_ADMIN, may not work on newer Android)
- `getAdapterState` — adapter.state mapped to string enum
- `getAdapterName` — adapter.name
- `getAdapterAddress` — adapter.address (restricted on Android 8+)
- `startDiscovery` — adapter.startDiscovery() with permission check
- `stopDiscovery` — adapter.cancelDiscovery()
- `isDiscovering` — adapter.isDiscovering
- `getPairedDevices` — adapter.bondedDevices (filter BLE-only)
- `bondDevice` — device.createBond()
- `unbondDevice` — device.removeBond() (reflection, hidden API)
- `connect` — createRfcommSocketToServiceRecord / createInsecureRfcommSocketToServiceRecord
- `disconnect` — socket.close()
- `write` — outputStream.write()
- `startServer` — adapter.listenUsingRfcommWithServiceRecord / listenUsingInsecureRfcommWithServiceRecord
- `stopServer` — serverSocket.close()
- `setDiscoverable` — ACTION_REQUEST_DISCOVERABLE intent with EXTRA_DISCOVERABLE_DURATION

### 2.3 Permissions in AndroidManifest.xml
```xml
<!-- Legacy (API < 31) -->
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<!-- Android 12+ (API 31+) -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />
<!-- Feature declaration -->
<uses-feature android:name="android.hardware.bluetooth" android:required="true" />
```

### 2.4 Broadcast Receivers
- `BluetoothAdapter.ACTION_STATE_CHANGED` → adapter state stream
- `BluetoothDevice.ACTION_FOUND` → scan results stream (include RSSI from EXTRA_RSSI)
- `BluetoothAdapter.ACTION_DISCOVERY_STARTED` / `ACTION_DISCOVERY_FINISHED` → discovery state stream
- `BluetoothDevice.ACTION_BOND_STATE_CHANGED` → bond state stream

### 2.5 Connection Architecture
- SparseArray\<BluetoothConnectionWrapper> for multiple connections
- Incrementing connection IDs
- Per-connection EventChannel for data streaming
- Abstract BluetoothConnection base class with ConnectionThread inner class
- Thread per connection for blocking I/O
- requestedClosing volatile flag for graceful shutdown
- Buffer size: 1024 bytes
- onRead callback → EventSink.success(data)
- onDisconnected callback → EventSink.endOfStream()

### 2.6 Server Architecture
- SparseArray\<BluetoothServerSocketWrapper> for multiple servers
- Server thread blocks on accept(), creates new connection on accept
- Per-server EventChannel for incoming connection notifications
- Server auto-registers SDP service record

### 2.7 Android Platform Capabilities
```
canEnableBluetooth: true
canDisableBluetooth: true (may fail on newer Android)
canDiscoverDevices: true
canGetPairedDevices: true
canBondDevices: true
canUnbondDevices: true (via reflection)
canCreateServer: true
canSetDiscoverable: true
supportsMultipleConnections: true
supportsSecureConnection: true
supportsInsecureConnection: true
requiresMfiCertification: false
```

---

## PHASE 3: Windows Implementation (C++)

### 3.1 Project Structure
```
windows/
├── flutter_classic_bluetooth_plugin.h
├── flutter_classic_bluetooth_plugin.cpp
├── flutter_classic_bluetooth_plugin_c_api.cpp
├── bluetooth_connection.h
├── bluetooth_connection.cpp
├── bluetooth_server.h
├── bluetooth_server.cpp
├── bluetooth_helper.h
├── bluetooth_helper.cpp
├── CMakeLists.txt
```

### 3.2 Windows APIs Used
- `bluetoothapis.h` — device enumeration, pairing
- `ws2bth.h` — RFCOMM sockets (AF_BTH)
- `BluetoothFindFirstRadio` / `BluetoothGetRadioInfo` — adapter info
- `BluetoothFindFirstDevice` / `BluetoothFindNextDevice` — discovery
- `BluetoothEnumerateInstalledServices` — service enumeration
- `BluetoothAuthenticateDevice` — pairing
- `BluetoothRemoveDevice` — unpairing
- `WSALookupServiceBegin` — SDP queries
- `WM_DEVICECHANGE` — adapter state changes (via window message)

### 3.3 Methods to Implement
- `isSupported` — BluetoothFindFirstRadio != NULL
- `isEnabled` — BluetoothIsDiscoverable or radio info check
- `enableBluetooth` — BluetoothEnableIncomingConnections + BluetoothEnableDiscovery (limited)
- `disableBluetooth` — limited on Windows
- `getAdapterState` — radio state check
- `getAdapterName` — BLUETOOTH_RADIO_INFO.szName
- `getAdapterAddress` — BLUETOOTH_RADIO_INFO.address
- `startDiscovery` — BluetoothFindFirstDevice in background thread (or WSALookupServiceBegin)
- `stopDiscovery` — cancel discovery thread
- `getPairedDevices` — BluetoothFindFirstDevice with fReturnAuthenticated
- `bondDevice` — BluetoothAuthenticateDevice / BluetoothAuthenticateDeviceEx
- `unbondDevice` — BluetoothRemoveDevice
- `connect` — socket(AF_BTH, SOCK_STREAM, BTHPROTO_RFCOMM) + connect()
- `disconnect` — closesocket()
- `write` — send()
- `read` — recv() in background thread
- `startServer` — bind() + listen() + accept() on AF_BTH socket
- `stopServer` — closesocket()

### 3.4 Threading Model
- std::thread for each connection (blocking recv)
- std::thread for discovery
- std::thread for server accept loop
- std::mutex for shared data
- Non-blocking sockets with select() or OVERLAPPED I/O

### 3.5 MAC Address Parsing
Support formats: `XX:XX:XX:XX:XX:XX`, `XX-XX-XX-XX-XX-XX`, `XXXXXXXXXXXX`
Convert to BTH_ADDR (ULONGLONG)

### 3.6 RFCOMM Channel
- Default: try SDP lookup for UUID, fallback to channel 1-30 scanning
- Or user provides specific UUID for SDP service lookup

### 3.7 CMakeLists.txt Dependencies
```cmake
target_link_libraries(${PLUGIN_NAME} PRIVATE
  flutter
  ws2_32          # Winsock2
  Bthprops        # Bluetooth APIs
  irprops         # Bluetooth device enumeration
)
```

### 3.8 Windows Platform Capabilities
```
canEnableBluetooth: false (limited — can enable discoverable but not power on/off)
canDisableBluetooth: false
canDiscoverDevices: true
canGetPairedDevices: true
canBondDevices: true
canUnbondDevices: true
canCreateServer: true
canSetDiscoverable: true (BluetoothEnableDiscovery)
supportsMultipleConnections: true
supportsSecureConnection: true
supportsInsecureConnection: true
requiresMfiCertification: false
```

---

## PHASE 4: macOS Implementation (Swift)

### 4.1 Project Structure
```
macos/Classes/
├── FlutterClassicBluetoothPlugin.swift
├── BluetoothManager.swift
├── BluetoothConnection.swift
├── BluetoothServer.swift
├── BluetoothHelper.swift
```

### 4.2 macOS Frameworks Used
- `IOBluetooth` — the Classic Bluetooth framework
  - `IOBluetoothHostController` — adapter info/state
  - `IOBluetoothDevice` — remote device representation
  - `IOBluetoothDeviceInquiry` — device discovery
  - `IOBluetoothRFCOMMChannel` — RFCOMM connection
  - `IOBluetoothSDPServiceRecord` — SDP services
  - `IOBluetoothSDPUUID` — UUID handling
  - `IOBluetoothUserNotification` — connect/disconnect notifications

### 4.3 Methods to Implement
- `isSupported` — IOBluetoothHostController.default() != nil
- `isEnabled` — hostController.powerState == kBluetoothHCIPowerStateON
- `enableBluetooth` — ❌ UNSUPPORTED (throw BtcUnsupportedException)
- `disableBluetooth` — ❌ UNSUPPORTED
- `getAdapterState` — hostController.powerState mapping
- `getAdapterName` — hostController.nameAsString()
- `getAdapterAddress` — hostController.addressAsString()
- `startDiscovery` — IOBluetoothDeviceInquiry.start()
- `stopDiscovery` — IOBluetoothDeviceInquiry.stop()
- `getPairedDevices` — IOBluetoothDevice.pairedDevices()
- `bondDevice` — IOBluetoothDevice.openConnection() triggers pairing
- `unbondDevice` — IOBluetoothDevice.removeFromFavorites() (partial)
- `connect` — device.openRFCOMMChannelSync(&channel, withChannelID: channelID, delegate: self)
- `disconnect` — rfcommChannel.close()
- `write` — rfcommChannel.writeSync(dataPtr, length: UInt16(data.count))
- `read` — via IOBluetoothRFCOMMChannelDelegate.rfcommChannelData()
- `startServer` — IOBluetoothSDPServiceRecord.publishedServiceRecord + listen for incoming RFCOMM
- `stopServer` — remove service record + close channel

### 4.4 Delegate Callbacks
- `IOBluetoothDeviceInquiryDelegate`:
  - `deviceInquiryDeviceFound` → scan results stream
  - `deviceInquiryStarted` → discovery state stream
  - `deviceInquiryComplete` → discovery state stream
- `IOBluetoothRFCOMMChannelDelegate`:
  - `rfcommChannelData` → connection data stream
  - `rfcommChannelClosed` → connection state stream
  - `rfcommChannelOpenComplete` → connection established

### 4.5 Adapter State Monitoring
- KVO on IOBluetoothHostController.powerState
- Or register for `IOBluetoothHostControllerPoweredOnNotification` / `PoweredOffNotification`
- Distribute notifications via NSDistributedNotificationCenter

### 4.6 macOS Entitlements
```xml
<key>com.apple.security.device.bluetooth</key>
<true/>
```
And in Info.plist:
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app needs Bluetooth to communicate with nearby devices.</string>
```

### 4.7 macOS Platform Capabilities
```
canEnableBluetooth: false
canDisableBluetooth: false
canDiscoverDevices: true
canGetPairedDevices: true
canBondDevices: true (via openConnection triggering pair dialog)
canUnbondDevices: true (partial — removeFromFavorites)
canCreateServer: true (via SDP service record + RFCOMM listener)
canSetDiscoverable: false (system controlled)
supportsMultipleConnections: true
supportsSecureConnection: true
supportsInsecureConnection: false (macOS doesn't expose insecure option easily)
requiresMfiCertification: false
```

---

## PHASE 5: Linux Implementation (C/C++ with BlueZ)

### 5.1 Project Structure
```
linux/
├── flutter_classic_bluetooth_plugin.h
├── flutter_classic_bluetooth_plugin.cc
├── bluetooth_manager.h
├── bluetooth_manager.cc
├── bluetooth_connection.h
├── bluetooth_connection.cc
├── bluetooth_server.h
├── bluetooth_server.cc
├── bluetooth_helper.h
├── bluetooth_helper.cc
├── dbus_helper.h
├── dbus_helper.cc
├── CMakeLists.txt
```

### 5.2 Linux APIs Used
- **BlueZ via D-Bus** (`org.bluez`):
  - `org.bluez.Adapter1` — adapter control (powered, discovering, discoverable)
  - `org.bluez.Device1` — device properties (name, address, paired, connected, UUIDs)
  - `org.bluez.AgentManager1` — pairing agent
- **BlueZ via sockets** (for RFCOMM):
  - `AF_BLUETOOTH` + `BTPROTO_RFCOMM` — RFCOMM sockets
  - `struct sockaddr_rc` — RFCOMM address
- **SDP**:
  - `sdp_connect()`, `sdp_service_search_attr_req()` — SDP queries
  - `sdp_record_register()` — SDP service registration

### 5.3 Methods to Implement
- `isSupported` — D-Bus: check if `org.bluez` service exists
- `isEnabled` — D-Bus: Adapter1.Powered property
- `enableBluetooth` — D-Bus: Set Adapter1.Powered = true
- `disableBluetooth` — D-Bus: Set Adapter1.Powered = false
- `getAdapterState` — D-Bus: Adapter1.Powered + other properties
- `getAdapterName` — D-Bus: Adapter1.Alias
- `getAdapterAddress` — D-Bus: Adapter1.Address
- `startDiscovery` — D-Bus: Adapter1.StartDiscovery()
- `stopDiscovery` — D-Bus: Adapter1.StopDiscovery()
- `isDiscovering` — D-Bus: Adapter1.Discovering
- `getPairedDevices` — D-Bus: iterate Device1 objects where Paired=true
- `bondDevice` — D-Bus: Device1.Pair()
- `unbondDevice` — D-Bus: Adapter1.RemoveDevice(device_path)
- `connect` — socket(AF_BLUETOOTH, SOCK_STREAM, BTPROTO_RFCOMM) + connect(sockaddr_rc)
- `disconnect` — close(socket_fd)
- `write` — write(socket_fd, data, len)
- `read` — read(socket_fd, buffer, len) in background thread
- `startServer` — bind() + listen() + accept() on RFCOMM socket + SDP register
- `stopServer` — close server socket + SDP unregister
- `setDiscoverable` — D-Bus: Set Adapter1.Discoverable = true, DiscoverableTimeout = duration

### 5.4 D-Bus Signal Monitoring
- `PropertiesChanged` on `org.bluez.Adapter1` → adapter state stream
- `PropertiesChanged` on `org.bluez.Device1` → bond state stream, connection state
- `InterfacesAdded` on `org.bluez` root → new device found during discovery

### 5.5 Threading
- GLib main loop integration (or separate thread for D-Bus event loop)
- pthread for each RFCOMM connection (blocking read)
- pthread for server accept loop

### 5.6 CMakeLists.txt Dependencies
```cmake
find_package(PkgConfig REQUIRED)
pkg_check_modules(DBUS REQUIRED dbus-1)
pkg_check_modules(BLUEZ REQUIRED bluez)
pkg_check_modules(GLIB REQUIRED glib-2.0)
pkg_check_modules(GIO REQUIRED gio-2.0)

target_link_libraries(${PLUGIN_NAME} PRIVATE
  flutter
  ${DBUS_LIBRARIES}
  ${BLUEZ_LIBRARIES}
  ${GLIB_LIBRARIES}
  ${GIO_LIBRARIES}
  bluetooth          # libbluetooth for RFCOMM sockets
  pthread
)
```

### 5.7 Linux Platform Capabilities
```
canEnableBluetooth: true
canDisableBluetooth: true
canDiscoverDevices: true
canGetPairedDevices: true
canBondDevices: true
canUnbondDevices: true
canCreateServer: true
canSetDiscoverable: true
supportsMultipleConnections: true
supportsSecureConnection: true
supportsInsecureConnection: true
requiresMfiCertification: false
```

---

## PHASE 6: iOS Implementation (Swift)

### 6.1 Project Structure
```
ios/Classes/
├── FlutterClassicBluetoothPlugin.swift
├── ExternalAccessoryManager.swift
├── AccessoryConnection.swift
├── AccessoryHelper.swift
```

### 6.2 iOS Frameworks Used
- `ExternalAccessory`:
  - `EAAccessoryManager` — discover/manage connected MFi accessories
  - `EAAccessory` — represents an MFi accessory
  - `EASession` — bidirectional communication session
  - `NSInputStream` / `NSOutputStream` — data streams

### 6.3 Methods to Implement
- `isSupported` — always true (framework exists)
- `isEnabled` — EAAccessoryManager check (limited — no direct adapter query)
- `enableBluetooth` — ❌ UNSUPPORTED (throw)
- `disableBluetooth` — ❌ UNSUPPORTED (throw)
- `getAdapterState` — ❌ limited, can return "unknown" or "on" based on connected accessories
- `startDiscovery` — ❌ UNSUPPORTED (throw — iOS auto-discovers MFi accessories)
- `stopDiscovery` — ❌ UNSUPPORTED (throw)
- `getPairedDevices` — EAAccessoryManager.shared().connectedAccessories (only currently connected MFi accessories)
- `bondDevice` — ❌ UNSUPPORTED (throw — system handles pairing)
- `unbondDevice` — ❌ UNSUPPORTED
- `connect` — Open EASession with protocol string (user provides protocol, not address)
- `disconnect` — Close EASession streams
- `write` — outputStream.write()
- `read` — inputStream read via RunLoop or delegate
- `startServer` — ❌ UNSUPPORTED
- `stopServer` — ❌ UNSUPPORTED
- `setDiscoverable` — ❌ UNSUPPORTED

### 6.4 EAAccessory Notifications
- `EAAccessoryDidConnect` — accessory plugged in / connected
- `EAAccessoryDidDisconnect` — accessory removed / disconnected
- Register via `EAAccessoryManager.shared().registerForLocalNotifications()`

### 6.5 EAAccessory → BtcDevice mapping
- `address` → accessory.serialNumber or connectionID as string
- `name` → accessory.name
- `type` → .classic (always, since MFi = Classic)
- `bondState` → .bonded (always, since connected = paired)
- `uuids` → accessory.protocolStrings

### 6.6 Info.plist Requirements
```xml
<key>UISupportedExternalAccessoryProtocols</key>
<array>
    <string>com.example.myprotocol</string>
    <!-- User must declare their MFi protocol strings -->
</array>
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app uses Bluetooth to communicate with accessories.</string>
```

### 6.7 iOS Platform Capabilities
```
canEnableBluetooth: false
canDisableBluetooth: false
canDiscoverDevices: false
canGetPairedDevices: true (only connected MFi accessories)
canBondDevices: false
canUnbondDevices: false
canCreateServer: false
canSetDiscoverable: false
supportsMultipleConnections: true (multiple EASessions)
supportsSecureConnection: true (MFi = always secure)
supportsInsecureConnection: false
requiresMfiCertification: true
platformNote: "iOS only supports Bluetooth Classic communication with MFi-certified accessories via the ExternalAccessory framework. General Bluetooth Classic devices (SPP, RFCOMM) are not accessible."
```

---

## PHASE 7: Example App

### 7.1 Structure
```
example/lib/
├── main.dart                 # Home screen — adapter status, navigation
├── screens/
│   ├── adapter_screen.dart   # Adapter info, state, enable/disable
│   ├── discovery_screen.dart # Scan for devices, show results
│   ├── paired_screen.dart    # List paired devices, bond/unbond
│   ├── connect_screen.dart   # Connect to device, send/receive data
│   ├── server_screen.dart    # Start server, show incoming connections
│   └── capabilities_screen.dart # Show platform capabilities
```

### 7.2 Example Features
- Show current adapter state with real-time updates
- Toggle Bluetooth on/off (where supported)
- Scan for nearby devices with RSSI
- List paired/bonded devices
- Pair new device
- Connect to device with UUID selection
- Bidirectional data terminal (send text, see received text)
- Start RFCOMM server and accept connections
- Display platform capabilities matrix

---

## PHASE 8: Testing

### 8.1 Dart Unit Tests
- Model serialization/deserialization (fromMap/toMap)
- Platform interface throws UnimplementedError for all methods
- Method channel correctly sends/receives all method calls
- BtcConnection properly manages streams
- BtcStreamSink chained futures ordering
- Exception hierarchy
- BtcPlatformCapabilities truthfulness per platform

### 8.2 Integration Tests
- Per-platform integration test checking real adapter
- Discovery test (requires actual BT device nearby)
- Connect/disconnect lifecycle test
- Data echo test (requires echo server/device)

### 8.3 Platform-Specific Unit Tests
- Android: Kotlin unit tests for PermissionManager, helper converters
- Mock MethodChannel responses

---

## PHASE 9: Documentation & Publishing

### 9.1 README.md
- Package description
- Platform support matrix with version info
- Quick start guide
- Full API reference with platform annotations
- iOS MFi limitations section (prominent)
- Permission setup per platform
- Example code snippets
- Comparison with other packages

### 9.2 CHANGELOG.md
- Track all versions

### 9.3 API Docs
- Every public method documented
- Platform-specific behavior noted
- @throws annotations for exceptions

### 9.4 pub.dev
- Proper topics: bluetooth, bluetooth-classic, rfcomm, serial, connectivity
- Screenshots from example app

---

## IMPLEMENTATION ORDER

1. **Dart API Layer** — models, platform interface, method channel, main class, exceptions
2. **Android** — most feature-complete, good for validating API design
3. **Example App** — test with Android while building
4. **Windows** — second most common platform for BT Classic use
5. **Linux** — BlueZ is well-documented
6. **macOS** — IOBluetooth is older but functional
7. **iOS** — most limited, build last
8. **Testing** — unit tests alongside, integration tests after
9. **Documentation & Publishing**

---

## METHOD CHANNEL CONTRACT (All Platforms Implement Same Methods)

### Methods
| Method Name | Arguments | Returns |
|---|---|---|
| isSupported | none | bool |
| isEnabled | none | bool |
| enableBluetooth | none | bool |
| disableBluetooth | none | bool |
| getAdapterState | none | String (enum name) |
| getAdapterName | none | String? |
| getAdapterAddress | none | String? |
| startDiscovery | {usesFineLocation: bool} | void |
| stopDiscovery | none | void |
| isDiscovering | none | bool |
| getPairedDevices | none | List\<Map> |
| bondDevice | {address: String} | bool |
| unbondDevice | {address: String} | bool |
| connect | {address: String, uuid: String?, secure: bool, timeout: int?} | int (connection ID) |
| disconnect | {id: int} | void |
| write | {id: int, bytes: Uint8List} | void |
| startServer | {serviceName: String?, uuid: String?, secure: bool} | int (server ID) |
| stopServer | {id: int} | void |
| setDiscoverable | {duration: int} | bool |
| getPlatformCapabilities | none | Map\<String, dynamic> |

### Event Channels
| Channel Name | Event Type |
|---|---|
| flutter_classic_bluetooth/adapter_state | String (enum name) |
| flutter_classic_bluetooth/discovery_state | bool |
| flutter_classic_bluetooth/discovery_results | Map (BtcDevice) |
| flutter_classic_bluetooth/bond_state | Map (BtcDevice with updated bondState) |
| flutter_classic_bluetooth/connection/{id} | Uint8List (raw data) |
| flutter_classic_bluetooth/connection_state/{id} | String (enum name) |
| flutter_classic_bluetooth/server/{id} | int (new connection ID) |

---

## PLATFORM CAPABILITY MATRIX

| Feature | Android | Windows | macOS | Linux | iOS |
|---|---|---|---|---|---|
| isSupported | ✅ | ✅ | ✅ | ✅ | ✅ |
| isEnabled | ✅ | ✅ | ✅ | ✅ | ⚠️ limited |
| enableBluetooth | ✅ | ❌ | ❌ | ✅ | ❌ |
| disableBluetooth | ⚠️ newer Android may block | ❌ | ❌ | ✅ | ❌ |
| getAdapterState | ✅ | ✅ | ✅ | ✅ | ⚠️ limited |
| adapterStateStream | ✅ | ✅ | ✅ | ✅ | ⚠️ limited |
| getAdapterName | ✅ | ✅ | ✅ | ✅ | ❌ |
| getAdapterAddress | ⚠️ restricted Android 8+ | ✅ | ✅ | ✅ | ❌ |
| startDiscovery | ✅ | ✅ | ✅ | ✅ | ❌ |
| stopDiscovery | ✅ | ✅ | ✅ | ✅ | ❌ |
| isDiscovering | ✅ | ✅ | ✅ | ✅ | ❌ |
| discoveryStateStream | ✅ | ✅ | ✅ | ✅ | ❌ |
| discoveryResultStream | ✅ | ✅ | ✅ | ✅ | ❌ |
| getPairedDevices | ✅ | ✅ | ✅ | ✅ | ⚠️ MFi only |
| bondDevice | ✅ | ✅ | ✅ | ✅ | ❌ |
| unbondDevice | ⚠️ reflection | ✅ | ⚠️ partial | ✅ | ❌ |
| connect | ✅ | ✅ | ✅ | ✅ | ⚠️ MFi only |
| disconnect | ✅ | ✅ | ✅ | ✅ | ✅ |
| write | ✅ | ✅ | ✅ | ✅ | ✅ |
| read stream | ✅ | ✅ | ✅ | ✅ | ✅ |
| startServer | ✅ | ✅ | ✅ | ✅ | ❌ |
| stopServer | ✅ | ✅ | ✅ | ✅ | ❌ |
| setDiscoverable | ✅ | ✅ | ❌ | ✅ | ❌ |
| secureConnection | ✅ | ✅ | ✅ | ✅ | ✅ (MFi = always secure) |
| insecureConnection | ✅ | ✅ | ❌ | ✅ | ❌ |
| multipleConnections | ✅ | ✅ | ✅ | ✅ | ✅ |
