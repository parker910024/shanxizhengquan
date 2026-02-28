package com.yanshu.app.singbox

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Process
import androidx.annotation.RequiresApi
import androidx.core.content.getSystemService
import io.nekohasekai.libbox.InterfaceUpdateListener
import io.nekohasekai.libbox.Libbox
import io.nekohasekai.libbox.NetworkInterfaceIterator
import io.nekohasekai.libbox.PlatformInterface
import io.nekohasekai.libbox.StringIterator
import io.nekohasekai.libbox.TunOptions
import io.nekohasekai.libbox.WIFIState
import java.net.Inet6Address
import java.net.InetSocketAddress
import java.net.InterfaceAddress
import java.net.NetworkInterface
import io.nekohasekai.libbox.NetworkInterface as LibboxNetworkInterface

class SimplePlatformInterface(private val context: Context) : PlatformInterface {

    private val connectivity by lazy { context.getSystemService<ConnectivityManager>()!! }
    private val wifiManager by lazy { context.getSystemService<WifiManager>()!! }
    private val packageManager by lazy { context.packageManager }

    override fun usePlatformAutoDetectInterfaceControl(): Boolean = true

    override fun autoDetectInterfaceControl(fd: Int) {
    }

    override fun openTun(options: TunOptions?): Int {
        return -1
    }

    override fun useProcFS(): Boolean = Build.VERSION.SDK_INT < Build.VERSION_CODES.Q

    @RequiresApi(Build.VERSION_CODES.Q)
    override fun findConnectionOwner(
        ipProtocol: Int,
        sourceAddress: String?,
        sourcePort: Int,
        destinationAddress: String?,
        destinationPort: Int
    ): Int {
        return try {
            val uid = connectivity.getConnectionOwnerUid(
                ipProtocol,
                InetSocketAddress(sourceAddress, sourcePort),
                InetSocketAddress(destinationAddress, destinationPort)
            )
            if (uid == Process.INVALID_UID) -1 else uid
        } catch (_: Exception) {
            -1
        }
    }

    override fun packageNameByUid(uid: Int): String {
        val packages = packageManager.getPackagesForUid(uid)
        return packages?.firstOrNull() ?: ""
    }

    @Suppress("DEPRECATION")
    override fun uidByPackageName(packageName: String?): Int {
        if (packageName.isNullOrEmpty()) return -1
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                packageManager.getPackageUid(packageName, android.content.pm.PackageManager.PackageInfoFlags.of(0))
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                packageManager.getPackageUid(packageName, 0)
            } else {
                packageManager.getApplicationInfo(packageName, 0).uid
            }
        } catch (_: Exception) {
            -1
        }
    }

    override fun startDefaultInterfaceMonitor(listener: InterfaceUpdateListener?) {
    }

    override fun closeDefaultInterfaceMonitor(listener: InterfaceUpdateListener?) {
    }

    @Suppress("DEPRECATION")
    override fun getInterfaces(): NetworkInterfaceIterator {
        val interfaces = mutableListOf<LibboxNetworkInterface>()
        try {
            val networks = connectivity.allNetworks
            val networkInterfaces = NetworkInterface.getNetworkInterfaces()?.toList() ?: emptyList()

            for (network in networks) {
                val boxInterface = LibboxNetworkInterface()
                val linkProperties = connectivity.getLinkProperties(network) ?: continue
                val networkCapabilities = connectivity.getNetworkCapabilities(network) ?: continue

                boxInterface.name = linkProperties.interfaceName
                val networkInterface = networkInterfaces.find { it.name == boxInterface.name } ?: continue

                boxInterface.dnsServer = StringArray(linkProperties.dnsServers.mapNotNull { it.hostAddress }.iterator())
                boxInterface.type = when {
                    networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> Libbox.InterfaceTypeWIFI
                    networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> Libbox.InterfaceTypeCellular
                    networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> Libbox.InterfaceTypeEthernet
                    else -> Libbox.InterfaceTypeOther
                }
                boxInterface.index = networkInterface.index
                runCatching { boxInterface.mtu = networkInterface.mtu }
                boxInterface.addresses = StringArray(networkInterface.interfaceAddresses.map { it.toPrefix() }.iterator())
                interfaces.add(boxInterface)
            }
        } catch (_: Exception) {
        }
        return InterfaceArray(interfaces.iterator())
    }

    override fun underNetworkExtension(): Boolean = false

    override fun includeAllNetworks(): Boolean = false

    override fun clearDNSCache() {
    }

    @Suppress("DEPRECATION")
    override fun readWIFIState(): WIFIState? {
        return try {
            val wifiInfo = wifiManager.connectionInfo ?: return null
            var ssid = wifiInfo.ssid
            if (ssid == "<unknown ssid>") return WIFIState("", "")
            if (ssid.startsWith("\"") && ssid.endsWith("\"")) {
                ssid = ssid.substring(1, ssid.length - 1)
            }
            WIFIState(ssid, wifiInfo.bssid ?: "")
        } catch (_: Exception) {
            null
        }
    }

    override fun sendNotification(notification: io.nekohasekai.libbox.Notification?) {
    }

    override fun writeLog(message: String?) {
    }

    private class InterfaceArray(private val iterator: Iterator<LibboxNetworkInterface>) : NetworkInterfaceIterator {
        override fun hasNext(): Boolean = iterator.hasNext()
        override fun next(): LibboxNetworkInterface = iterator.next()
    }

    private class StringArray(private val iterator: Iterator<String>) : StringIterator {
        override fun len(): Int = 0
        override fun hasNext(): Boolean = iterator.hasNext()
        override fun next(): String = iterator.next()
    }

    private fun InterfaceAddress.toPrefix(): String {
        return if (address is Inet6Address) {
            "${Inet6Address.getByAddress(address.address).hostAddress}/${networkPrefixLength}"
        } else {
            "${address.hostAddress}/${networkPrefixLength}"
        }
    }
}
