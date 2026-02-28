package com.yanshu.app.repo.contract.interceptor

import com.yanshu.app.config.AppConfigCenter
import com.yanshu.app.config.UserConfig
import com.yanshu.app.repo.contract.crypto.AesGcmCrypto
import com.yanshu.app.repo.contract.crypto.CryptoContext
import ex.ss.lib.components.log.SSLog
import okhttp3.Interceptor
import okhttp3.MediaType
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.Response
import okio.Buffer
import org.json.JSONArray
import org.json.JSONObject
import org.json.JSONTokener

class RequestEncryptInterceptor : Interceptor {

    private val log by lazy { SSLog.create("ContractRequestEncrypt") }

    override fun intercept(chain: Interceptor.Chain): Response {
        val request = chain.request()
        val body = request.body
        val contentType = body?.contentType()

        if (shouldSkip(contentType)) {
            return chain.proceed(request)
        }

        val context = request.tag(CryptoContext::class.java)
        val unixString = context?.unixString ?: AesGcmCrypto.currentUnixString()
        val originalPath = context?.originalPath ?: request.url.encodedPath
        val originalMethod = context?.originalMethod ?: request.method

        val params = mutableMapOf<String, Any?>()
        val queryParams = context?.originalQuery ?: request.url.queryParameterNames.associateWith { name ->
            request.url.queryParameter(name).orEmpty()
        }
        params.putAll(queryParams)

        val rawBody = body?.let {
            val buffer = Buffer()
            it.writeTo(buffer)
            buffer.readUtf8()
        }.orEmpty()

        parseRequestBody(rawBody)?.also { parsed ->
            when (parsed) {
                is JSONObject -> parsed.keys().forEach { key -> params[key] = parsed.opt(key) }
                is JSONArray -> params["body"] = parsed
                else -> params["body"] = parsed
            }
        }

        val wrapperJson = JSONObject().apply {
            put("url", originalPath)
            put("method", originalMethod)
            put("param", JSONObject(params))
            put("token", UserConfig.token)
        }.toString()

        if (AppConfigCenter.enableCryptoLog) {
            log.d("request plain: $wrapperJson")
        }

        val encrypted = AesGcmCrypto.encryptWithUnixString(wrapperJson, unixString)
        val newBody = encrypted.toRequestBody("text/plain; charset=utf-8".toMediaType())
        val newUrl = request.url.newBuilder().query(null).build()

        val newRequest = request.newBuilder()
            .url(newUrl)
            .method("POST", newBody)
            .tag(
                CryptoContext::class.java,
                CryptoContext(
                    unixString = unixString,
                    originalPath = originalPath,
                    originalMethod = originalMethod,
                    originalQuery = queryParams,
                )
            )
            .build()
        return chain.proceed(newRequest)
    }

    private fun shouldSkip(contentType: MediaType?): Boolean {
        if (contentType == null) return false
        if (contentType.type.equals("multipart", ignoreCase = true)) return true
        if (contentType.subtype.equals("form-data", ignoreCase = true)) return true
        if (contentType.type.equals("image", ignoreCase = true)) return true
        if (contentType.subtype.equals("octet-stream", ignoreCase = true)) return true
        return false
    }

    private fun parseRequestBody(body: String): Any? {
        val trimmed = body.trim()
        if (trimmed.isEmpty()) return null
        return runCatching {
            when {
                trimmed.startsWith("{") -> JSONObject(JSONTokener(trimmed))
                trimmed.startsWith("[") -> JSONArray(JSONTokener(trimmed))
                else -> trimmed
            }
        }.getOrNull()
    }
}
