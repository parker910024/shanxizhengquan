package com.yanshu.app.config

import android.content.Context
import android.content.Intent
import android.content.Intent.FLAG_ACTIVITY_CLEAR_TASK
import android.content.Intent.FLAG_ACTIVITY_NEW_TASK
import com.google.gson.Gson
import com.yanshu.app.data.LoginData
import com.yanshu.app.data.UserProfile
import com.yanshu.app.repo.Remote
import com.yanshu.app.ui.login.LoginActivity
import ex.ss.lib.components.mmkv.IMMKVDelegate
import ex.ss.lib.components.mmkv.kvDelegate

object UserConfig : IMMKVDelegate() {

    override fun mmkvName(): String = "appConfig"

    var paying by kvDelegate(false)
    var payOrder by kvDelegate("")

    var token by kvDelegate("")
    var auth_data by kvDelegate("")
    var vip_remark by kvDelegate("")

    private var userInfo by kvDelegate("")

    private val gson by lazy { Gson() }

    fun saveLoginData(data: LoginData) {
        this.token = data.token
        this.auth_data = data.auth_data
    }

    fun saveUser(info: UserProfile) {
        userInfo = gson.toJson(info)
        vip_remark = info.nickname.ifEmpty { info.username }
    }

    fun logout() {
        this.token = ""
        this.auth_data = ""
        this.userInfo = ""
        this.vip_remark = ""
    }

    /**
     * 退出账户（无接口）：清除登录态与缓存，并跳转登录页且清栈。
     */
    fun performLogout(context: Context) {
        logout()
        Remote.resetLoginExpire()
        val intent = Intent(context, LoginActivity::class.java).apply {
            addFlags(FLAG_ACTIVITY_NEW_TASK or FLAG_ACTIVITY_CLEAR_TASK)
        }
        runCatching { context.startActivity(intent) }
    }

    fun isLogin(): Boolean {
        return token.isNotEmpty()
    }

    fun getUser(): UserProfile? {
        return runCatching { gson.fromJson(userInfo, UserProfile::class.java) }.getOrNull()
    }

    fun getLogInfo(): String {
        return userInfo
    }
}
