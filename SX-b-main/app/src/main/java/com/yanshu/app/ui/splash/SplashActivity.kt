package com.yanshu.app.ui.splash

import android.content.Intent
import android.os.Handler
import android.util.Log
import android.os.Looper
import androidx.lifecycle.lifecycleScope
import com.yanshu.app.base.BasicActivity
import ex.ss.lib.base.extension.viewBinding
import com.yanshu.app.config.FloatMenuManager
import com.yanshu.app.config.UserConfig
import com.yanshu.app.databinding.ActivitySplashBinding
import com.yanshu.app.repo.Remote
import com.yanshu.app.repo.contract.ContractRemote
import com.yanshu.app.ui.login.LoginActivity
import com.yanshu.app.ui.main.MainActivity
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class SplashActivity : BasicActivity<ActivitySplashBinding>() {

    private companion object {
        const val SPLASH_DELAY_MS = 2000L
    }

    override val binding: ActivitySplashBinding by viewBinding()

    override fun initView() {
        Log.d("sp_ts", "SplashActivity onCreate")
        Handler(Looper.getMainLooper()).postDelayed({
            if (isFinishing) return@postDelayed
            val isLogin = UserConfig.isLogin()
            Log.d("sp_ts", "Splash delay done, isLogin=$isLogin")
            if (!isLogin) {
                Log.d("sp_ts", "Splash no token -> LoginActivity")
                startActivity(Intent(this, LoginActivity::class.java))
                finish()
                return@postDelayed
            }
            Log.d("sp_ts", "Splash calling getUserInfo()")
            lifecycleScope.launch {
                val resp = ContractRemote.callApiSilent { getUserInfo() }
                val code = if (!resp.isSuccess()) resp.failed.code else -1
                Log.d("sp_ts", "Splash getUserInfo isSuccess=${resp.isSuccess()} code=$code")
                withContext(Dispatchers.Main) {
                    if (isFinishing) return@withContext
                    if (!resp.isSuccess()) {
                        Log.d("sp_ts", "Splash navigate -> LoginActivity")
                        UserConfig.logout()
                        Remote.resetLoginExpire()
                        startActivity(Intent(this@SplashActivity, LoginActivity::class.java))
                    } else {
                        Log.d("sp_ts", "Splash navigate -> MainActivity")
                        startActivity(Intent(this@SplashActivity, MainActivity::class.java))
                    }
                    finish()
                }
            }
        }, SPLASH_DELAY_MS)
    }

    override fun showFloatMenu(): Boolean = false

    override fun initData() {
        FloatMenuManager.startConfigLoading()
    }

    override fun listenerExpire(): Boolean = false
}
