package com.yanshu.app.config

import com.yanshu.app.data.ApiLine
import com.yanshu.app.data.StaticNode

object StaticConfig {
    const val PREFERRED_BASE_URL = "http://192.253.235.176:51000"
    // Playwright proxy server base URL (optional, for EastMoney market/dragon data).
    // Stock detail page already switched to Sina Finance — no proxy needed.
    // Use "http://10.0.2.2:3001" for Android Emulator if market data also needs proxy.
    const val PLAYWRIGHT_PROXY_URL = ""

    val STATIC_LINES = listOf(
        ApiLine("线路1", "https://13.231.202.103:51000"),
        ApiLine("线路2", "https://35.72.5.84:51000"),
    )

    // 代理节点（vless:// 格式）
    val STATIC_NODES = listOf(
        StaticNode("节点1", "vless://b4ea7947-5872-4253-ad9f-ce3464a6e801@183.240.252.113:24846?encryption=none&security=none&type=tcp#node1"),
        StaticNode("节点2", "vless://b4ea7947-5872-4253-ad9f-ce3464a6e801@183.240.252.114:24846?encryption=none&security=none&type=tcp#node2"),
        StaticNode("节点3", "vless://b4ea7947-5872-4253-ad9f-ce3464a6e801@183.240.252.126:24846?encryption=none&security=none&type=tcp#node3"),
        StaticNode("节点4", "vless://b4ea7947-5872-4253-ad9f-ce3464a6e802@183.240.252.126:24846?encryption=none&security=none&type=tcp#node4"),
        StaticNode("节点5", "vless://b4ea7947-5872-4253-ad9f-ce3464a6e803@183.240.252.126:24846?encryption=none&security=none&type=tcp#node5"),
        StaticNode("节点5", "1")
    )

    // 白名单 IP（命中则走代理节点）
    val STATIC_PROXY_IPS = listOf(
        "52.195.189.185",
        "54.250.165.226",
        "52.192.168.3",
        "43.207.198.214",
        "103.45.64.34",
    )

    // 白名单域名
    val STATIC_PROXY_DOMAINS = emptyList<String>()
}
