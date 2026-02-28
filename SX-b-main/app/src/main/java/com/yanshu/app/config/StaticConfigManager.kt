package com.yanshu.app.config

import com.yanshu.app.data.ApiLine
import com.yanshu.app.data.StaticNode
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.withContext
import java.net.HttpURLConnection
import java.net.URI
import java.net.URL
import java.security.SecureRandom
import java.security.cert.X509Certificate
import javax.net.ssl.HttpsURLConnection
import javax.net.ssl.SSLContext
import javax.net.ssl.TrustManager
import javax.net.ssl.X509TrustManager

object StaticConfigManager {

    private const val TAG = "config_ts"
    private const val PRIMARY_PROBE_TIMEOUT_MS = 1500
    private const val LINE_PROBE_TIMEOUT_MS = 3000

    private var cachedLines: List<ApiLine>? = null
    private var cachedNodes: List<StaticNode>? = null
    private var cachedProxyRules: ProxyRules? = null

    private var isLinesLoaded = false
    private var isNodesLoaded = false
    private var currentLineIndex = 0

    data class ProxyRules(
        val ips: List<String>,
        val domains: List<String>
    )

    suspend fun loadLines(): Boolean = withContext(Dispatchers.IO) {
        android.util.Log.d(TAG, "===== load lines =====")
        val allLines = StaticConfig.STATIC_LINES
        android.util.Log.d(TAG, "static line count: ${allLines.size}")

        if (allLines.isEmpty()) {
            cachedLines = emptyList()
            isLinesLoaded = true
            currentLineIndex = 0
            android.util.Log.w(TAG, "line list is empty")
            return@withContext false
        }

        val checkResults = allLines.map { line ->
            async {
                val available = checkLineAvailable(line.url, LINE_PROBE_TIMEOUT_MS)
                line to available
            }
        }.awaitAll()

        cachedLines = checkResults
            .sortedByDescending { it.second }
            .map { it.first }

        isLinesLoaded = true
        currentLineIndex = 0
        cachedLines?.firstOrNull()?.let { line ->
            com.yanshu.app.repo.contract.dynamic.DynamicDomainConfig.useStaticLine(line.url)
            android.util.Log.d(TAG, "active line: ${line.name} -> ${line.url}")
        }

        cachedLines?.forEachIndexed { i, line ->
            android.util.Log.d(TAG, "line[$i]: ${line.name} -> ${line.url}")
        }

        cachedLines!!.isNotEmpty()
    }

    suspend fun loadNodes(): Boolean {
        cachedNodes = StaticConfig.STATIC_NODES
        isNodesLoaded = true
        android.util.Log.d(TAG, "===== load nodes =====")
        android.util.Log.d(TAG, "node count: ${cachedNodes!!.size}")
        cachedNodes?.forEachIndexed { i, node ->
            val masked = node.url.take(50) + "..."
            android.util.Log.d(TAG, "node[$i]: ${node.name} -> $masked")
        }
        return cachedNodes!!.isNotEmpty()
    }

    suspend fun loadProxyRules(): Boolean {
        cachedProxyRules = ProxyRules(
            StaticConfig.STATIC_PROXY_IPS,
            StaticConfig.STATIC_PROXY_DOMAINS
        )
        android.util.Log.d(TAG, "===== load whitelist =====")
        android.util.Log.d(TAG, "whitelist ips: ${cachedProxyRules!!.ips.size}")
        cachedProxyRules!!.ips.forEach { ip ->
            android.util.Log.d(TAG, "ip: $ip")
        }
        android.util.Log.d(TAG, "whitelist domains: ${cachedProxyRules!!.domains.size}")
        cachedProxyRules!!.domains.forEach { domain ->
            android.util.Log.d(TAG, "domain: $domain")
        }
        return true
    }

    fun getLines(): List<ApiLine> = cachedLines ?: emptyList()

    fun getNodes(): List<StaticNode> = cachedNodes ?: emptyList()

    fun getProxyRules(): ProxyRules = cachedProxyRules ?: ProxyRules(emptyList(), emptyList())

    fun getCurrentLine(): ApiLine? = getLines().getOrNull(currentLineIndex)

    fun switchLine(index: Int) {
        val lines = getLines()
        if (index < 0 || index >= lines.size) {
            android.util.Log.w(TAG, "switch line failed: index=$index out of range")
            return
        }
        currentLineIndex = index
        val line = lines[index]
        android.util.Log.d(TAG, "switch line[$index]: ${line.name} -> ${line.url}")
        com.yanshu.app.repo.contract.dynamic.DynamicDomainConfig.useStaticLine(line.url)
    }

    fun switchLine(line: ApiLine) {
        val index = getLines().indexOf(line)
        android.util.Log.d(TAG, "switch by ApiLine: ${line.name}, index=$index")
        if (index >= 0) switchLine(index)
    }

    fun shouldProxy(url: String): Boolean {
        val rules = getProxyRules()
        val host = extractHost(url)
        android.util.Log.d(
            TAG,
            "whitelist check: url=$url, host=$host, ruleIp=${rules.ips.size}, ruleDomain=${rules.domains.size}"
        )
        if (rules.ips.isEmpty() && rules.domains.isEmpty()) {
            android.util.Log.d(TAG, "no whitelist rules, do not proxy")
            return false
        }

        rules.domains.forEach { domain ->
            if (host.contains(domain, ignoreCase = true) || url.contains(domain, ignoreCase = true)) {
                android.util.Log.d(TAG, "hit domain whitelist: $domain")
                return true
            }
        }

        rules.ips.forEach { ip ->
            if (host == ip || url.contains(ip)) {
                android.util.Log.d(TAG, "hit ip whitelist: $ip")
                return true
            }
        }

        android.util.Log.d(TAG, "whitelist miss, do not proxy")
        return false
    }

    fun isLinesLoaded(): Boolean = isLinesLoaded

    fun isNodesLoaded(): Boolean = isNodesLoaded

    fun clearCache() {
        cachedLines = null
        cachedNodes = null
        cachedProxyRules = null
        isLinesLoaded = false
        isNodesLoaded = false
        currentLineIndex = 0
    }

    private suspend fun checkLineAvailable(
        url: String,
        timeoutMs: Int = 5000,
    ): Boolean = withContext(Dispatchers.IO) {
        probeWithMethod(url, "HEAD", timeoutMs)
            ?: probeWithMethod(url, "GET", timeoutMs)
            ?: false
    }

    private fun probeWithMethod(url: String, method: String, timeoutMs: Int): Boolean? {
        return try {
            val connection = URL(url).openConnection() as HttpURLConnection
            connection.connectTimeout = timeoutMs
            connection.readTimeout = timeoutMs
            connection.requestMethod = method
            connection.instanceFollowRedirects = true

            if (connection is HttpsURLConnection) {
                val trustAll = arrayOf<TrustManager>(object : X509TrustManager {
                    override fun checkClientTrusted(chain: Array<X509Certificate>, authType: String) {}
                    override fun checkServerTrusted(chain: Array<X509Certificate>, authType: String) {}
                    override fun getAcceptedIssuers(): Array<X509Certificate> = emptyArray()
                })
                val sslCtx = SSLContext.getInstance("TLS")
                sslCtx.init(null, trustAll, SecureRandom())
                connection.sslSocketFactory = sslCtx.socketFactory
                connection.hostnameVerifier = javax.net.ssl.HostnameVerifier { _, _ -> true }
            }

            val code = connection.responseCode
            val finalUrl = connection.url?.toString() ?: url
            connection.disconnect()

            if (method == "HEAD" && code == HttpURLConnection.HTTP_BAD_METHOD) {
                android.util.Log.d(TAG, "probe HEAD not allowed: $url")
                null
            } else {
                val reachable = code in 100..599
                android.util.Log.d(TAG, "probe $method: $url -> HTTP $code final=$finalUrl reachable=$reachable")
                reachable
            }
        } catch (e: Exception) {
            android.util.Log.d(TAG, "probe $method exception: $url -> ${e.javaClass.simpleName}: ${e.message}")
            false
        }
    }

    private fun extractHost(url: String): String {
        return try {
            URI(url).host ?: url
        } catch (_: Exception) {
            url.removePrefix("http://")
                .removePrefix("https://")
                .substringBefore("/")
                .substringBefore(":")
        }
    }
}
