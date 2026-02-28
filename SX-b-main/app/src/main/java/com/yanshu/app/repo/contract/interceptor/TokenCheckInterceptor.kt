package com.yanshu.app.repo.contract.interceptor

import android.util.Log
import com.yanshu.app.config.UserConfig
import com.yanshu.app.repo.Remote
import okhttp3.Interceptor
import okhttp3.Response
import java.io.IOException

/**
 * 在发起请求前检查本地 token：若未登录（token 为空），则直接拦截需登录的请求，不访问网络。
 * 白名单：登录、注册接口允许无 token 访问。
 */
class TokenCheckInterceptor : Interceptor {

    override fun intercept(chain: Interceptor.Chain): Response {
        val path = chain.request().url.encodedPath
        Log.d("sp_ts", "Contract path: $path")
        if (UserConfig.isLogin()) {
            return chain.proceed(chain.request())
        }
        if (isNoAuthPath(path)) {
            return chain.proceed(chain.request())
        }
        Remote.notifyLoginExpireOnce()
        throw IOException("请登录后操作")
    }

    private fun isNoAuthPath(path: String): Boolean {
        return path.contains("api/user/login") || path.contains("api/user/register")
    }
}
