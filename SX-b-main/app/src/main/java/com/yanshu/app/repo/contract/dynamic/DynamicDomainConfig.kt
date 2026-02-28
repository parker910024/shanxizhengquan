package com.yanshu.app.repo.contract.dynamic

import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.proxy.base.config.AppConfig
import com.yanshu.app.config.AppConfigCenter
import ex.ss.lib.components.log.SSLog
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.MainScope
import okhttp3.OkHttpClient
import okhttp3.Request
import java.io.IOException
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference

object DynamicDomainConfig : CoroutineScope by MainScope() {

    private val log by lazy { SSLog.create("ContractDynamicDomain") }
    private val gson by lazy { Gson() }
    private val currentConfig = AtomicReference(DynamicConfig.default())
    private val requestLock = Any()

    private val okHttpClient by lazy {
        OkHttpClient.Builder()
            .connectTimeout(10L, TimeUnit.SECONDS)
            .readTimeout(10L, TimeUnit.SECONDS)
            .writeTimeout(10L, TimeUnit.SECONDS)
            .callTimeout(15L, TimeUnit.SECONDS)
            .build()
    }

    fun featConfig(): DynamicConfig = synchronized(requestLock) {
        val config = currentConfig.get()
        if (config.success) return@synchronized config
        loadConfig()
    }

    fun refreshConfig(): DynamicConfig = synchronized(requestLock) {
        loadConfig()
    }

    fun clearCache() {
        AppConfig.dynamicDomain = ""
        AppConfig.dynamicKey = ""
        currentConfig.set(DynamicConfig.default())
    }

    fun useTestServer(
        domain: String = TEST_SERVER_DOMAIN,
        key: String = TEST_SERVER_KEY,
    ): DynamicConfig {
        val config = DynamicConfig(true, domain, key)
        currentConfig.set(config)
        setCache(config)
        return config
    }

    /**
     * 切换到指定静态线路域名（由 StaticConfigManager.switchLine() 调用）。
     * key 沿用当前缓存值，保持加密逻辑不变。
     */
    fun useStaticLine(url: String): DynamicConfig {
        val key = AppConfig.dynamicKey.ifEmpty { TEST_SERVER_KEY }
        val config = DynamicConfig(true, url, key)
        currentConfig.set(config)
        setCache(config)
        return config
    }

    private fun loadConfig(): DynamicConfig {
        val urls = remoteConfigUrls()
        val config = requestConfig(urls, 0)
        if (config.success) {
            currentConfig.set(config)
            setCache(config)
            return config
        }
        val cache = getCache()
        currentConfig.set(cache)
        return cache
    }

    private fun requestConfig(urls: List<String>, index: Int): DynamicConfig {
        val url = urls.getOrNull(index) ?: return DynamicConfig.default()
        return runCatching {
            val request = Request.Builder().url(url).get().build()
            val response = okHttpClient.newCall(request).execute()
            if (response.code == 200) {
                parseConfig(response.body?.string().orEmpty())
            } else {
                throw IOException("HTTP ${response.code}")
            }
        }.getOrElse {
            if (AppConfigCenter.enableCryptoLog) {
                log.d("requestConfig[$index] failed: ${it.message}")
            }
            requestConfig(urls, index + 1)
        }
    }

    private fun parseConfig(content: String): DynamicConfig = runCatching {
        val type = object : TypeToken<Map<String, String>>() {}.type
        val map = gson.fromJson<Map<String, String>>(content, type)
        val domain = map["new"].orEmpty()
        val key = map["key"].orEmpty()
        if (domain.isNotEmpty()) DynamicConfig(true, domain, key) else DynamicConfig.default()
    }.getOrElse {
        DynamicConfig.default()
    }

    private fun getCache(): DynamicConfig {
        val domain = AppConfig.dynamicDomain
        val key = AppConfig.dynamicKey
        return if (domain.isNotEmpty()) DynamicConfig(true, domain, key) else DynamicConfig.default()
    }

    private fun setCache(dynamicConfig: DynamicConfig) {
        AppConfig.dynamicDomain = dynamicConfig.new
        AppConfig.dynamicKey = dynamicConfig.key
    }

    private fun remoteConfigUrls(): List<String> {
        return listOf(
            "https://shxiongying.oss-cn-shanghai.aliyuncs.com/a.log",
        )
    }

    private const val TEST_SERVER_DOMAIN = "https://13.231.202.103:51000"
    private const val TEST_SERVER_KEY = "123@abc"
}
