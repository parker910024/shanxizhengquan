package com.yanshu.app.repo

import android.content.Context
import androidx.lifecycle.MutableLiveData
import com.yanshu.app.R
import com.yanshu.app.config.UserConfig
import com.yanshu.app.data.BaseResponse
import com.yanshu.app.ui.dialog.AppToast
import com.google.gson.JsonSyntaxException
import com.google.gson.stream.MalformedJsonException
import ex.ss.lib.net.BaseRemoteRepository
import ex.ss.lib.net.bean.ResponseData
import ex.ss.lib.net.bean.ResponseFailed
import kotlinx.coroutines.delay
import retrofit2.HttpException
import java.io.IOException
import java.net.ConnectException
import java.net.SocketTimeoutException
import java.net.UnknownHostException

object Remote : BaseRemoteRepository<API>() {

    val loginExpireLiveData = MutableLiveData<Boolean>()

    override val apiClass: Class<API> = API::class.java

    private val loginExpireLock = Any()

    @Volatile
    private var loginExpireNotified = false

    /**
     * Trigger login-expired event only once to avoid duplicate dialogs/navigation.
     */
    fun notifyLoginExpireOnce() {
        synchronized(loginExpireLock) {
            if (loginExpireNotified) return
            loginExpireNotified = true
        }
        loginExpireLiveData.postValue(true)
    }

    suspend fun <T> callApi(block: suspend API.() -> BaseResponse<T>): ResponseData<T> {
        val response = retryCall(0) { block.invoke(api) }
        return if (response.isSuccess()) {
            val data = response.data
            when (data.code) {
                BaseResponse.SUCCESS -> ResponseData.success(data.data)

                BaseResponse.EXPIRE -> {
                    if (UserConfig.isLogin()) {
                        notifyLoginExpireOnce()
                    }
                    ResponseData.failed(data.code, data.message)
                }

                else -> {
                    AppToast.show(data.message)
                    ResponseData.failed(data.code, data.message)
                }
            }
        } else {
            val failed = failedWrapper(response.failed)
            if (failed.code == BaseResponse.EXPIRE && UserConfig.isLogin()) {
                notifyLoginExpireOnce()
            } else {
                val toastMsg = failed.msg ?: failed.e?.message
                if (!toastMsg.isNullOrBlank()) {
                    AppToast.show(toastMsg)
                }
            }
            ResponseData.failed(failed)
        }
    }

    private suspend fun <T> retryCall(retryCount: Int = 3, call: suspend () -> T): ResponseData<T> {
        val callResponse = call(call)
        return if (!callResponse.isSuccess() && retryCount > 0) {
            delay(100)
            retryCall(retryCount - 1, call)
        } else {
            callResponse
        }
    }

    fun resetLoginExpire() {
        loginExpireNotified = false
        loginExpireLiveData.postValue(false)
    }

    private val errorMessage = mutableMapOf<Class<out Exception>, String>()

    fun initErrorMessage(context: Context) {
        errorMessage[UnknownHostException::class.java] = context.getString(R.string.unknown_host)
    }

    private fun failedWrapper(failed: ResponseFailed): ResponseFailed {
        return when (val error = failed.e) {
            is SocketTimeoutException -> {
                ResponseFailed(failed.code, "网络连接超时，请稍后再试", error)
            }

            is ConnectException -> {
                ResponseFailed(failed.code, "无法连接服务器，请检查网络", error)
            }

            is UnknownHostException -> {
                ResponseFailed(failed.code, "网络不可用，请检查网络连接", error)
            }

            is IOException -> {
                ResponseFailed(failed.code, "网络异常，请稍后再试", error)
            }

            is HttpException -> {
                val code = error.code()
                val msg = error.response()?.errorBody()?.string() ?: error.message()
                ResponseFailed(code, msg, error)
            }

            is MalformedJsonException,
            is JsonSyntaxException -> {
                ResponseFailed(failed.code, null, error)
            }

            else -> failed
        }
    }
}
