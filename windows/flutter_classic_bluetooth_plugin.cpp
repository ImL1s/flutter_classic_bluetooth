#include "flutter_classic_bluetooth_plugin.h"

#include <winsock2.h>
#include <windows.h>
#include <ws2bth.h>
#include <BluetoothAPIs.h>

#include <flutter/method_channel.h>
#include <flutter/event_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>
#include <thread>
#include <vector>

#include "bluetooth_helper.h"
#include "bluetooth_connection.h"
#include "bluetooth_server.h"

#pragma comment(lib, "ws2_32.lib")
#pragma comment(lib, "Bthprops.lib")

namespace flutter_classic_bluetooth {

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

// static
void FlutterClassicBluetoothPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<EncodableValue>>(
          registrar->messenger(), "flutter_classic_bluetooth/methods",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<FlutterClassicBluetoothPlugin>(registrar->messenger());

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  // Register event channels
  plugin->adapter_state_channel_ = std::make_unique<flutter::EventChannel<EncodableValue>>(
      registrar->messenger(), "flutter_classic_bluetooth/adapter_state",
      &flutter::StandardMethodCodec::GetInstance());
  plugin->discovery_state_channel_ = std::make_unique<flutter::EventChannel<EncodableValue>>(
      registrar->messenger(), "flutter_classic_bluetooth/discovery_state",
      &flutter::StandardMethodCodec::GetInstance());
  plugin->discovery_results_channel_ = std::make_unique<flutter::EventChannel<EncodableValue>>(
      registrar->messenger(), "flutter_classic_bluetooth/discovery_results",
      &flutter::StandardMethodCodec::GetInstance());

  auto adapter_handler = std::make_unique<PluginStreamHandler>();
  plugin->adapter_state_handler_ = adapter_handler.get();
  plugin->adapter_state_channel_->SetStreamHandler(std::move(adapter_handler));

  auto disc_state_handler = std::make_unique<PluginStreamHandler>();
  plugin->discovery_state_handler_ = disc_state_handler.get();
  plugin->discovery_state_channel_->SetStreamHandler(std::move(disc_state_handler));

  auto disc_results_handler = std::make_unique<PluginStreamHandler>();
  plugin->discovery_results_handler_ = disc_results_handler.get();
  plugin->discovery_results_channel_->SetStreamHandler(std::move(disc_results_handler));

  registrar->AddPlugin(std::move(plugin));
}

FlutterClassicBluetoothPlugin::FlutterClassicBluetoothPlugin(
    flutter::BinaryMessenger* messenger)
    : messenger_(messenger) {
  InitWinsock();
}

FlutterClassicBluetoothPlugin::~FlutterClassicBluetoothPlugin() {
  discovering_.store(false);
  // Clean up connections and servers
  {
    std::lock_guard<std::mutex> lock(connections_mutex_);
    for (auto& [id, conn] : connections_) {
      conn->Close();
    }
    connections_.clear();
  }
  {
    std::lock_guard<std::mutex> lock(servers_mutex_);
    for (auto& [id, server] : servers_) {
      server->Stop();
    }
    servers_.clear();
  }
  CleanupWinsock();
}

void FlutterClassicBluetoothPlugin::InitWinsock() {
  WSADATA wsa_data;
  if (WSAStartup(MAKEWORD(2, 2), &wsa_data) == 0) {
    wsa_initialized_ = true;
  }
}

void FlutterClassicBluetoothPlugin::CleanupWinsock() {
  if (wsa_initialized_) {
    WSACleanup();
    wsa_initialized_ = false;
  }
}

void FlutterClassicBluetoothPlugin::HandleMethodCall(
    const flutter::MethodCall<EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {

  const auto& method = method_call.method_name();

  if (method == "isSupported") {
    HandleIsSupported(std::move(result));
  } else if (method == "isEnabled") {
    HandleIsEnabled(std::move(result));
  } else if (method == "enableBluetooth" || method == "disableBluetooth") {
    result->Error("unsupported", "Cannot programmatically enable/disable Bluetooth on Windows",
                  EncodableValue(EncodableMap{
                      {EncodableValue("feature"), EncodableValue(method)},
                      {EncodableValue("platform"), EncodableValue("Windows")}}));
  } else if (method == "getAdapterName") {
    HandleGetAdapterName(std::move(result));
  } else if (method == "getAdapterAddress") {
    HandleGetAdapterAddress(std::move(result));
  } else if (method == "startDiscovery") {
    HandleStartDiscovery(std::move(result));
  } else if (method == "stopDiscovery") {
    HandleStopDiscovery(std::move(result));
  } else if (method == "isDiscovering") {
    result->Success(EncodableValue(discovering_.load()));
  } else if (method == "getPairedDevices") {
    HandleGetPairedDevices(std::move(result));
  } else if (method == "bondDevice") {
    const auto* args = std::get_if<EncodableMap>(method_call.arguments());
    if (args) HandleBondDevice(*args, std::move(result));
    else result->Error("invalidArguments", "Arguments required", EncodableValue());
  } else if (method == "unbondDevice") {
    const auto* args = std::get_if<EncodableMap>(method_call.arguments());
    if (args) HandleUnbondDevice(*args, std::move(result));
    else result->Error("invalidArguments", "Arguments required", EncodableValue());
  } else if (method == "connect") {
    const auto* args = std::get_if<EncodableMap>(method_call.arguments());
    if (args) HandleConnect(*args, std::move(result));
    else result->Error("invalidArguments", "Arguments required", EncodableValue());
  } else if (method == "disconnect") {
    const auto* args = std::get_if<EncodableMap>(method_call.arguments());
    if (args) HandleDisconnect(*args, std::move(result));
    else result->Error("invalidArguments", "Arguments required", EncodableValue());
  } else if (method == "write") {
    const auto* args = std::get_if<EncodableMap>(method_call.arguments());
    if (args) HandleWrite(*args, std::move(result));
    else result->Error("invalidArguments", "Arguments required", EncodableValue());
  } else if (method == "startServer") {
    const auto* args = std::get_if<EncodableMap>(method_call.arguments());
    if (args) HandleStartServer(*args, std::move(result));
    else result->Error("invalidArguments", "Arguments required", EncodableValue());
  } else if (method == "stopServer") {
    const auto* args = std::get_if<EncodableMap>(method_call.arguments());
    if (args) HandleStopServer(*args, std::move(result));
    else result->Error("invalidArguments", "Arguments required", EncodableValue());
  } else if (method == "setDiscoverable") {
    result->Error("unsupported", "setDiscoverable not available on Windows",
                  EncodableValue(EncodableMap{
                      {EncodableValue("feature"), EncodableValue("setDiscoverable")},
                      {EncodableValue("platform"), EncodableValue("Windows")}}));
  } else if (method == "getPlatformCapabilities") {
    HandleGetPlatformCapabilities(std::move(result));
  } else {
    result->NotImplemented();
  }
}

void FlutterClassicBluetoothPlugin::HandleIsSupported(
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  HANDLE radio = nullptr;
  BLUETOOTH_FIND_RADIO_PARAMS params = {sizeof(BLUETOOTH_FIND_RADIO_PARAMS)};
  HBLUETOOTH_RADIO_FIND find = BluetoothFindFirstRadio(&params, &radio);
  bool supported = (find != nullptr);
  if (find) {
    BluetoothFindRadioClose(find);
    CloseHandle(radio);
  }
  result->Success(EncodableValue(supported));
}

void FlutterClassicBluetoothPlugin::HandleIsEnabled(
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  HANDLE radio = nullptr;
  BLUETOOTH_FIND_RADIO_PARAMS params = {sizeof(BLUETOOTH_FIND_RADIO_PARAMS)};
  HBLUETOOTH_RADIO_FIND find = BluetoothFindFirstRadio(&params, &radio);
  bool enabled = false;
  if (find) {
    enabled = BluetoothIsConnectable(radio) != FALSE;
    BluetoothFindRadioClose(find);
    CloseHandle(radio);
  }
  result->Success(EncodableValue(enabled));
}

void FlutterClassicBluetoothPlugin::HandleGetAdapterName(
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  HANDLE radio = nullptr;
  BLUETOOTH_FIND_RADIO_PARAMS params = {sizeof(BLUETOOTH_FIND_RADIO_PARAMS)};
  HBLUETOOTH_RADIO_FIND find = BluetoothFindFirstRadio(&params, &radio);
  if (find) {
    BLUETOOTH_RADIO_INFO info = {sizeof(BLUETOOTH_RADIO_INFO)};
    if (BluetoothGetRadioInfo(radio, &info) == ERROR_SUCCESS) {
      result->Success(EncodableValue(WideToUtf8(info.szName)));
    } else {
      result->Success(EncodableValue());
    }
    BluetoothFindRadioClose(find);
    CloseHandle(radio);
  } else {
    result->Success(EncodableValue());
  }
}

void FlutterClassicBluetoothPlugin::HandleGetAdapterAddress(
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  HANDLE radio = nullptr;
  BLUETOOTH_FIND_RADIO_PARAMS params = {sizeof(BLUETOOTH_FIND_RADIO_PARAMS)};
  HBLUETOOTH_RADIO_FIND find = BluetoothFindFirstRadio(&params, &radio);
  if (find) {
    BLUETOOTH_RADIO_INFO info = {sizeof(BLUETOOTH_RADIO_INFO)};
    if (BluetoothGetRadioInfo(radio, &info) == ERROR_SUCCESS) {
      result->Success(EncodableValue(AddressToString(info.address)));
    } else {
      result->Success(EncodableValue());
    }
    BluetoothFindRadioClose(find);
    CloseHandle(radio);
  } else {
    result->Success(EncodableValue());
  }
}

void FlutterClassicBluetoothPlugin::HandleStartDiscovery(
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  if (discovering_.load()) {
    result->Success(EncodableValue());
    return;
  }

  discovering_.store(true);

  // Notify Dart that discovery has started
  if (discovery_state_handler_ && discovery_state_handler_->sink()) {
    discovery_state_handler_->sink()->Success(EncodableValue(true));
  }

  // Discovery runs in a background thread — results are sent via event channel
  discovery_thread_ = std::thread([this]() {
    BLUETOOTH_DEVICE_SEARCH_PARAMS search_params = {};
    search_params.dwSize = sizeof(BLUETOOTH_DEVICE_SEARCH_PARAMS);
    search_params.fReturnAuthenticated = TRUE;
    search_params.fReturnRemembered = TRUE;
    search_params.fReturnUnknown = TRUE;
    search_params.fReturnConnected = TRUE;
    search_params.fIssueInquiry = TRUE;
    search_params.cTimeoutMultiplier = 8; // ~10 seconds

    BLUETOOTH_DEVICE_INFO device_info = {};
    device_info.dwSize = sizeof(BLUETOOTH_DEVICE_INFO);

    HBLUETOOTH_DEVICE_FIND find = BluetoothFindFirstDevice(&search_params, &device_info);
    if (find) {
      do {
        if (!discovering_.load()) break;
        if (discovery_results_handler_ && discovery_results_handler_->sink()) {
          discovery_results_handler_->sink()->Success(
              EncodableValue(DeviceToMap(device_info)));
        }
      } while (BluetoothFindNextDevice(find, &device_info));
      BluetoothFindDeviceClose(find);
    }
    discovering_.store(false);
    if (discovery_state_handler_ && discovery_state_handler_->sink()) {
      discovery_state_handler_->sink()->Success(EncodableValue(false));
    }
  });
  discovery_thread_.detach();

  result->Success(EncodableValue());
}

void FlutterClassicBluetoothPlugin::HandleStopDiscovery(
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  discovering_.store(false);
  result->Success(EncodableValue());
}

void FlutterClassicBluetoothPlugin::HandleGetPairedDevices(
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  BLUETOOTH_DEVICE_SEARCH_PARAMS search_params = {};
  search_params.dwSize = sizeof(BLUETOOTH_DEVICE_SEARCH_PARAMS);
  search_params.fReturnAuthenticated = TRUE;
  search_params.fReturnRemembered = TRUE;
  search_params.fReturnUnknown = FALSE;
  search_params.fReturnConnected = TRUE;
  search_params.fIssueInquiry = FALSE;

  BLUETOOTH_DEVICE_INFO device_info = {};
  device_info.dwSize = sizeof(BLUETOOTH_DEVICE_INFO);

  EncodableList devices;
  HBLUETOOTH_DEVICE_FIND find = BluetoothFindFirstDevice(&search_params, &device_info);
  if (find) {
    do {
      if (device_info.fAuthenticated || device_info.fRemembered) {
        devices.push_back(EncodableValue(DeviceToMap(device_info)));
      }
    } while (BluetoothFindNextDevice(find, &device_info));
    BluetoothFindDeviceClose(find);
  }
  result->Success(EncodableValue(devices));
}

void FlutterClassicBluetoothPlugin::HandleBondDevice(
    const EncodableMap& args,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  auto it = args.find(EncodableValue("address"));
  if (it == args.end()) {
    result->Error("invalidAddress", "Address is required", EncodableValue());
    return;
  }
  std::string address = std::get<std::string>(it->second);
  BTH_ADDR bth_addr = StringToAddress(address);

  BLUETOOTH_DEVICE_INFO device_info = {};
  device_info.dwSize = sizeof(BLUETOOTH_DEVICE_INFO);
  device_info.Address.ullLong = bth_addr;

  DWORD auth_result = BluetoothAuthenticateDeviceEx(
      nullptr, nullptr, &device_info, nullptr, MITMProtectionNotRequired);

  result->Success(EncodableValue(auth_result == ERROR_SUCCESS));
}

void FlutterClassicBluetoothPlugin::HandleUnbondDevice(
    const EncodableMap& args,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  auto it = args.find(EncodableValue("address"));
  if (it == args.end()) {
    result->Error("invalidAddress", "Address is required", EncodableValue());
    return;
  }
  std::string address = std::get<std::string>(it->second);
  BTH_ADDR bth_addr = StringToAddress(address);

  BLUETOOTH_ADDRESS bt_addr;
  bt_addr.ullLong = bth_addr;
  DWORD remove_result = BluetoothRemoveDevice(&bt_addr);
  result->Success(EncodableValue(remove_result == ERROR_SUCCESS));
}

void FlutterClassicBluetoothPlugin::HandleConnect(
    const EncodableMap& args,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  auto addr_it = args.find(EncodableValue("address"));
  auto uuid_it = args.find(EncodableValue("uuid"));

  if (addr_it == args.end()) {
    result->Error("connectionFailed", "Address is required", EncodableValue());
    return;
  }

  std::string address = std::get<std::string>(addr_it->second);
  std::string uuid = "00001101-0000-1000-8000-00805F9B34FB";
  if (uuid_it != args.end()) {
    uuid = std::get<std::string>(uuid_it->second);
  }

  BTH_ADDR bth_addr = StringToAddress(address);

  // Connect in background thread
  auto result_ptr = std::shared_ptr<flutter::MethodResult<EncodableValue>>(std::move(result));
  std::thread([this, bth_addr, uuid, address, result_ptr]() {
    SOCKET sock = socket(AF_BTH, SOCK_STREAM, BTHPROTO_RFCOMM);
    if (sock == INVALID_SOCKET) {
      result_ptr->Error("connectionFailed", "Failed to create socket",
                        EncodableValue(EncodableMap{
                            {EncodableValue("address"), EncodableValue(address)}}));
      return;
    }

    SOCKADDR_BTH addr = {};
    addr.addressFamily = AF_BTH;
    addr.btAddr = bth_addr;
    addr.serviceClassId = StringToGuid(uuid);
    addr.port = 0;

    if (connect(sock, (SOCKADDR*)&addr, sizeof(addr)) == SOCKET_ERROR) {
      closesocket(sock);
      result_ptr->Error("connectionFailed", "Failed to connect",
                        EncodableValue(EncodableMap{
                            {EncodableValue("address"), EncodableValue(address)}}));
      return;
    }

    int conn_id;
    {
      std::lock_guard<std::mutex> lock(connections_mutex_);
      conn_id = next_connection_id_++;
      auto connection = std::make_unique<BluetoothConnection>(conn_id, sock, address);
      connection->StartReading(
          [](const std::vector<uint8_t>& data) {
            // Data is delivered via EventChannel on Dart side
          },
          []() {
            // Disconnect notification via EventChannel
          });
      connections_[conn_id] = std::move(connection);
    }

    EncodableMap response;
    response[EncodableValue("id")] = EncodableValue(conn_id);
    response[EncodableValue("address")] = EncodableValue(address);
    result_ptr->Success(EncodableValue(response));
  }).detach();
}

void FlutterClassicBluetoothPlugin::HandleDisconnect(
    const EncodableMap& args,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  auto it = args.find(EncodableValue("id"));
  if (it == args.end()) {
    result->Error("connectionFailed", "Connection ID is required", EncodableValue());
    return;
  }
  int id = std::get<int>(it->second);

  std::lock_guard<std::mutex> lock(connections_mutex_);
  auto conn_it = connections_.find(id);
  if (conn_it != connections_.end()) {
    conn_it->second->Close();
    connections_.erase(conn_it);
  }
  result->Success(EncodableValue());
}

void FlutterClassicBluetoothPlugin::HandleWrite(
    const EncodableMap& args,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  auto id_it = args.find(EncodableValue("id"));
  auto data_it = args.find(EncodableValue("data"));

  if (id_it == args.end() || data_it == args.end()) {
    result->Error("writeFailed", "Connection ID and data are required", EncodableValue());
    return;
  }

  int id = std::get<int>(id_it->second);
  const auto& data = std::get<std::vector<uint8_t>>(data_it->second);

  std::lock_guard<std::mutex> lock(connections_mutex_);
  auto conn_it = connections_.find(id);
  if (conn_it == connections_.end()) {
    result->Error("connectionFailed", "Connection not found", EncodableValue());
    return;
  }

  if (conn_it->second->Write(data)) {
    result->Success(EncodableValue());
  } else {
    result->Error("writeFailed", "Failed to write data", EncodableValue());
  }
}

void FlutterClassicBluetoothPlugin::HandleStartServer(
    const EncodableMap& args,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  std::string uuid = "00001101-0000-1000-8000-00805F9B34FB";
  std::string service_name = "FlutterBluetooth";
  bool secure = true;

  auto uuid_it = args.find(EncodableValue("uuid"));
  if (uuid_it != args.end()) uuid = std::get<std::string>(uuid_it->second);

  auto name_it = args.find(EncodableValue("serviceName"));
  if (name_it != args.end()) service_name = std::get<std::string>(name_it->second);

  auto secure_it = args.find(EncodableValue("secure"));
  if (secure_it != args.end()) secure = std::get<bool>(secure_it->second);

  int server_id;
  {
    std::lock_guard<std::mutex> lock(servers_mutex_);
    server_id = next_server_id_++;
    auto server = std::make_unique<BluetoothServer>(server_id, uuid, service_name, secure);

    bool started = server->Start([this](SOCKET client_socket, const std::string& address) {
      std::lock_guard<std::mutex> lock(connections_mutex_);
      int conn_id = next_connection_id_++;
      auto connection = std::make_unique<BluetoothConnection>(conn_id, client_socket, address);
      connection->StartReading([](const std::vector<uint8_t>&) {}, []() {});
      connections_[conn_id] = std::move(connection);
    });

    if (!started) {
      result->Error("connectionFailed", "Failed to start server", EncodableValue());
      return;
    }

    servers_[server_id] = std::move(server);
  }

  EncodableMap response;
  response[EncodableValue("id")] = EncodableValue(server_id);
  result->Success(EncodableValue(response));
}

void FlutterClassicBluetoothPlugin::HandleStopServer(
    const EncodableMap& args,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  auto it = args.find(EncodableValue("id"));
  if (it == args.end()) {
    result->Error("connectionFailed", "Server ID is required", EncodableValue());
    return;
  }
  int id = std::get<int>(it->second);

  std::lock_guard<std::mutex> lock(servers_mutex_);
  auto server_it = servers_.find(id);
  if (server_it != servers_.end()) {
    server_it->second->Stop();
    servers_.erase(server_it);
  }
  result->Success(EncodableValue());
}

void FlutterClassicBluetoothPlugin::HandleGetPlatformCapabilities(
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  EncodableMap caps;
  caps[EncodableValue("canEnableBluetooth")] = EncodableValue(false);
  caps[EncodableValue("canDisableBluetooth")] = EncodableValue(false);
  caps[EncodableValue("canDiscoverDevices")] = EncodableValue(true);
  caps[EncodableValue("canGetPairedDevices")] = EncodableValue(true);
  caps[EncodableValue("canBondDevices")] = EncodableValue(true);
  caps[EncodableValue("canUnbondDevices")] = EncodableValue(true);
  caps[EncodableValue("canCreateServer")] = EncodableValue(true);
  caps[EncodableValue("canSetDiscoverable")] = EncodableValue(false);
  caps[EncodableValue("supportsMultipleConnections")] = EncodableValue(true);
  caps[EncodableValue("supportsSecureConnection")] = EncodableValue(true);
  caps[EncodableValue("supportsInsecureConnection")] = EncodableValue(true);
  caps[EncodableValue("requiresMfiCertification")] = EncodableValue(false);
  caps[EncodableValue("platformNote")] = EncodableValue(
      std::string("Windows — Bluetooth Classic via Winsock2 AF_BTH. Cannot programmatically enable/disable Bluetooth."));
  result->Success(EncodableValue(caps));
}

}  // namespace flutter_classic_bluetooth
