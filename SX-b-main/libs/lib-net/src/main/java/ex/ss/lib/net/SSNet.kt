package ex.ss.lib.net

import com.google.gson.Gson
import ex.ss.lib.net.converter.CompatibleGsonConvert
import ex.ss.lib.net.util.TrustManager
import okhttp3.OkHttpClient
import retrofit2.Retrofit
import java.util.concurrent.TimeUnit

class SSNetBuilder {
    var timeoutSeconds = 10L
    var trustAllManager = false
    var okhttpBuilder: (OkHttpClient.Builder.() -> Unit) = {}
    var retrofitBuilder: (Retrofit.Builder.() -> Unit) = {}
    var onResponsePreCheck: OnResponsePreCheck? = null
}

object SSNet {
    private lateinit var retrofit: Retrofit

    fun initialize(baseUrl: String, onBuilder: SSNetBuilder.() -> Unit = {}): SSNet {
        val builder = SSNetBuilder().apply(onBuilder)
        val httpClient = initOkHttp(builder)
        initRetrofit(httpClient, baseUrl, builder)
        return this
    }

    internal fun <T> create(clazz: Class<T>): T {
        return retrofit.create(clazz)
    }

    /**
     * 初始化OKHttp
     */
    private fun initOkHttp(builder: SSNetBuilder): OkHttpClient {
        val okHttpClientBuilder = OkHttpClient.Builder()
            .connectTimeout(builder.timeoutSeconds, TimeUnit.SECONDS)
            .writeTimeout(builder.timeoutSeconds, TimeUnit.SECONDS)
            .readTimeout(builder.timeoutSeconds, TimeUnit.SECONDS)
            .callTimeout(builder.timeoutSeconds, TimeUnit.SECONDS)
        takeIf { builder.trustAllManager }?.also {
            TrustManager.trustAllHttpsCertificates(okHttpClientBuilder)
        }
        builder.okhttpBuilder(okHttpClientBuilder)
        return okHttpClientBuilder.build()
    }

    /**
     * 初始化Retrofit
     */
    private fun initRetrofit(client: OkHttpClient, baseUrl: String, builder: SSNetBuilder) {
        val convert = CompatibleGsonConvert(Gson(), builder.onResponsePreCheck)
        retrofit =
            Retrofit.Builder().addConverterFactory(convert).baseUrl(baseUrl).client(client).apply {
                builder.retrofitBuilder.invoke(this)
            }.build()
    }


}