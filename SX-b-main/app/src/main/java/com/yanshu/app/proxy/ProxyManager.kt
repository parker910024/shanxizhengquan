package com.yanshu.app.proxy

import android.content.Context
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import com.yanshu.app.config.StaticConfigManager
import com.yanshu.app.singbox.Callback
import com.yanshu.app.singbox.VPNManager
import com.yanshu.app.singbox.VlessToSingboxConverter

object ProxyManager {

    const val HTTP_PORT = VlessToSingboxConverter.HTTP_PORT
    const val SOCKS_PORT = VlessToSingboxConverter.SOCKS_PORT

    const val K_Disconnected = Callback.K_Disconnected
    const val K_Connecting = Callback.K_Connecting
    const val K_Connected = Callback.K_Connected

    private val _statusLiveData: MutableLiveData<Int> = MutableLiveData(Callback.K_Disconnected)
    val statusLiveData: LiveData<Int> = _statusLiveData

    private var context: Context? = null

    fun init(context: Context) {
        this.context = context.applicationContext

        VPNManager.sharedManager().setApplicationContext(context)
        VPNManager.sharedManager().setVPNConectionStatusCallback(object : Callback {
            override fun connectionStatusDidChange(status: Int) {
                _statusLiveData.postValue(status)
            }
            override fun onPingResponse(rtt: Int, uri: String?) {}
        })
    }

    fun startProxyWithUrl(nodeUrl: String) {
        try {
            val proxyRules = StaticConfigManager.getProxyRules()
            val configJson = VlessToSingboxConverter.convert(nodeUrl, proxyRules)

            _statusLiveData.postValue(K_Connecting)
            VPNManager.sharedManager().startTunnel(configJson)
        } catch (_: Exception) {
            _statusLiveData.postValue(K_Disconnected)
        }
    }

    fun stopProxy() {
        VPNManager.sharedManager().stopTunnel()
    }

    fun changeNode(nodeUrl: String) {
        if (isRunning()) {
            stopProxy()
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                startProxyWithUrl(nodeUrl)
            }, 500)
        } else {
            startProxyWithUrl(nodeUrl)
        }
    }

    fun getHttpProxyAddress(): String = "127.0.0.1:$HTTP_PORT"

    fun isRunning(): Boolean {
        return checkPort(HTTP_PORT)
    }

    private fun checkPort(port: Int): Boolean {
        return try {
            java.net.Socket().use { socket ->
                socket.connect(java.net.InetSocketAddress("127.0.0.1", port), 100)
                true
            }
        } catch (_: Exception) {
            false
        }
    }

    fun release() {
        stopProxy()
    }
}
