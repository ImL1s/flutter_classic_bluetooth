#include "bluetooth_server.h"
#include "bluetooth_helper.h"

namespace flutter_classic_bluetooth {

BluetoothServer::BluetoothServer(int id, const std::string& uuid,
                                 const std::string& service_name, bool secure)
    : id_(id), uuid_(uuid), service_name_(service_name), secure_(secure) {}

BluetoothServer::~BluetoothServer() {
  Stop();
}

bool BluetoothServer::Start(std::function<void(SOCKET, const std::string&)> on_connection) {
  server_socket_ = socket(AF_BTH, SOCK_STREAM, BTHPROTO_RFCOMM);
  if (server_socket_ == INVALID_SOCKET) return false;

  SOCKADDR_BTH addr = {};
  addr.addressFamily = AF_BTH;
  addr.btAddr = 0;
  addr.serviceClassId = StringToGuid(uuid_);
  addr.port = BT_PORT_ANY;

  if (bind(server_socket_, (SOCKADDR*)&addr, sizeof(addr)) == SOCKET_ERROR) {
    closesocket(server_socket_);
    server_socket_ = INVALID_SOCKET;
    return false;
  }

  if (listen(server_socket_, 5) == SOCKET_ERROR) {
    closesocket(server_socket_);
    server_socket_ = INVALID_SOCKET;
    return false;
  }

  running_.store(true);
  accept_thread_ = std::thread([this, on_connection]() {
    while (running_.load()) {
      SOCKADDR_BTH client_addr = {};
      int addr_len = sizeof(client_addr);
      SOCKET client = accept(server_socket_, (SOCKADDR*)&client_addr, &addr_len);
      if (client == INVALID_SOCKET) break;

      BLUETOOTH_ADDRESS bt_addr;
      bt_addr.ullLong = client_addr.btAddr;
      std::string address = AddressToString(bt_addr);
      on_connection(client, address);
    }
  });
  accept_thread_.detach();
  return true;
}

void BluetoothServer::Stop() {
  running_.store(false);
  if (server_socket_ != INVALID_SOCKET) {
    closesocket(server_socket_);
    server_socket_ = INVALID_SOCKET;
  }
}

}  // namespace flutter_classic_bluetooth
