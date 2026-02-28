package com.yanshu.app.ui

import android.content.Intent
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import com.yanshu.app.config.UserConfig
import com.yanshu.app.ui.login.LoginActivity
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

suspend fun Fragment.checkLoginSuspend(block: suspend () -> Unit): Boolean {
    val check = withContext(Dispatchers.Main) { checkLogin() }
    if (check) {
        block.invoke()
        return true
    }
    return false
}

fun Fragment.checkLogin(block: () -> Unit): Boolean {
    if (checkLogin()) {
        block.invoke()
        return true
    }
    return false
}

fun Fragment.checkLogin(): Boolean {
    return requireActivity().checkLogin()
}

fun FragmentActivity.checkLogin(): Boolean {
    if (UserConfig.isLogin()) {
        return true
    } else {
        startActivity(Intent(this, LoginActivity::class.java))
        return false
    }
}
