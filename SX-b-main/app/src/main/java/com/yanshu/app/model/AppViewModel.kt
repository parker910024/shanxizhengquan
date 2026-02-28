package com.yanshu.app.model

import androidx.lifecycle.MutableLiveData
import com.yanshu.app.config.UserConfig
import com.yanshu.app.data.MineConfig
import ex.ss.lib.components.log.SSLog
import kotlinx.coroutines.sync.Mutex
import java.util.concurrent.atomic.AtomicReference

object AppViewModel : BaseViewModel() {

    private val log by lazy { SSLog.create("AppViewModel") }

    private val currentMineConfig = AtomicReference<MineConfig>(null)
    private val mineConfigMutex = Mutex()
    
    val mineConfigLiveData = MutableLiveData<MineConfig?>()

    fun onProcessResume() {
        log.d("进入前台")
        if (UserConfig.isLogin()) {
            log.d("进入前台，刷新一次用户信息")
            UserViewModel.userInfo()
            if (UserConfig.paying) {
                log.d("触发了支付，刷新一次节点")
                UserConfig.paying = false
                log.d("触发了支付，刷新支付结果")
            }
        }
    }

    fun onProcessStop() {

    }
}