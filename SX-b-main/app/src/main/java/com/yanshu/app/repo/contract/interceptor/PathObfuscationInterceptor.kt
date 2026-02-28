package com.yanshu.app.repo.contract.interceptor

import com.yanshu.app.config.AppConfigCenter
import com.yanshu.app.repo.contract.crypto.PathObfuscator
import ex.ss.lib.components.log.SSLog
import okhttp3.Interceptor
import okhttp3.Response

class PathObfuscationInterceptor : Interceptor {

    private val log by lazy { SSLog.create("ContractPathObfuscation") }

    override fun intercept(chain: Interceptor.Chain): Response {
        val request = chain.request()
        val originalPath = request.url.encodedPath
        val obfuscated = PathObfuscator.confusePath(originalPath)

        if (AppConfigCenter.enableCryptoLog) {
            log.d("path obfuscation: $originalPath -> $obfuscated")
        }

        val newRequest = request.newBuilder()
            .url(request.url.newBuilder().encodedPath(obfuscated).build())
            .build()
        return chain.proceed(newRequest)
    }
}
