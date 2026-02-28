package ex.ss.lib.tools.common

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Build
import androidx.annotation.RequiresApi
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.isActive
import kotlinx.coroutines.withContext
import java.io.IOException
import java.net.InetSocketAddress
import java.net.Socket
import java.net.UnknownHostException
import kotlin.coroutines.coroutineContext

object VPNTools {

    const val TIME_OUT_DELAY = Short.MAX_VALUE * 2

    @RequiresApi(Build.VERSION_CODES.M)
    fun hasRunningVPN(context: Context): Boolean {
        val manager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        return manager.activeNetwork?.let {
            manager.getNetworkCapabilities(it)?.let { capabilities ->
                capabilities.hasTransport(NetworkCapabilities.TRANSPORT_VPN) &&
                        capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            } ?: false
        } ?: false
    }

    suspend fun tcping(timeout: Int = 3000, list: List<TCPItem>): Map<String, Int> {
        return withContext(Dispatchers.IO) {
            val result = mutableMapOf<String, Int>()
            SpeedTestUtil.closeAllTcpSockets()
            val deferredList = mutableListOf<Deferred<*>>()
            list.onEach { node ->
                deferredList.add(async {
                    val time = SpeedTestUtil.tcping(node.address, node.port, timeout)
                    val delay = if (time <= -1) TIME_OUT_DELAY else time
                    result.put(node.key, delay)
                })
            }
            deferredList.onEach { it.await() }
            result
        }
    }

}

data class TCPItem(val key: String, val address: String, val port: Int)

object SpeedTestUtil {

    private val tcpTestingSockets = ArrayList<Socket?>()

    suspend fun tcping(url: String, port: Int, timeout: Int): Int {
        var time = -1
        for (k in 0 until 1) {
            val one = socketConnectTime(url, port, timeout)
            if (!coroutineContext.isActive) {
                break
            }
            if (one != -1 && (time == -1 || one < time)) {
                time = one
            }
        }
        return time
    }

    private fun socketConnectTime(url: String, port: Int, timeout: Int): Int {
        try {
            val socket = Socket()
            synchronized(this) {
                tcpTestingSockets.add(socket)
            }
            val start = System.currentTimeMillis()
            socket.connect(InetSocketAddress(url, port), timeout)
            val time = System.currentTimeMillis() - start
            synchronized(this) {
                tcpTestingSockets.remove(socket)
            }
            socket.close()
            return minOf(timeout, time.toInt())
        } catch (e: UnknownHostException) {
            e.printStackTrace()
        } catch (e: IOException) {
            e.printStackTrace()
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return -1
    }

    fun closeAllTcpSockets() {
        synchronized(this) {
            tcpTestingSockets.forEach {
                it?.close()
            }
            tcpTestingSockets.clear()
        }
    }

}