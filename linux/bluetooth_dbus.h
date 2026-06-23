#ifndef BLUETOOTH_DBUS_H_
#define BLUETOOTH_DBUS_H_

#include <flutter_linux/flutter_linux.h>
#include <gio/gio.h>
#include <climits>
#include <string>

#include "bluetooth_helper.h"

// Helpers that talk to BlueZ over its D-Bus API (org.bluez) for the operations
// the raw HCI socket interface cannot do: adapter power on/off, paired-device
// enumeration, and pairing / unpairing. All calls are synchronous and
// best-effort — they return false / no-op if BlueZ or the system bus is
// unavailable, so the raw-HCI code paths remain the source of truth for
// discovery, connect and server.

// BlueZ adapter object path for hci<dev_id>, e.g. "/org/bluez/hci0".
inline std::string dbus_adapter_path(int dev_id) {
    return "/org/bluez/hci" + std::to_string(dev_id >= 0 ? dev_id : 0);
}

// BlueZ device object path, e.g. "/org/bluez/hci0/dev_AA_BB_CC_DD_EE_FF".
inline std::string dbus_device_path(int dev_id, const char* address) {
    std::string path = dbus_adapter_path(dev_id) + "/dev_";
    for (const char* p = address; *p; ++p) {
        char c = *p;
        if (c == ':') c = '_';
        else if (c >= 'a' && c <= 'f') c = static_cast<char>(c - 'a' + 'A');
        path += c;
    }
    return path;
}

// Sets the adapter's Powered property (enable/disable Bluetooth).
inline bool dbus_set_adapter_powered(int dev_id, bool powered) {
    GError* error = nullptr;
    GDBusConnection* bus = g_bus_get_sync(G_BUS_TYPE_SYSTEM, nullptr, &error);
    if (!bus) { if (error) g_error_free(error); return false; }

    std::string path = dbus_adapter_path(dev_id);
    GVariant* ret = g_dbus_connection_call_sync(
        bus, "org.bluez", path.c_str(),
        "org.freedesktop.DBus.Properties", "Set",
        g_variant_new("(ssv)", "org.bluez.Adapter1", "Powered",
                      g_variant_new_boolean(powered)),
        nullptr, G_DBUS_CALL_FLAGS_NONE, -1, nullptr, &error);

    bool ok = ret != nullptr;
    if (ret) g_variant_unref(ret);
    if (error) g_error_free(error);
    g_object_unref(bus);
    return ok;
}

// Calls org.bluez.Device1.Pair. Succeeds for "just works"/SSP devices; devices
// requiring a PIN/passkey need a registered agent and may fail.
inline bool dbus_pair_device(int dev_id, const char* address) {
    GError* error = nullptr;
    GDBusConnection* bus = g_bus_get_sync(G_BUS_TYPE_SYSTEM, nullptr, &error);
    if (!bus) { if (error) g_error_free(error); return false; }

    std::string path = dbus_device_path(dev_id, address);
    GVariant* ret = g_dbus_connection_call_sync(
        bus, "org.bluez", path.c_str(),
        "org.bluez.Device1", "Pair", nullptr, nullptr,
        G_DBUS_CALL_FLAGS_NONE, 30000, nullptr, &error);

    bool ok = ret != nullptr;
    if (ret) g_variant_unref(ret);
    if (error) g_error_free(error);
    g_object_unref(bus);
    return ok;
}

// Calls org.bluez.Adapter1.RemoveDevice (unpair).
inline bool dbus_remove_device(int dev_id, const char* address) {
    GError* error = nullptr;
    GDBusConnection* bus = g_bus_get_sync(G_BUS_TYPE_SYSTEM, nullptr, &error);
    if (!bus) { if (error) g_error_free(error); return false; }

    std::string adapter = dbus_adapter_path(dev_id);
    std::string dev = dbus_device_path(dev_id, address);
    GVariant* ret = g_dbus_connection_call_sync(
        bus, "org.bluez", adapter.c_str(),
        "org.bluez.Adapter1", "RemoveDevice",
        g_variant_new("(o)", dev.c_str()),
        nullptr, G_DBUS_CALL_FLAGS_NONE, -1, nullptr, &error);

    bool ok = ret != nullptr;
    if (ret) g_variant_unref(ret);
    if (error) g_error_free(error);
    g_object_unref(bus);
    return ok;
}

// Appends every paired org.bluez.Device1 to `devices` (an FlValue list) using
// device_to_map(), via the standard ObjectManager.GetManagedObjects pattern.
inline void dbus_append_paired_devices(FlValue* devices) {
    GError* error = nullptr;
    GDBusConnection* bus = g_bus_get_sync(G_BUS_TYPE_SYSTEM, nullptr, &error);
    if (!bus) { if (error) g_error_free(error); return; }

    GVariant* ret = g_dbus_connection_call_sync(
        bus, "org.bluez", "/",
        "org.freedesktop.DBus.ObjectManager", "GetManagedObjects",
        nullptr, G_VARIANT_TYPE("(a{oa{sa{sv}}})"),
        G_DBUS_CALL_FLAGS_NONE, -1, nullptr, &error);
    if (!ret) {
        if (error) g_error_free(error);
        g_object_unref(bus);
        return;
    }

    GVariantIter* objects = nullptr;
    g_variant_get(ret, "(a{oa{sa{sv}}})", &objects);
    const gchar* obj_path = nullptr;
    GVariantIter* interfaces = nullptr;
    while (g_variant_iter_loop(objects, "{&oa{sa{sv}}}", &obj_path, &interfaces)) {
        const gchar* iface = nullptr;
        GVariantIter* props = nullptr;
        while (g_variant_iter_loop(interfaces, "{&sa{sv}}", &iface, &props)) {
            if (g_strcmp0(iface, "org.bluez.Device1") != 0) continue;

            const gchar* key = nullptr;
            GVariant* value = nullptr;
            std::string address;
            std::string name;
            bool paired = false;
            int rssi = INT_MIN;
            while (g_variant_iter_loop(props, "{&sv}", &key, &value)) {
                if (g_strcmp0(key, "Address") == 0) {
                    address = g_variant_get_string(value, nullptr);
                } else if (g_strcmp0(key, "Name") == 0) {
                    name = g_variant_get_string(value, nullptr);
                } else if (g_strcmp0(key, "Paired") == 0) {
                    paired = g_variant_get_boolean(value);
                } else if (g_strcmp0(key, "RSSI") == 0) {
                    rssi = g_variant_get_int16(value);
                }
            }
            if (paired && !address.empty()) {
                fl_value_append_take(devices,
                    device_to_map(address.c_str(),
                                  name.empty() ? nullptr : name.c_str(),
                                  true, rssi));
            }
        }
    }

    g_variant_iter_free(objects);
    g_variant_unref(ret);
    g_object_unref(bus);
}

#endif  // BLUETOOTH_DBUS_H_
