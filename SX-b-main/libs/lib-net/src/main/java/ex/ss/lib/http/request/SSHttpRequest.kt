package ex.ss.lib.http.request

import com.google.gson.reflect.TypeToken
import okhttp3.MediaType
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.MultipartBody
import okhttp3.RequestBody.Companion.asRequestBody
import java.io.File

class SSHttpRequest<Response> private constructor(
    val type: TypeToken<Response>,
    val path: String,
    val domain: String? = null,
    val method: SSHttpMethod,
    val body: Any? = null,
    val params: Map<String, String> = mapOf(),
    val headers: List<Pair<String, String>> = listOf()
) {

    fun newBuilder(): Builder<Response> {
        return Builder(type, path, domain, method, body, params.toMutableMap(), headers.toMutableList())
    }

    fun getHeader(key: String): String {
        return headers.firstOrNull { it.first == key }?.second ?: ""
    }

    fun getHeaders(key: String): List<String> {
        return headers.filter { it.first == key }.map { it.second }
    }

    class Builder<Response>(
        private val type: TypeToken<Response>,
        private val path: String,
        private var domain: String? = null,
        private val method: SSHttpMethod = SSHttpMethod.NONE,
        private val body: Any? = null,
        private val params: MutableMap<String, String> = mutableMapOf(),
        private val headers: MutableList<Pair<String, String>> = mutableListOf(),
    ) {

        fun domain(domain: String): Builder<Response> {
            this.domain = domain
            return this
        }

        fun addHeader(key: String, value: String): Builder<Response> {
            headers.add(key to value)
            return this
        }

        fun addHeaders(key: String, values: List<String>): Builder<Response> {
            values.onEach { value ->
                headers.add(key to value)
            }
            return this
        }

        fun params(key: String, value: String): Builder<Response> {
            params[key] = value
            return this
        }

        fun get(): SSHttpRequest<Response> {
            return SSHttpRequest(type, path, domain, SSHttpMethod.GET, null, params, headers)
        }

        fun post(body: Any? = null): SSHttpRequest<Response> {
            return SSHttpRequest(type, path, domain, SSHttpMethod.POST, body, params, headers)
        }

        fun upload(files: List<SSHttpFile>): SSHttpRequest<Response> {
            val builder = MultipartBody.Builder().setType(MultipartBody.FORM)
            files.onEach { builder.add(it) }
            val multipartBody = builder.build()
            return post(multipartBody)
        }

        fun rebuild(): SSHttpRequest<Response> {
            check(method != SSHttpMethod.NONE)
            return SSHttpRequest(type, path, domain, method, body, params, headers)
        }

        private fun MultipartBody.Builder.add(httpFile: SSHttpFile): MultipartBody.Builder {
            val file = httpFile.file
            val contentType = httpFile.mediaType ?: file.nameWithoutExtension.toMediaTypeOrNull()
            val requestBody = file.asRequestBody(contentType)
            return addFormDataPart(httpFile.params, file.name, requestBody)
        }
    }
}

data class SSHttpFile(val file: File, val params: String, val mediaType: MediaType? = null)

inline fun <reified T> typeGet(): TypeToken<T> = object : TypeToken<T>() {}

inline fun <reified Response> api(path: String): SSHttpRequest.Builder<Response> {
    return SSHttpRequest.Builder(typeGet<Response>(), path)
}
