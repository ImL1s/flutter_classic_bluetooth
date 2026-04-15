import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_classic_bluetooth_method_channel.dart';

abstract class FlutterClassicBluetoothPlatform extends PlatformInterface {
  /// Constructs a FlutterClassicBluetoothPlatform.
  FlutterClassicBluetoothPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterClassicBluetoothPlatform _instance = MethodChannelFlutterClassicBluetooth();

  /// The default instance of [FlutterClassicBluetoothPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterClassicBluetooth].
  static FlutterClassicBluetoothPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterClassicBluetoothPlatform] when
  /// they register themselves.
  static set instance(FlutterClassicBluetoothPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
