
import 'flutter_classic_bluetooth_platform_interface.dart';

class FlutterClassicBluetooth {
  Future<String?> getPlatformVersion() {
    return FlutterClassicBluetoothPlatform.instance.getPlatformVersion();
  }
}
