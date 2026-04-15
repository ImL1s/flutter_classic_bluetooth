#ifndef FLUTTER_PLUGIN_BLUETOOTH_HELPER_H_
#define FLUTTER_PLUGIN_BLUETOOTH_HELPER_H_

#include <windows.h>
#include <ws2bth.h>
#include <BluetoothAPIs.h>

#include <flutter/encodable_value.h>
#include <string>
#include <sstream>
#include <iomanip>

namespace flutter_classic_bluetooth {

inline std::string WideToUtf8(const std::wstring& wide) {
    if (wide.empty()) return "";
    int size = WideCharToMultiByte(CP_UTF8, 0, wide.c_str(), -1, nullptr, 0, nullptr, nullptr);
    std::string result(size - 1, 0);
    WideCharToMultiByte(CP_UTF8, 0, wide.c_str(), -1, &result[0], size, nullptr, nullptr);
    return result;
}

inline std::wstring Utf8ToWide(const std::string& utf8) {
    if (utf8.empty()) return L"";
    int size = MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(), -1, nullptr, 0);
    std::wstring result(size - 1, 0);
    MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(), -1, &result[0], size);
    return result;
}

inline std::string AddressToString(const BLUETOOTH_ADDRESS& addr) {
    std::ostringstream ss;
    ss << std::hex << std::uppercase << std::setfill('0');
    for (int i = 5; i >= 0; --i) {
        ss << std::setw(2) << static_cast<int>(addr.rgBytes[i]);
        if (i > 0) ss << ":";
    }
    return ss.str();
}

inline BTH_ADDR StringToAddress(const std::string& str) {
    BTH_ADDR addr = 0;
    unsigned int bytes[6];
    if (sscanf_s(str.c_str(), "%02X:%02X:%02X:%02X:%02X:%02X",
                 &bytes[0], &bytes[1], &bytes[2], &bytes[3], &bytes[4], &bytes[5]) == 6) {
        for (int i = 0; i < 6; ++i) {
            addr = (addr << 8) | bytes[i];
        }
    }
    return addr;
}

inline GUID StringToGuid(const std::string& uuid) {
    GUID guid = {};
    unsigned int d[11];
    if (sscanf_s(uuid.c_str(),
                 "%08X-%04X-%04X-%02X%02X-%02X%02X%02X%02X%02X%02X",
                 &d[0], &d[1], &d[2], &d[3], &d[4],
                 &d[5], &d[6], &d[7], &d[8], &d[9], &d[10]) == 11) {
        guid.Data1 = d[0];
        guid.Data2 = (unsigned short)d[1];
        guid.Data3 = (unsigned short)d[2];
        guid.Data4[0] = (unsigned char)d[3];
        guid.Data4[1] = (unsigned char)d[4];
        guid.Data4[2] = (unsigned char)d[5];
        guid.Data4[3] = (unsigned char)d[6];
        guid.Data4[4] = (unsigned char)d[7];
        guid.Data4[5] = (unsigned char)d[8];
        guid.Data4[6] = (unsigned char)d[9];
        guid.Data4[7] = (unsigned char)d[10];
    }
    return guid;
}

inline flutter::EncodableMap DeviceToMap(const BLUETOOTH_DEVICE_INFO& info, int rssi = 0) {
    flutter::EncodableMap map;
    BLUETOOTH_ADDRESS addr;
    addr.ullLong = info.Address.ullLong;
    map[flutter::EncodableValue("address")] = flutter::EncodableValue(AddressToString(addr));
    map[flutter::EncodableValue("name")] = flutter::EncodableValue(WideToUtf8(info.szName));
    map[flutter::EncodableValue("type")] = flutter::EncodableValue("unknown");

    std::string bondState = info.fAuthenticated ? "bonded" : "none";
    map[flutter::EncodableValue("bondState")] = flutter::EncodableValue(bondState);
    map[flutter::EncodableValue("rssi")] = flutter::EncodableValue(rssi);
    map[flutter::EncodableValue("uuids")] = flutter::EncodableValue(flutter::EncodableList());
    return map;
}

}  // namespace flutter_classic_bluetooth

#endif  // FLUTTER_PLUGIN_BLUETOOTH_HELPER_H_
