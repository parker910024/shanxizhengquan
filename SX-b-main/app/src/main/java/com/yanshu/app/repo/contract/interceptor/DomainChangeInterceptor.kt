package com.yanshu.app.repo.contract.interceptor

import com.yanshu.app.config.AppConfigCenter
import com.yanshu.app.repo.contract.dynamic.DynamicDomainConfig
import ex.ss.lib.components.log.SSLog
import okhttp3.HttpUrl
import okhttp3.HttpUrl.Companion.toHttpUrlOrNull
import okhttp3.Interceptor
import okhttp3.Response

class DomainChangeInterceptor : Interceptor {

    private val log by lazy { SSLog.create("ContractDomainChange") }

    override fun intercept(chain: Interceptor.Chain): Response {
        val config = DynamicDomainConfig.featConfig()
        if (!config.success) return chain.proceed(chain.request())

        val oldUrl = chain.request().url
        val newUrl = replaceHttpUrl(oldUrl, config.new)

        if (AppConfigCenter.enableCryptoLog) {
            log.d("domain change: $oldUrl -> ${newUrl ?: oldUrl}")
        }

        val newRequest = if (newUrl != null) {
            chain.request().newBuilder().url(newUrl).build()
        } else {
            chain.request()
        }
        return chain.proceed(newRequest)
    }

    private fun replaceHttpUrl(oldUrl: HttpUrl, newHost: String): HttpUrl? {
        val newHostUrl = newHost.toHttpUrlOrNull() ?: return null
        return oldUrl.newBuilder()
            .scheme(newHostUrl.scheme)
            .host(newHostUrl.host)
            .port(newHostUrl.port)
            .build()
    }
}
