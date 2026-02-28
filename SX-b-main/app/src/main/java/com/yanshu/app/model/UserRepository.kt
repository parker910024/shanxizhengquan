package com.yanshu.app.model

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import com.yanshu.app.data.UserProfileData
import ex.ss.lib.net.bean.ResponseData

object UserRepository : BaseRepository() {

    private val _userInfoResponseLiveData = MutableLiveData<ResponseData<UserProfileData>>()
    val userInfoResponseLiveData: LiveData<ResponseData<UserProfileData>> = _userInfoResponseLiveData

    fun userInfo() {
        callApi(_userInfoResponseLiveData) {
            getUserInfo()
        }
    }
}
