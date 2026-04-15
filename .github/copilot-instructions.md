## Project Context
- This is a **Flutter plugin package** (`flutter_classic_bluetooth`) for Bluetooth Classic communication.
- Multi-platform: Android, iOS (MFi only), Windows, macOS, Linux.
- Unified Dart API with platform-specific native implementations.
- Uses Method Channels + Event Channels for native communication.
- The library entry point is `lib/flutter_classic_bluetooth.dart` (barrel export).

---

## 1. Architecture (Plugin Structure)
- Follow Flutter plugin architecture:

```
lib/
  flutter_classic_bluetooth.dart              → barrel export
  src/
    flutter_classic_bluetooth.dart            → main plugin class
    platform_interface.dart                   → abstract PlatformInterface
    method_channel.dart                       → MethodChannel implementation
    models/
      btc_device.dart                       → BtcDevice model
      btc_connection.dart                   → BtcConnection with streams
      btc_stream_sink.dart                  → BtcStreamSink for output
      btc_server_socket.dart                → BtcServerSocket for server mode
      btc_platform_capabilities.dart        → BtcPlatformCapabilities model
      btc_enums.dart                        → All enums
      btc_exceptions.dart                   → Exception hierarchy

android/src/main/kotlin/com/.../
  FlutterClassicBluetoothPlugin.kt            → Main plugin
  BluetoothConnection.kt                     → Abstract RFCOMM connection
  BluetoothConnectionWrapper.kt              → Concrete connection
  BluetoothServerSocket.kt                   → Server socket
  PermissionManager.kt                       → Permission handling
  ActivityResultManager.kt                   → Activity results
  BluetoothHelper.kt                         → Constants/utilities
  receivers/                                 → Broadcast receivers

windows/                                     → C++ with Winsock2/AF_BTH
macos/Classes/                               → Swift with IOBluetooth
linux/                                       → C++ with BlueZ/D-Bus
ios/Classes/                                 → Swift with ExternalAccessory
```

- Each file is standalone with its own imports — do NOT use `part of` / `part` directives.
- Keep Dart layer platform-agnostic. All platform checks happen in native code.
- Method channel contract is identical across all platforms — unsupported features throw typed exceptions.

---

## 2. Method Channel Contract
- Namespace: `flutter_classic_bluetooth`
- Method channel: `flutter_classic_bluetooth/methods`
- Event channels:
  - `flutter_classic_bluetooth/adapter_state`
  - `flutter_classic_bluetooth/discovery_state`
  - `flutter_classic_bluetooth/discovery_results`
  - `flutter_classic_bluetooth/bond_state`
  - `flutter_classic_bluetooth/connection/{id}` — per-connection data
  - `flutter_classic_bluetooth/connection_state/{id}` — per-connection state
  - `flutter_classic_bluetooth/server/{id}` — per-server incoming connections

---

## 3. Naming Conventions
- Variables: camelCase
- Files: snake_case.dart
- Classes: PascalCase
- Constants: camelCase for Dart, UPPER_SNAKE_CASE for native constants
- Private members: prefix with `_`
- Enum values: camelCase

---

## 4. Code Style
- Avoid unnecessary comments.
- Only add comments for complex logic, important notes, or public API docs.
- Keep code clean and readable.
- Avoid over-engineering.
- `dynamic` is allowed in method channel map values, but avoid elsewhere.
- Public API classes and methods must have dartdoc comments (`///`).
- Platform-specific behavior documented in dartdoc with platform matrix tables.

---

## 5. Dependencies
- Dependencies: `flutter`, `plugin_platform_interface`, `meta`
- Dev dependencies: `flutter_test`, `flutter_lints`
- Add packages using terminal: `flutter pub add <package_name>` or `flutter pub add --dev <package_name>`
- Do NOT manually edit pubspec.yaml to add dependencies.

---

## 6. Error Handling
- Throw typed exceptions from `BtcException` hierarchy:
  - `BtcUnsupportedException` — feature not available on platform
  - `BtcPermissionException` — permission denied
  - `BtcDisabledException` — adapter is off
  - `BtcConnectionException` — connection failed
  - `BtcWriteException` — write failed
  - `BtcTimeoutException` — operation timed out
  - `BtcAddressException` — invalid address
  - `BtcUuidException` — invalid UUID
- Convert PlatformException from native side to typed exceptions in method channel layer.
- Never silently swallow errors.
- Validate at public API boundaries only (plugin class, connection constructors).

---

## 7. Modularity & File Size
- Keep code modular.
- Maximum file length: 400–500 lines.
- Split large classes across multiple files if needed.
- One class per file for models.
- Platform interface methods grouped by category (adapter, discovery, pairing, connection, server).

---

## 8. Testing
- All public API changes must have corresponding tests.
- Test model serialization/deserialization (fromMap/toMap).
- Test platform interface throws UnimplementedError for all methods.
- Test method channel sends correct method names and arguments.
- Test BtcConnection stream management.
- Test exception hierarchy and conversion from PlatformException.
- Run `flutter test` before committing.
- Run `flutter analyze` after any code change and fix all issues.
- Commit after every meaningful change with a clear, descriptive message.

---

## 9. Platform Capability Pattern
- Each platform reports its capabilities via `getPlatformCapabilities()`.
- Unsupported features throw `BtcUnsupportedException` with clear message.
- Users can check capabilities before calling: `capabilities.canDiscoverDevices`.
- Every method dartdoc includes platform support table.

---

## 10. Connection Architecture
- Multiple simultaneous connections supported (connection ID system).
- Each connection gets its own EventChannel for data streaming.
- BtcConnection object wraps: input stream (read), output sink (write).
- BtcStreamSink uses chained futures for ordered write delivery.
- Graceful disconnect: `finish()` waits for pending writes, `close()` is immediate.
- Connection objects are disposable — `dispose()` cleans up streams and channels.

---

## 11. General Rules
- Do not mix architecture styles.
- Remove unused code.
- Keep code production-ready and scalable.
- Maintain backward compatibility for public API changes.
- Native code follows platform conventions (Kotlin for Android, Swift for iOS/macOS, C++ for Windows/Linux).
- All native methods handle permissions automatically where possible.
## Project Context
- This is a **pure Dart package** (`csv_plus`) for reading, writing, streaming, and manipulating CSV data.
- NOT a Flutter app. No UI, no state management, no networking.
- Must work on all Dart platforms: VM, Web, AOT.
- Zero external dependencies — pure Dart only.
- The library entry point is `lib/csv_plus.dart` (barrel export).

---

## 1. Architecture (Layered Package Structure)
- Follow layered architecture within `lib/src/`:

```
lib/src/
  core/        → CsvConfig, QuoteMode enum, CsvException hierarchy
  codec/       → CsvCodec (main facade), codec adapter for dart:convert
  encoder/     → CsvEncoder (stream), FastEncoder (batch, StringBuffer-based)
  decoder/     → CsvDecoder (stream, chunked state machine), FastDecoder (batch, byte-level), DelimiterDetector
  table/       → CsvTable (2D data structure), CsvRow (header-aware), CsvColumn, CsvSchema
  query/       → Filtering (where, firstWhere, distinct), sorting (sortBy, sortByMultiple)
  transform/   → Column/row manipulation (add, remove, rename, reorder), aggregation (sum, avg, groupBy)
  io/          → CsvFile (file read/write/stream/append) — dart:io isolated here
```

- Each file is a standalone Dart file with its own imports — do NOT use `part of` / `part` directives.
- Keep layers separate: encoder should not depend on decoder logic and vice versa.
- Decoder and encoder layers have two paths each: fast batch (maximum speed) and streaming (chunked, memory-efficient).

---

## 2. Performance & Memory
- **Dual-path architecture**: Batch operations use byte-level (`codeUnits`) parsing for speed; streaming uses chunked state machine for memory efficiency.
- Use `codeUnits` array indexing and ASCII constants in FastDecoder — no string ops in hot loops.
- Use labeled loops (`row_loop:`, `cell_loop:`) for efficient control flow in FastDecoder.
- Type inference by first-byte detection: `"` → string, `t`/`f` → bool, digit → number, `,`/`\n` → null.
- Per-call `StringBuffer` in encoder (not global) for thread safety.
- No `tryParse()` in hot loops — detect int vs double by scanning for `.` in byte array.
- No regex in decoder hot paths — direct codeUnit comparison only.
- Prefer `StringBuffer` over string concatenation (`+`) everywhere.
- Pre-size row lists when column count is known.
- Profile before optimizing — focus on measurable bottlenecks.

---

## 3. Naming Conventions
- Variables: camelCase
- Files: snake_case.dart
- Classes: PascalCase
- Constants: UPPER_SNAKE_CASE
- Private members: prefix with `_`

---

## 4. Code Style
- Avoid unnecessary comments.
- Only add comments for complex logic, important notes, or public API docs.
- Keep code clean and readable.
- Avoid over-engineering.
- `dynamic` is allowed in CSV cell values (mixed-type rows are expected), but avoid elsewhere.
- Public API classes and methods should have dartdoc comments (`///`).

---

## 5. Dependencies
- **Zero external dependencies** — this is a pure Dart library.
- Only dev dependencies: `lints`, `test`.
- Add dev packages using terminal: `dart pub add --dev <package_name>`
- Do NOT manually edit pubspec.yaml to add dependencies.

---

## 6. Error Handling
- Throw typed exceptions: `CsvException`, `CsvParseException`, `CsvValidationException`.
- Never silently swallow errors — at minimum log them.
- Validate input at public API boundaries only (CsvCodec, CsvTable constructors, CsvFile).
- Graceful handling of malformed CSV: unmatched quotes treated as literal characters (PapaParse behavior).

---

## 7. Modularity & File Size
- Keep code modular.
- Avoid large files.
- Maximum file length: 400–500 lines.
- Split large classes across multiple files if needed.

---

## 8. Testing
- All public API changes must have corresponding tests.
- Cover encode/decode round-trips for all types (String, int, double, bool, null).
- Test edge cases: BOM, Excel sep=, CRLF splits, escaped quotes, multi-char delimiters, empty input.
- Test streaming with chunk boundaries that split mid-field, mid-escape, mid-CRLF.
- Run `dart test` before committing.
- Run `dart analyze` after any code change and fix all issues before proceeding.
- Commit after every meaningful change with a clear, descriptive message.

---

## 9. Platform Compatibility
- Package must compile on all Dart platforms (VM, Web, AOT).
- `dart:io` usage must be isolated in `io/csv_file.dart` only.
- Core encode/decode/table functionality must not import `dart:io`.

---

## 10. General Rules
- Do not mix architecture styles.
- Avoid hardcoded values — use constants from `core/csv_config.dart`.
- Remove unused code.
- Keep code production-ready and scalable.
- Maintain backward compatibility for public API changes.