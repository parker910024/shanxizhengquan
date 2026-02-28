package com.yanshu.app.model

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.viewModelScope
import com.yanshu.app.config.NewsCache
import com.yanshu.app.config.UserConfig
import com.yanshu.app.data.LoginApiData
import com.yanshu.app.data.LoginData
import com.yanshu.app.data.LoginRequest
import com.yanshu.app.data.RegisterRequest
import com.yanshu.app.data.UserProfile
import com.yanshu.app.data.UserProfileData
import com.yanshu.app.repo.Remote
import ex.ss.lib.net.bean.ResponseData
import kotlinx.coroutines.launch
import java.util.concurrent.atomic.AtomicBoolean

object UserViewModel : BaseViewModel() {

    val payForRefreshUserInfo = AtomicBoolean(false)

    private val _userInfoLiveData = MutableLiveData<UserProfile?>()
    val userInfoLiveData: LiveData<UserProfile?> = _userInfoLiveData

    private val _userInfoResponseLiveData = MutableLiveData<ResponseData<UserProfileData>>()
    val userInfoResponseLiveData: LiveData<ResponseData<UserProfileData>> = _userInfoResponseLiveData

    private val _loginResultLiveData = MutableLiveData<Boolean>()
    val loginResultLiveData: LiveData<Boolean> = _loginResultLiveData

    private val _loginDataLiveData = MutableLiveData<LoginData?>()
    val loginDataLiveData: LiveData<LoginData?> = _loginDataLiveData

    private val _loginErrorLiveData = MutableLiveData<String?>()
    val loginErrorLiveData: LiveData<String?> = _loginErrorLiveData

    private val _registerResultLiveData = MutableLiveData<Boolean>()
    val registerResultLiveData: LiveData<Boolean> = _registerResultLiveData

    private val _registerErrorLiveData = MutableLiveData<String?>()
    val registerErrorLiveData: LiveData<String?> = _registerErrorLiveData

    private val _loginResponseLiveData = MutableLiveData<ResponseData<LoginApiData>>()
    private val _registerResponseLiveData = MutableLiveData<ResponseData<LoginApiData>>()

    val isLogin: Boolean
        get() = UserConfig.isLogin()

    fun loginData(data: LoginData) {
        UserConfig.saveLoginData(data)
        _loginDataLiveData.postValue(data)
        _loginResultLiveData.postValue(true)
    }

    fun login(account: String, password: String) {
        viewModelScope.launch {
            val responseData = Remote.callApi<LoginApiData> {
                login(LoginRequest(account = account, password = password))
            }
            _loginResponseLiveData.postValue(responseData)

            if (responseData.isSuccess() && responseData.data != null) {
                handleLoginSuccess(responseData.data)
            } else {
                val errorMessage = responseData.failed.msg ?: "登录失败"
                _loginErrorLiveData.postValue(errorMessage)
                _loginResultLiveData.postValue(false)
            }
        }
    }

    private fun handleLoginSuccess(loginData: LoginApiData) {
        val legacyData = loginData.toLegacyLoginData()
        UserConfig.saveLoginData(legacyData)
        _loginDataLiveData.postValue(legacyData)
        _loginResultLiveData.postValue(true)
        _loginErrorLiveData.postValue(null)
        prefetchNewsCache()
    }

    fun register(account: String, password: String, paymentCode: String = "", inviteCode: String = "") {
        viewModelScope.launch {
            val responseData = Remote.callApi<LoginApiData> {
                register(
                    RegisterRequest(
                        mobile = account,
                        password = password,
                        payment_code = paymentCode,
                        institution_number = inviteCode,
                    )
                )
            }
            _registerResponseLiveData.postValue(responseData)

            if (responseData.isSuccess() && responseData.data != null) {
                handleRegisterSuccess(responseData.data)
            } else {
                val errorMessage = responseData.failed.msg ?: "注册失败"
                _registerErrorLiveData.postValue(errorMessage)
                _registerResultLiveData.postValue(false)
            }
        }
    }

    private fun handleRegisterSuccess(loginData: LoginApiData) {
        val legacyData = loginData.toLegacyLoginData()
        UserConfig.saveLoginData(legacyData)
        _loginDataLiveData.postValue(legacyData)
        _registerResultLiveData.postValue(true)
        _registerErrorLiveData.postValue(null)
        prefetchNewsCache()
    }

    private fun prefetchNewsCache() {
        viewModelScope.launch {
            runCatching { NewsCache.fetchAndCacheAll() }
        }
    }

    fun userInfo() {
        val cachedUser = UserConfig.getUser()
        if (cachedUser != null) {
            _userInfoLiveData.postValue(cachedUser)
        }

        callApi(_userInfoResponseLiveData, ::handleUserInfoSuccess) {
            getUserInfo()
        }
    }

    private fun handleUserInfoSuccess(userProfileData: UserProfileData) {
        val profile = userProfileData.list
        UserConfig.saveUser(profile)
        _userInfoLiveData.postValue(profile)
    }

    private fun LoginApiData.toLegacyLoginData(): LoginData {
        val loginToken = userinfo.token
        return LoginData(token = loginToken, auth_data = loginToken)
    }
}
