#ifndef BLUETOOTH_CONNECTION_H_
#define BLUETOOTH_CONNECTION_H_

#include <flutter_linux/flutter_linux.h>
#include <string>
#include <vector>
#include <thread>
#include <atomic>
#include <functional>
#include <unistd.h>

class BluetoothConnection {
public:
    BluetoothConnection(int id, int socket, const std::string& address)
        : id_(id), socket_(socket), address_(address), running_(false) {}

    ~BluetoothConnection() { Close(); }

    int id() const { return id_; }
    const std::string& address() const { return address_; }

    void StartReading(
        std::function<void(const std::vector<uint8_t>&)> on_data,
        std::function<void()> on_disconnect) {
        running_.store(true);
        std::thread([this, on_data, on_disconnect]() {
            uint8_t buffer[1024];
            while (running_.load()) {
                ssize_t bytes_read = read(socket_, buffer, sizeof(buffer));
                if (bytes_read > 0) {
                    if (on_data) {
                        on_data(std::vector<uint8_t>(buffer, buffer + bytes_read));
                    }
                } else {
                    break;
                }
            }
            running_.store(false);
            if (on_disconnect) on_disconnect();
        }).detach();
    }

    bool Write(const std::vector<uint8_t>& data) {
        if (socket_ < 0) return false;
        ssize_t sent = write(socket_, data.data(), data.size());
        return sent == static_cast<ssize_t>(data.size());
    }

    void Close() {
        running_.store(false);
        if (socket_ >= 0) {
            shutdown(socket_, SHUT_RDWR);
            close(socket_);
            socket_ = -1;
        }
    }

private:
    int id_;
    int socket_;
    std::string address_;
    std::atomic<bool> running_;
};

#endif  // BLUETOOTH_CONNECTION_H_
