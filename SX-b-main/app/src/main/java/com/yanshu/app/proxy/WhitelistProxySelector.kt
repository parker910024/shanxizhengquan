package com.yanshu.app.proxy

import com.yanshu.app.config.StaticConfigManager
import java.io.IOException
import java.net.InetSocketAddress
import java.net.Proxy
import java.net.ProxySelector
import java.net.SocketAddress
import java.net.URI

/**
 * OkHttp 动态代理选择器。
 * 白名单命中 + 代理运行中 → 走 127.0.0.1:10809 本地 HTTP 代理。
 * 其他情况直连。
 */
class WhitelistProxySelector : ProxySelector() {

    private val directList = listOf(Proxy.NO_PROXY)
    private val proxyList by lazy {
        listOf(Proxy(Proxy.Type.HTTP, InetSocketAddress("127.0.0.1", ProxyManager.HTTP_PORT)))
    }

    override fun select(uri: URI?): List<Proxy> {
        if (uri == null) return directList

        val url = uri.toString()
        if (ProxyManager.isRunning() && StaticConfigManager.shouldProxy(url)) {
            return proxyList
        }
        return directList
    }

    override fun connectFailed(uri: URI?, sa: SocketAddress?, ioe: IOException?) {
    }
}
