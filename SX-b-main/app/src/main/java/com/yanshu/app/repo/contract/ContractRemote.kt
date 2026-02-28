package com.yanshu.app.repo.contract

import android.util.Log
import com.yanshu.app.config.UserConfig
import com.yanshu.app.data.BaseResponse
import com.yanshu.app.repo.API
import com.yanshu.app.repo.Remote
import com.yanshu.app.ui.dialog.AppToast
import ex.ss.lib.net.bean.ResponseData
import retrofit2.HttpException

object ContractRemote {

    private val api: API
        get() = ContractServiceFactory.api

    suspend fun <T> callApi(block: suspend API.() -> BaseResponse<T>): ResponseData<T> {
        return callApiInternal(block, showToast = true)
    }

    suspend fun <T> callApiSilent(block: suspend API.() -> BaseResponse<T>): ResponseData<T> {
        return callApiInternal(block, showToast = false)
    }

    private suspend fun <T> callApiInternal(
        block: suspend API.() -> BaseResponse<T>,
        showToast: Boolean,
    ): ResponseData<T> {
        Log.d("sp_ts", "ContractRemote request start")
        return runCatching { block.invoke(api) }.fold(
            onSuccess = { data ->
                Log.d("sp_ts", "ContractRemote response code=${data.code}")
                val routeMissing = isRouteMissingMessage(data.msg)
                when {
                    data.code == BaseResponse.SUCCESS && !routeMissing -> {
                        ResponseData.success(data.code, data.msg, data.data)
                    }

                    data.code == 0 && data.msg.equals("success", ignoreCase = true) -> {
                        ResponseData.success(data.data)
                    }

                    data.code == BaseResponse.EXPIRE -> {
                        if (UserConfig.isLogin()) {
                            Remote.notifyLoginExpireOnce()
                        }
                        ResponseData.failed(data.code, data.msg)
                    }

                    else -> {
                        if (showToast) AppToast.show(data.msg)
                        ResponseData.failed(data.code, data.msg)
                    }
                }
            },
            onFailure = { error ->
                Log.d("sp_ts", "ContractRemote failure: ${error.message}")
                val httpCode = (error as? HttpException)?.code()
                if (httpCode == BaseResponse.EXPIRE && UserConfig.isLogin()) {
                    Remote.notifyLoginExpireOnce()
                } else if (showToast) {
                    val displayMsg = when (error) {
                        is java.net.SocketTimeoutException -> "网络连接超时，请稍后再试"
                        is java.net.ConnectException -> "无法连接服务器，请检查网络"
                        is java.net.UnknownHostException -> "网络不可用，请检查网络连接"
                        is java.io.IOException -> "网络异常，请稍后再试"
                        else -> error.message ?: ""
                    }
                    AppToast.show(displayMsg)
                }
                ResponseData.failed(error)
            }
        )
    }

    private fun isRouteMissingMessage(msg: String): Boolean {
        val lower = msg.lowercase()
        return msg.contains("api不存在") || lower.contains("api not found")
    }
}
