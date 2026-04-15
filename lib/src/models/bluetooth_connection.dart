import 'dart:async';

import 'package:flutter/services.dart';

import 'enums.dart';
import 'bluetooth_stream_sink.dart';

/// An active RFCOMM connection to a remote Bluetooth device.
///
/// Provides a byte stream [input] for reading data and a [output] sink
/// for writing data. Multiple connections can be active simultaneously,
/// each identified by a unique [id].
///
/// ## Usage
/// ```dart
/// final connection = await bluetooth.connect('AA:BB:CC:DD:EE:FF');
/// connection.input.listen((data) {
///   print('Received: $data');
/// });
/// await connection.output.add(Uint8List.fromList([0x01, 0x02]));
/// await connection.finish(); // graceful disconnect
/// ```
///
/// ## Lifecycle
/// - [finish] waits for pending writes then disconnects.
/// - [close] disconnects immediately, discarding pending writes.
/// - [dispose] cleans up all resources. Always call this when done.
///
/// {@category Models}
class BluetoothConnection {
  /// Unique identifier for this connection assigned by the native side.
  final int id;

  /// The address of the connected remote device.
  final String address;

  final MethodChannel _methodChannel;
  late final EventChannel _dataChannel;
  late final EventChannel _stateChannel;

  late final Stream<Uint8List> _inputStream;
  late final BluetoothStreamSink _outputSink;
  late final Stream<BluetoothConnectionState> _stateStream;

  StreamSubscription<BluetoothConnectionState>? _stateSubscription;
  BluetoothConnectionState _state = BluetoothConnectionState.connected;

  /// Creates a [BluetoothConnection] wrapping the native connection [id].
  ///
  /// This constructor is intended to be called by the method channel
  /// implementation, not directly by users.
  BluetoothConnection({
    required this.id,
    required this.address,
    required MethodChannel methodChannel,
  }) : _methodChannel = methodChannel {
    _dataChannel = EventChannel('flutter_classic_bluetooth/connection/$id');
    _stateChannel =
        EventChannel('flutter_classic_bluetooth/connection_state/$id');

    _inputStream = _dataChannel
        .receiveBroadcastStream()
        .map((event) => event as Uint8List);

    _outputSink = BluetoothStreamSink(
      connectionId: id,
      methodChannel: _methodChannel,
    );

    _stateStream = _stateChannel.receiveBroadcastStream().map((event) {
      return BluetoothConnectionState.values.firstWhere(
        (e) => e.name == event,
        orElse: () => BluetoothConnectionState.disconnected,
      );
    });

    _stateSubscription = _stateStream.listen((state) {
      _state = state;
    });
  }

  /// Stream of incoming bytes from the remote device.
  Stream<Uint8List> get input => _inputStream;

  /// Sink for writing bytes to the remote device.
  ///
  /// Writes are queued and delivered in order. Use [BluetoothStreamSink.add]
  /// to write data.
  BluetoothStreamSink get output => _outputSink;

  /// Stream of connection state changes.
  Stream<BluetoothConnectionState> get stateStream => _stateStream;

  /// The current connection state.
  BluetoothConnectionState get state => _state;

  /// Whether this connection is currently active.
  bool get isConnected => _state == BluetoothConnectionState.connected;

  /// Gracefully disconnects: waits for all pending writes to complete,
  /// then closes the connection.
  Future<void> finish() async {
    await _outputSink.close();
    await _methodChannel.invokeMethod('disconnect', {'id': id});
    _state = BluetoothConnectionState.disconnected;
  }

  /// Immediately disconnects, discarding any pending writes.
  Future<void> close() async {
    _outputSink.cancel();
    await _methodChannel.invokeMethod('disconnect', {'id': id});
    _state = BluetoothConnectionState.disconnected;
  }

  /// Releases all resources associated with this connection.
  ///
  /// Always call [dispose] when you are done with a connection.
  /// After calling this, the connection object should not be reused.
  void dispose() {
    _stateSubscription?.cancel();
    _stateSubscription = null;
    _outputSink.cancel();
  }
}
