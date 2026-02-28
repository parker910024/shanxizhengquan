package com.yanshu.app.model

import androidx.lifecycle.MutableLiveData
import com.yanshu.app.data.BaseResponse
import com.yanshu.app.repo.API
import com.yanshu.app.repo.Remote
import ex.ss.lib.net.bean.ResponseData
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

abstract class BaseRepository {

    protected fun <T> callApi(
        liveData: MutableLiveData<ResponseData<T>>,
        block: suspend API.() -> BaseResponse<T>
    ) {
        CoroutineScope(Dispatchers.IO).launch {
            val responseData = Remote.callApi(block)
            liveData.postValue(responseData)
        }
    }

    protected fun <T> callApi(
        responseLiveData: MutableLiveData<ResponseData<T>>,
        successLiveData: MutableLiveData<T>? = null,
        block: suspend API.() -> BaseResponse<T>
    ) {
        CoroutineScope(Dispatchers.IO).launch {
            val responseData = Remote.callApi(block)
            responseLiveData.postValue(responseData)

            if (responseData.isSuccess() && successLiveData != null) {
                responseData.data?.let {
                    successLiveData.postValue(it)
                }
            }
        }
    }
}