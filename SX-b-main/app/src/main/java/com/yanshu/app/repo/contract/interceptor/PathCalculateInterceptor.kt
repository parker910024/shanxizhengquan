package com.yanshu.app.repo.contract.interceptor

import com.yanshu.app.config.AppConfigCenter
import com.yanshu.app.repo.contract.crypto.AesGcmCrypto
import com.yanshu.app.repo.contract.crypto.CryptoContext
import com.yanshu.app.repo.contract.crypto.CryptoKeyProvider
import com.yanshu.app.repo.contract.crypto.PathCalculator
import ex.ss.lib.components.log.SSLog
import okhttp3.Interceptor
import okhttp3.Response

class PathCalculateInterceptor : Interceptor {

    private val log by lazy { SSLog.create("ContractPathCalculate") }

    override fun intercept(chain: Interceptor.Chain): Response {
        val original = chain.request()
        val existed = original.tag(CryptoContext::class.java)
        val unixString = existed?.unixString ?: AesGcmCrypto.currentUnixString()

        val originalUrl = original.url
        val queryParams = originalUrl.queryParameterNames.associateWith { name ->
            originalUrl.queryParameter(name).orEmpty()
        }

        val masterKey = CryptoKeyProvider.getMasterKey()
        val path = PathCalculator.calculatePath(masterKey, unixString)

        if (AppConfigCenter.enableCryptoLog) {
            log.d("path calculate: ${originalUrl.encodedPath} -> $path")
        }

        val newRequest = original.newBuilder()
            .url(originalUrl.newBuilder().encodedPath(path).build())
            .tag(
                CryptoContext::class.java,
                CryptoContext(
                    unixString = unixString,
                    originalPath = originalUrl.encodedPath,
                    originalMethod = original.method,
                    originalQuery = queryParams,
                )
            )
            .build()

        return chain.proceed(newRequest)
    }
}
