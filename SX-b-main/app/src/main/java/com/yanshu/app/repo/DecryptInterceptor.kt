package com.yanshu.app.repo

import ex.ss.lib.components.log.SSLog
import ex.ss.lib.tools.cipher.AESKeys
import ex.ss.lib.tools.cipher.AESTools
import okhttp3.Interceptor
import okhttp3.Response
import okhttp3.ResponseBody.Companion.toResponseBody
import org.json.JSONObject

class DecryptInterceptor : Interceptor {
    /**
     * key:778876b7d1b35adev5c640g33df44ttd
     * iv:5a6a7e361a4c8877
     */
    private val keys by lazy { AESKeys("778876b7d1b35adev5c640g33df44ttd", "5a6a7e361a4c8877") }

    private val log by lazy { SSLog.create("RemoteHttp") }

    override fun intercept(chain: Interceptor.Chain): Response {
        val response = chain.proceed(chain.request())
        return response.body?.let { responseBody ->
            val contentType = responseBody.contentType()
            val responseString = responseBody.string()
            val decryptString = if (isJson(responseString)) {
                responseString
            } else {
                runCatching {
                    AESTools.decryptString(responseString, keys)
                }.getOrElse { e ->
                    // 解密失败（如服务端返回明文 JSON、密钥不一致等）则原样返回，避免 IllegalBlockSizeException 弹窗
                    log.d("decrypt failed, use raw: ${e.message}")
                    responseString
                }
            }
            log.d(decryptString)
            response.newBuilder().body(decryptString.toResponseBody(contentType)).build()
        } ?: response
    }

    private fun isJson(text: String): Boolean = runCatching {
        JSONObject(text)
        true
    }.getOrElse { false }

}