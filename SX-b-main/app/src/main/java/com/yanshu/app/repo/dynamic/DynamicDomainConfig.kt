package com.yanshu.app.repo.dynamic

import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.proxy.base.config.AppConfig
import ex.ss.lib.components.log.SSLog
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.MainScope
import okhttp3.OkHttpClient
import okhttp3.Request
import java.io.IOException
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference

object DynamicDomainConfig : CoroutineScope by MainScope() {

    private val log by lazy { SSLog.create("DynamicDomainConfig") }
    private val gson by lazy { Gson() }
    private val okHttpClient by lazy {
        OkHttpClient.Builder().writeTimeout(10L, TimeUnit.SECONDS)
            .readTimeout(10L, TimeUnit.SECONDS).callTimeout(10L, TimeUnit.SECONDS)
            .connectTimeout(10L, TimeUnit.SECONDS).build()
    }

    private val requestLock = Any()
    private val currentConfig = AtomicReference(DynamicConfig.default())

    fun featConfig(): DynamicConfig = synchronized(requestLock) {
        val config = currentConfig.get()
        if (config.success) {
            log.d("featConfig already config")
            return@synchronized config
        }
        log.d("featConfig request config")
        return loadConfig()
    }

    private fun loadConfig(): DynamicConfig {
        val configList = originRemoteConfigAPI()
        val dynamicConfig = requestDynamicConfig(configList, 0, true)
        if (dynamicConfig.success) {
            currentConfig.set(dynamicConfig)
        }
        return currentConfig.get()
    }

    private fun requestDynamicConfig(
        origin: List<String>, index: Int, useCache: Boolean,
    ): DynamicConfig {
        runCatching {
            log.d("getDynamicConfig :${index}")
            val url = origin.getOrNull(index)
            if (url.isNullOrEmpty()) {
                return if (useCache) getCache() else DynamicConfig.default()
            }
            log.d("getDynamicConfig :${url}")
            val request = Request.Builder().url(url).get().build()
            val response = okHttpClient.newCall(request).execute()
            if (response.code == 200) {
                return parseConfig(response.body?.string() ?: "").apply {
                    if (useCache) setCache(this)
                }
            }
            throw IOException("")
        }.getOrElse {
            log.d("getDynamicConfig $it")
            if (index >= origin.size) return DynamicConfig.default()
            log.d("getDynamicConfig next")
            return requestDynamicConfig(origin, index + 1, useCache)
        }
    }

    private fun getCache(): DynamicConfig {
        val dynamicDomain = AppConfig.dynamicDomain
        if (dynamicDomain.isEmpty()) {
            return DynamicConfig(true, dynamicDomain)
        }
        return DynamicConfig.default()
    }

    private fun setCache(dynamicConfig: DynamicConfig) {
        AppConfig.dynamicDomain = dynamicConfig.new
    }

    private fun parseConfig(content: String?): DynamicConfig = runCatching {
        log.d("parseConfig :${content}")
        val type = object : TypeToken<Map<String, String>>() {}.type
        val map = gson.fromJson<Map<String, String>>(content, type)
        val host = map["new"]
        if (!host.isNullOrEmpty()) {
            return@runCatching DynamicConfig(true, host)
        }
        return@runCatching DynamicConfig.default()
    }.getOrElse {
        log.d("parseConfig :${it}")
        return DynamicConfig.default()
    }

    private fun originRemoteConfigAPI(): List<String> {
        return listOf("https://shxiongying.oss-cn-shanghai.aliyuncs.com/a.log")
    }

}
