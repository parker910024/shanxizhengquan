package com.yanshu.app.repo

import okhttp3.Interceptor
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.Response
import okhttp3.ResponseBody.Companion.toResponseBody
import org.json.JSONTokener
import java.nio.charset.Charset

/**
 * 修复服务端返回 GBK 等编码导致的乱码：优先尝试 UTF-8，异常或明显乱码时用 GBK，
 * 并将响应体统一转为 UTF-8 供后续拦截器与 Gson 使用。
 */
class ResponseCharsetInterceptor : Interceptor {

    override fun intercept(chain: Interceptor.Chain): Response {
        val response = chain.proceed(chain.request())
        val body = response.body ?: return response
        val contentType = body.contentType() ?: return response

        val bytes = body.bytes()
        val decoded = decodeBytes(bytes, contentType.type, contentType.subtype)
        val mediaType = "${contentType.type}/${contentType.subtype}; charset=utf-8".toMediaType()
        val newBody = decoded.toResponseBody(mediaType)
        return response.newBuilder().body(newBody).build()
    }

    /**
     * 先按 UTF-8 解码；若出现替换符、或为 JSON 但解析失败、或像乱码，则尝试 GBK。
     */
    private fun decodeBytes(bytes: ByteArray, type: String, subtype: String): String {
        val utf8 = String(bytes, Charsets.UTF_8)
        val isJson = type.equals("application", true) && subtype.equals("json", true)

        if (!utf8.contains('\uFFFD') && !looksLikeMojibake(utf8)) {
            if (isJson && !isValidJson(utf8)) {
                return tryGbk(bytes, utf8)
            }
            return utf8
        }
        return tryGbk(bytes, utf8)
    }

    private fun tryGbk(bytes: ByteArray, fallback: String): String {
        return runCatching {
            String(bytes, Charset.forName("GBK"))
        }.getOrElse { fallback }
    }

    private fun looksLikeMojibake(s: String): Boolean {
        if (s.length < 2) return false
        var suspicious = 0
        for (i in 0 until minOf(s.length - 1, 200)) {
            val c = s[i]
            if (c == '\uFFFD') return true
            if (c in '\u00C0'..'\u00FF' && s[i + 1] in '\u0080'..'\u00BF') suspicious++
        }
        return suspicious >= 3
    }

    private fun isValidJson(s: String): Boolean {
        val t = s.trim()
        if (t.isEmpty()) return false
        return try {
            JSONTokener(t).nextValue()
            true
        } catch (_: Exception) {
            false
        }
    }
}
