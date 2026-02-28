package com.yanshu.app.repo.contract.interceptor

import com.google.gson.GsonBuilder
import com.google.gson.JsonParser
import java.io.StringReader
import com.yanshu.app.config.AppConfigCenter
import com.yanshu.app.repo.contract.crypto.AesGcmCrypto
import ex.ss.lib.components.log.SSLog
import okhttp3.Interceptor
import okhttp3.Response
import okhttp3.ResponseBody.Companion.toResponseBody
import org.json.JSONArray
import org.json.JSONObject
import org.json.JSONTokener

class DecryptInterceptor : Interceptor {

    private val log by lazy { SSLog.create("ContractDecrypt") }
    private val logDecrypted by lazy { SSLog.create("RemoteHttp2") }
    private val cipherKeys = listOf("cipher", "ciphertext", "data", "result", "payload")

    override fun intercept(chain: Interceptor.Chain): Response {
        val request = chain.request()
        val response = chain.proceed(request)
        return response.body?.let { body ->
            val contentType = body.contentType()
            val content = body.string()
            val decrypted = when {
                isJson(content) -> tryDecryptJsonFields(content)
                isHtmlError(content) -> content
                else -> tryDecryptWhole(content)
            }
            if (AppConfigCenter.enableCryptoLog) {
                log.d("response plain: $decrypted")
            }
            val path = "${request.method} ${request.url}"
            logDecrypted.d("$path\n${toPrettyJson(decrypted)}")
            response.newBuilder().body(decrypted.toResponseBody(contentType)).build()
        } ?: response
    }

    private fun tryDecryptWhole(text: String): String {
        return runCatching { AesGcmCrypto.decrypt(text) }.getOrElse { text }
    }

    private fun tryDecryptJsonFields(text: String): String {
        val trimmed = text.trimStart()
        if (!trimmed.startsWith("{")) return text
        return runCatching {
            val obj = JSONObject(text)
            var changed = decryptFieldsInObject(obj)
            val data = obj.opt("data")
            if (data is JSONObject && decryptFieldsInObject(data)) {
                obj.put("data", data)
                changed = true
            }
            if (changed) obj.toString() else text
        }.getOrElse { text }
    }

    private fun decryptFieldsInObject(obj: JSONObject): Boolean {
        var changed = false
        for (key in cipherKeys) {
            if (!obj.has(key)) continue
            val value = obj.opt(key)
            if (value !is String) continue
            val decrypted = runCatching { AesGcmCrypto.decrypt(value) }.getOrNull() ?: continue
            obj.put(key, parseJsonValue(decrypted) ?: decrypted)
            changed = true
        }
        return changed
    }

    private fun parseJsonValue(text: String): Any? = runCatching {
        val trimmed = text.trimStart()
        when {
            trimmed.startsWith("{") -> JSONObject(JSONTokener(text))
            trimmed.startsWith("[") -> JSONArray(JSONTokener(text))
            else -> null
        }
    }.getOrNull()

    private fun isJson(text: String): Boolean = runCatching {
        val trimmed = text.trimStart()
        when {
            trimmed.startsWith("{") -> {
                JSONObject(text)
                true
            }

            trimmed.startsWith("[") -> {
                JSONArray(text)
                true
            }

            else -> false
        }
    }.getOrElse { false }

    private fun isHtmlError(text: String): Boolean {
        return text.trimStart().startsWith("<") || text.contains("<html", ignoreCase = true)
    }

    /** 将字符串格式化为 JSON 再打印，便于阅读；非 JSON 则原样输出 */
    private fun toPrettyJson(raw: String): String {
        val trimmed = raw.trim()
        if (trimmed.isEmpty()) return raw
        return runCatching {
            val json = JsonParser().parse(StringReader(raw))
            GsonBuilder().setPrettyPrinting().create().toJson(json)
        }.getOrElse { raw }
    }
}
