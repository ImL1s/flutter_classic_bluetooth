#ifndef FLUTTER_PLUGIN_FLUTTER_CLASSIC_BLUETOOTH_PLUGIN_H_
#define FLUTTER_PLUGIN_FLUTTER_CLASSIC_BLUETOOTH_PLUGIN_H_

#include <flutter/event_channel.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <map>
#include <memory>
#include <mutex>
#include <string>

#include "bluetooth_connection.h"
#include "bluetooth_server.h"

namespace flutter_classic_bluetooth {

// StreamHandler that stores the event sink for later use
class PluginStreamHandler : public flutter::StreamHandler<flutter::EncodableValue> {
 public:
  std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> OnListenInternal(
      const flutter::EncodableValue* arguments,
      std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events) override {
    sink_ = std::move(events);
    return nullptr;
  }

  std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> OnCancelInternal(
      const flutter::EncodableValue* arguments) override {
    sink_.reset();
    return nullptr;
  }

  flutter::EventSink<flutter::EncodableValue>* sink() const { return sink_.get(); }

 private:
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> sink_;
};

class FlutterClassicBluetoothPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FlutterClassicBluetoothPlugin(flutter::BinaryMessenger* messenger);
  virtual ~FlutterClassicBluetoothPlugin();

  FlutterClassicBluetoothPlugin(const FlutterClassicBluetoothPlugin&) = delete;
  FlutterClassicBluetoothPlugin& operator=(const FlutterClassicBluetoothPlugin&) = delete;

  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

 private:
  flutter::BinaryMessenger* messenger_;
  bool wsa_initialized_ = false;

  std::map<int, std::unique_ptr<BluetoothConnection>> connections_;
  std::map<int, std::unique_ptr<BluetoothServer>> servers_;
  std::mutex connections_mutex_;
  std::mutex servers_mutex_;
  int next_connection_id_ = 1;
  int next_server_id_ = 1;

  // Discovery
  std::atomic<bool> discovering_{false};
  std::thread discovery_thread_;

  // Event channels
  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>> adapter_state_channel_;
  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>> discovery_state_channel_;
  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>> discovery_results_channel_;
  PluginStreamHandler* adapter_state_handler_ = nullptr;
  PluginStreamHandler* discovery_state_handler_ = nullptr;
  PluginStreamHandler* discovery_results_handler_ = nullptr;

  void InitWinsock();
  void CleanupWinsock();

  // Method handlers
  void HandleIsSupported(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void HandleIsEnabled(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void HandleGetAdapterName(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void HandleGetAdapterAddress(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void HandleStartDiscovery(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void HandleStopDiscovery(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void HandleGetPairedDevices(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void HandleBondDevice(const flutter::EncodableMap& args,
                        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void HandleUnbondDevice(const flutter::EncodableMap& args,
                          std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void HandleConnect(const flutter::EncodableMap& args,
                     std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void HandleDisconnect(const flutter::EncodableMap& args,
                        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void HandleWrite(const flutter::EncodableMap& args,
                   std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void HandleStartServer(const flutter::EncodableMap& args,
                         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void HandleStopServer(const flutter::EncodableMap& args,
                        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void HandleGetPlatformCapabilities(
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace flutter_classic_bluetooth

#endif  // FLUTTER_PLUGIN_FLUTTER_CLASSIC_BLUETOOTH_PLUGIN_H_
