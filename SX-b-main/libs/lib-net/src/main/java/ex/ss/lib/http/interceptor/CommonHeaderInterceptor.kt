package ex.ss.lib.http.interceptor

import okhttp3.Interceptor
import okhttp3.Response

class CommonHeaderInterceptor(private val header: () -> MutableMap<String, String>) : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response {
        val newBuilder = chain.request().newBuilder()
        mutableMapOf<String, String>().apply {
            header.invoke().also { putAll(it) }
        }.forEach {
            newBuilder.addHeader(it.key, it.value)
        }
        return chain.proceed(newBuilder.build())
    }
}