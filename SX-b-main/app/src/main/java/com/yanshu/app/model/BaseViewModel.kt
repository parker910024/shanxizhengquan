package com.yanshu.app.model

import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.yanshu.app.data.BaseResponse
import com.yanshu.app.repo.API
import com.yanshu.app.repo.Remote
import kotlinx.coroutines.launch
import ex.ss.lib.net.bean.ResponseData

abstract class BaseViewModel : ViewModel() {
    
    protected fun <T> callApi(
        responseLiveData: MutableLiveData<ResponseData<T>>,
        onSuccess: ((T) -> Unit)? = null,
        block: suspend API.() -> BaseResponse<T>
    ) {
        viewModelScope.launch {
            val responseData = Remote.callApi(block)
            responseLiveData.postValue(responseData)
            
            if (responseData.isSuccess() && responseData.data != null) {
                onSuccess?.invoke(responseData.data)
            }
        }
    }
}