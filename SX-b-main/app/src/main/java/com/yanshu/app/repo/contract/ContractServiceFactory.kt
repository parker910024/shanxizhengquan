package com.yanshu.app.repo.contract

import android.os.Build
import com.google.gson.Gson
import com.proxy.base.config.AppConfig
import com.yanshu.app.BuildConfig
import com.yanshu.app.config.AppConfigCenter
import com.yanshu.app.config.UserConfig
import com.yanshu.app.repo.API
import com.yanshu.app.repo.ResponseCharsetInterceptor
import com.yanshu.app.repo.contract.interceptor.DecryptInterceptor
import com.yanshu.app.repo.contract.interceptor.DomainChangeInterceptor
import com.yanshu.app.repo.contract.interceptor.PathCalculateInterceptor
import com.yanshu.app.repo.contract.interceptor.PathObfuscationInterceptor
import com.yanshu.app.repo.contract.interceptor.RequestEncryptInterceptor
import com.yanshu.app.repo.contract.interceptor.TokenCheckInterceptor
import ex.ss.lib.net.interceptor.CommonHeaderInterceptor
import ex.ss.lib.tools.common.hash
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.util.concurrent.TimeUnit

object ContractServiceFactory {

    private val apiInstance: API by lazy {
        val client = buildClient()
        val retrofit = Retrofit.Builder()
            .baseUrl(BuildConfig.BASE_URL)
            .client(client)
            .addConverterFactory(GsonConverterFactory.create(Gson()))
            .build()
        retrofit.create(API::class.java)
    }

    val api: API
        get() = apiInstance

    private fun buildClient(): OkHttpClient {
        return OkHttpClient.Builder()
            .connectTimeout(15L, TimeUnit.SECONDS)
            .writeTimeout(15L, TimeUnit.SECONDS)
            .readTimeout(15L, TimeUnit.SECONDS)
            .callTimeout(20L, TimeUnit.SECONDS)
            .apply {
                if (AppConfigCenter.enableCryptoLog) {
                    addNetworkInterceptor(
                        HttpLoggingInterceptor().setLevel(HttpLoggingInterceptor.Level.BODY)
                    )
                }
                addInterceptor(TokenCheckInterceptor())
                addInterceptor(PathCalculateInterceptor())
                addInterceptor(PathObfuscationInterceptor())
                addInterceptor(DomainChangeInterceptor())
                addInterceptor(RequestEncryptInterceptor())
                addInterceptor(DecryptInterceptor())
                addInterceptor(
                    CommonHeaderInterceptor {
                        mutableMapOf(
                            "devicetype" to "1",
                            "devicename" to "${Build.BRAND} ${Build.MODEL}",
                            "deviceid" to AppConfig.deviceId.hash(),
                            "authtoken" to UserConfig.token,
                            "token" to UserConfig.auth_data,
                            "channel-number" to AppConfig.channel,
                            "oaid" to AppConfig.oaid.hash(),
                        )
                    }
                )
                addInterceptor(ResponseCharsetInterceptor())
            }
            .build()
    }
}
