package com.yanshu.app.base

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.WindowManager
import android.view.inputmethod.InputMethodManager
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.viewbinding.ViewBinding
import com.yanshu.app.R
import com.yanshu.app.config.FloatMenuManager
import com.yanshu.app.config.UserConfig
import com.yanshu.app.repo.Remote
import com.yanshu.app.ui.dialog.AppDialog
import com.yanshu.app.util.lang.LanguageUtil
import ex.ss.lib.base.activity.BaseActivity

abstract class BasicActivity<VB : ViewBinding> : BaseActivity<VB>() {

    companion object {
        @Volatile
        private var loginExpireDialogShowing = false
    }

    private var pendingLoginExpireDialog = false

    override fun attachBaseContext(newBase: Context?) {
        super.attachBaseContext(LanguageUtil.getNewLocalContext(newBase))
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (listenerExpire()) {
            Remote.loginExpireLiveData.observe(this) {
                if (it) {
                    pendingLoginExpireDialog = true
                    showLoginExpireDialogIfNeeded()
                }
            }
        }
        if (showFloatMenu()) {
            FloatMenuManager.showInActivity(this)
        }
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (!hasFocus) return
        controlSystemUI()
    }

    override fun onStart() {
        super.onStart()
        controlSystemUI()
    }

    override fun onResume() {
        super.onResume()
        if (showFloatMenu()) {
            FloatMenuManager.showInActivity(this)
        }
        showLoginExpireDialogIfNeeded()
    }

    private fun controlSystemUI() {
        WindowCompat.setDecorFitsSystemWindows(window, false)
        val controllerCompat = WindowCompat.getInsetsController(window, window.decorView)
        controllerCompat.isAppearanceLightStatusBars = useLightStatusBarIcons()
        controllerCompat.systemBarsBehavior =
            WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        controllerCompat.hide(WindowInsetsCompat.Type.navigationBars())

        val attributes = window.attributes
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            attributes.layoutInDisplayCutoutMode =
                WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
        }
        window.attributes = attributes

        window.clearFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS)
        window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS)
        window.statusBarColor = statusBarColor()
        window.navigationBarColor = Color.TRANSPARENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.isNavigationBarContrastEnforced = false
        }
    }

    protected open fun statusBarColor(): Int = Color.TRANSPARENT

    protected open fun useLightStatusBarIcons(): Boolean = true

    protected fun <T : Activity> startActivity(clazz: Class<T>, params: Intent.() -> Unit = {}) {
        val intent = Intent(this, clazz)
        params.invoke(intent)
        startActivity(intent)
    }

    private fun showLoginExpireDialogIfNeeded() {
        if (!pendingLoginExpireDialog) return
        if (isFinishing || isDestroyed) return
        if (supportFragmentManager.isStateSaved) return
        if (loginExpireDialogShowing) return

        pendingLoginExpireDialog = false
        loginExpireDialogShowing = true
        AppDialog.show(supportFragmentManager) {
            title = getString(R.string.common_dialog_title)
            content = getString(R.string.login_expired_message)
            done = getString(R.string.login_expired_go_login)
            alwaysShow = true
            onDone = {
                UserConfig.performLogout(this@BasicActivity)
            }
            onClose = {
                loginExpireDialogShowing = false
            }
        }
    }

    protected open fun showFloatMenu(): Boolean = true

    protected open fun listenerExpire(): Boolean = true

    override fun onDestroy() {
        FloatMenuManager.hideInActivity(this)
        super.onDestroy()
    }

    /** 收起软键盘；若当前有焦点 View 则先清除焦点。 */
    protected fun hideKeyboard() {
        currentFocus?.let { focus ->
            (getSystemService(Context.INPUT_METHOD_SERVICE) as? InputMethodManager)
                ?.hideSoftInputFromWindow(focus.windowToken, 0)
            focus.clearFocus()
        }
    }

    /** 为根布局设置点击空白收起键盘（在 initView 中对 binding.root 调用即可）。 */
    protected fun View.setClickToHideKeyboard() {
        isClickable = true
        isFocusableInTouchMode = true
        setOnClickListener { hideKeyboard() }
    }
}
