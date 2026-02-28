package com.yanshu.app.repo

import com.yanshu.app.BuildConfig
import com.yanshu.app.repo.dynamic.DynamicConfig
import com.yanshu.app.repo.dynamic.DynamicDomainConfig
import ex.ss.lib.components.log.SSLog
import okhttp3.HttpUrl
import okhttp3.HttpUrl.Companion.toHttpUrlOrNull
import okhttp3.Interceptor
import okhttp3.Response

class DomainChangeInterceptor : Interceptor {

    private val log by lazy { SSLog.create("DomainChangeInterceptor") }

    private val dynamicConfig by lazy {
        DynamicConfig(
            true,
            "${BuildConfig.BASE_URL}/bbnsb567-t85i-1l7b-99yz-z123wxy88ffz/"
        )
    }

    override fun intercept(chain: Interceptor.Chain): Response {
        return retryProceed(chain) {
            val request = chain.request().newBuilder().url(it).build()
            chain.proceed(request)
        }
    }

    private fun retryProceed(chain: Interceptor.Chain, onProceed: (HttpUrl) -> Response): Response {
        val config = DynamicDomainConfig.featConfig()
//        val config = dynamicConfig
        return if (config.success) {
            // 移除了 VPNProxy.setRouterConfiguration(config.new)
            val httpUrl = replaceHttpUrl(chain.request().url, config.new, BuildConfig.BASE_URL)
            log.d("replaceHttpUrl - oldUrl : ${chain.request().url} newHost : ${config.new} baseHost : ${BuildConfig.BASE_URL} newHttpUrl:$httpUrl")
            if (httpUrl != null) {
                onProceed(httpUrl)
            } else {
                onProceed(chain.request().url)
            }
        } else {
            onProceed(chain.request().url)
        }
    }

    private fun replaceHttpUrl(oldHttpUrl: HttpUrl?, newHost: String, baseHost: String): HttpUrl? {
        val newBuild = oldHttpUrl?.newBuilder()
        newHost.toHttpUrlOrNull()?.also { new ->
            // 移除所有路径段
            oldHttpUrl?.pathSegments?.onEach { newBuild?.removePathSegment(0) }
            // 替换新的 scheme
            newBuild?.scheme(new.scheme)
            // 替换新的 host
            newBuild?.host(new.host)
            // 替换新的 port
            newBuild?.port(new.port)
            // 添加新的 host 路径段
            new.pathSegments.filter { item -> item.isNotEmpty() }
                .onEach { path -> newBuild?.addPathSegment(path) }
            // 移除旧 host 路径段并添加剩余路径段
            oldHttpUrl?.pathSegments?.filter { path ->
                baseHost.toHttpUrlOrNull()?.pathSegments?.contains(path) != true
            }?.filter { item -> item.isNotEmpty() }
                ?.onEach { path -> newBuild?.addPathSegment(path) }
        }
        return newBuild?.build()
    }
}