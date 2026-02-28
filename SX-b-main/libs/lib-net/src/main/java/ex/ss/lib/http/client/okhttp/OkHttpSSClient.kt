package ex.ss.lib.http.client.okhttp

import com.google.gson.Gson
import ex.ss.lib.http.client.ISSHttpClient
import ex.ss.lib.http.client.okhttp.util.TrustManager
import ex.ss.lib.http.exception.SSHttpException
import ex.ss.lib.http.request.SSHttpMethod
import ex.ss.lib.http.request.SSHttpRequest
import kotlinx.coroutines.suspendCancellableCoroutine
import okhttp3.Call
import okhttp3.Callback
import okhttp3.FormBody
import okhttp3.HttpUrl
import okhttp3.HttpUrl.Companion.toHttpUrl
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.Response
import okhttp3.logging.HttpLoggingInterceptor
import java.io.IOException
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

class OkHttpSSClient private constructor(private val builder: Builder) : ISSHttpClient {

    data class Builder(
        val baseUrl: String,
        val okhttpClientBuilder: OkHttpClient.Builder.() -> Unit = {},
        val loggerLevel: HttpLoggingInterceptor.Level = HttpLoggingInterceptor.Level.BODY,
        val logger: HttpLoggingInterceptor.Logger = HttpLoggingInterceptor.Logger.DEFAULT,
        val trustAllCertificates: Boolean = false,
    )

    companion object {
        fun create(baseUrl: String, block: Builder.() -> Builder = { this }): OkHttpSSClient {
            return OkHttpSSClient(Builder(baseUrl).let(block))
        }
    }

    private val gson: Gson by lazy { Gson() }

    private val client by lazy {
        OkHttpClient.Builder().apply(builder.okhttpClientBuilder)
            .addInterceptor(HttpLoggingInterceptor(builder.logger).setLevel(builder.loggerLevel))
            .apply {
                if (builder.trustAllCertificates) {
                    TrustManager.trustAllHttpsCertificates(this)
                }
            }.build()
    }

    override suspend fun <Response> request(request: SSHttpRequest<Response>): Response {
        val response = runCatching { doRequest(request) }.getOrElse {
            throw SSHttpException(request, ex = it)
        }
        return parseResponse(request, response)
    }

    private fun <Response> parseResponse(
        request: SSHttpRequest<Response>,
        response: okhttp3.Response
    ): Response {
        if (response.isSuccessful) {
            return response.body?.use {
                if (request.type.type == String::class.java) {
                    it.string() as Response
                } else {
                    gson.fromJson(it.string(), request.type.type)
                }
            } ?: throw SSHttpException(request, response.code, response.message)
        } else {
            throw SSHttpException(request, response.code, response.message)
        }
    }

    private suspend fun <T> doRequest(request: SSHttpRequest<T>): Response {
        return realRequest(createOkHttpRequest(request))
    }

    private suspend fun realRequest(request: Request) = suspendCancellableCoroutine { co ->
        val call = client.newCall(request)
        co.invokeOnCancellation {
            call.cancel()
        }
        val callback = object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                co.resumeWithException(e)
            }

            override fun onResponse(call: Call, response: Response) {
                co.resume(response)
            }
        }
        call.enqueue(callback)
    }

    private fun <Response> createOkHttpRequest(request: SSHttpRequest<Response>): Request {
        return when (request.method) {
            SSHttpMethod.GET -> createGetRequest(request)
            SSHttpMethod.POST -> createPostRequest(request)
            else -> throw IllegalStateException("$request")
        }
    }

    private fun <Response> createGetRequest(httpGet: SSHttpRequest<Response>): Request {
        val httpUrl = if (httpGet.params.isEmpty()) {
            createHttpUrl(httpGet)
        } else {
            createHttpUrl(httpGet).newBuilder().apply {
                httpGet.params.onEach {
                    addQueryParameter(it.key, it.value)
                }
            }.build()
        }
        return Request.Builder().get().url(httpUrl).apply {
            httpGet.headers.onEach {
                addHeader(it.first, it.second)
            }
        }.build()
    }

    private fun <Response> createPostRequest(httpPost: SSHttpRequest<Response>): Request {
        val httpUrl = createHttpUrl(httpPost)
        val body = if (httpPost.body == null && httpPost.params.isEmpty()) {
            "".toRequestBody(null)
        } else {
            if (httpPost.params.isNotEmpty()) {
                FormBody.Builder().apply {
                    httpPost.params.onEach { add(it.key, it.value) }
                }.build()
            } else {
                gson.toJson(httpPost.body).toRequestBody("application/json".toMediaType())
            }
        }
        return Request.Builder().post(body).url(httpUrl).apply {
            httpPost.headers.onEach {
                addHeader(it.first, it.second)
            }
        }.build()
    }

    private fun <Response> createHttpUrl(request: SSHttpRequest<Response>): HttpUrl {
        val path = request.path
        val domain = request.domain ?: builder.baseUrl
        return when {
            path.startsWith("http://") || path.startsWith("https://") -> path.toHttpUrl()
            path.startsWith("/") || path.startsWith("\\") -> {
                domain.toHttpUrl().newBuilder().addEncodedPathSegments(path.drop(1)).build()
            }

            else -> domain.toHttpUrl().newBuilder().addEncodedPathSegments(path).build()
        }
    }

}