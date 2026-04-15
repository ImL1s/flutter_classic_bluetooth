package com.flutter_classic_bluetooth.flutter_classic_bluetooth

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.os.Build

object BluetoothHelper {
    const val NAMESPACE = "flutter_classic_bluetooth"
    const val METHOD_CHANNEL = "$NAMESPACE/methods"
    const val ADAPTER_STATE_CHANNEL = "$NAMESPACE/adapter_state"
    const val DISCOVERY_STATE_CHANNEL = "$NAMESPACE/discovery_state"
    const val DISCOVERY_RESULTS_CHANNEL = "$NAMESPACE/discovery_results"
    const val BOND_STATE_CHANNEL = "$NAMESPACE/bond_state"
    fun connectionChannel(id: Int) = "$NAMESPACE/connection/$id"
    fun connectionStateChannel(id: Int) = "$NAMESPACE/connection_state/$id"
    fun serverChannel(id: Int) = "$NAMESPACE/server/$id"

    const val DEFAULT_UUID = "00001101-0000-1000-8000-00805F9B34FB"

    fun adapterStateToString(state: Int): String = when (state) {
        BluetoothAdapter.STATE_OFF -> "off"
        BluetoothAdapter.STATE_TURNING_ON -> "turningOn"
        BluetoothAdapter.STATE_ON -> "on"
        BluetoothAdapter.STATE_TURNING_OFF -> "turningOff"
        else -> "unknown"
    }

    fun bondStateToString(state: Int): String = when (state) {
        BluetoothDevice.BOND_NONE -> "none"
        BluetoothDevice.BOND_BONDING -> "bonding"
        BluetoothDevice.BOND_BONDED -> "bonded"
        else -> "none"
    }

    @Suppress("MissingPermission")
    fun deviceTypeToString(device: BluetoothDevice): String = when (device.type) {
        BluetoothDevice.DEVICE_TYPE_CLASSIC -> "classic"
        BluetoothDevice.DEVICE_TYPE_DUAL -> "dual"
        BluetoothDevice.DEVICE_TYPE_LE -> "le"
        else -> "unknown"
    }

    @Suppress("MissingPermission")
    fun deviceToMap(device: BluetoothDevice, rssi: Int? = null): Map<String, Any?> {
        val map = mutableMapOf<String, Any?>(
            "address" to device.address,
            "name" to device.name,
            "type" to deviceTypeToString(device),
            "bondState" to bondStateToString(device.bondState),
            "rssi" to rssi,
            "uuids" to (device.uuids?.map { it.uuid.toString() } ?: emptyList<String>()),
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            map["alias"] = device.alias
        }
        return map
    }
}
