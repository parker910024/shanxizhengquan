package com.yanshu.app

import android.app.Application
import android.content.Context
import android.os.Build
import android.util.Log
import androidx.appcompat.app.AppCompatDelegate
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.ProcessLifecycleOwner
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.repeatOnLifecycle
import com.meituan.android.walle.WalleChannelReader
import com.proxy.base.config.AppConfig
import com.umeng.analytics.MobclickAgent
import com.umeng.commonsdk.UMConfigure
import com.yanshu.app.config.NewsCache
import com.yanshu.app.config.StaticConfig
import com.yanshu.app.config.UserConfig
import com.yanshu.app.model.AppViewModel
import com.yanshu.app.repo.ResponseCharsetInterceptor
import com.yanshu.app.repo.eastmoney.EastMoneyMarketRepository
import com.yanshu.app.repo.contract.dynamic.DynamicDomainConfig
import com.yanshu.app.repo.contract.interceptor.DecryptInterceptor
import com.yanshu.app.repo.contract.interceptor.DomainChangeInterceptor
import com.yanshu.app.repo.contract.interceptor.PathCalculateInterceptor
import com.yanshu.app.repo.contract.interceptor.PathObfuscationInterceptor
import com.yanshu.app.repo.contract.interceptor.RequestEncryptInterceptor
import com.yanshu.app.proxy.ProxyManager
import com.yanshu.app.proxy.WhitelistProxySelector
import com.yanshu.app.repo.OkhttpEventListener
import com.yanshu.app.repo.Remote
import com.yanshu.app.ui.dialog.AppToast
import com.yanshu.app.util.FileLogger
import ex.ss.lib.base.SSBase
import ex.ss.lib.components.SSComponents
import ex.ss.lib.components.log.SSLog
import ex.ss.lib.components.startup.StartupBuilder
import ex.ss.lib.components.startup.StartupComponent
import ex.ss.lib.components.startup.asyncStartup
import ex.ss.lib.components.startup.syncStartup
import ex.ss.lib.net.SSNet
import ex.ss.lib.net.interceptor.CommonHeaderInterceptor
import ex.ss.lib.tools.common.APKTools
import ex.ss.lib.tools.common.DevicesTools
import ex.ss.lib.tools.common.ProcessTools
import ex.ss.lib.tools.common.hash
import kotlinx.coroutines.launch
import okhttp3.logging.HttpLoggingInterceptor
import java.io.File

class App : Application() {

    override fun onCreate() {
        super.onCreate()
        AppCompatDelegate.setDefaultNightMode(AppCompatDelegate.MODE_NIGHT_NO)
        android.util.Log.d("sp_ts", "App onCreate")
        StartupComponent.onCreate(this) {
            log()
            base()
            proxy()
            appInit()
            umeng()
            net()
        }
    }
}

fun StartupBuilder.log() = syncStartup {
    FileLogger.initialize(it)
    SSLog.println { priority, tag, msg ->
        FileLogger.app.write("$tag $msg")
        if (BuildConfig.DEBUG) {
            Log.println(priority, tag, msg)
        }
    }
}

private fun StartupBuilder.base() = syncStartup {
    SSBase.initialize(it)
    SSBase.setImmersiveStatusBar(true)

    SSComponents.initialize(it)
    SSComponents.initMMKV {
        val crypt = APKTools.getSignNature(it).slice(0 until 16)
        setDefCryptKey(crypt)
        setRootPath(File(it.filesDir, "app").absolutePath)
        File(it.filesDir, "mmkv").delete()
    }
}

fun StartupBuilder.appInit() = syncStartup {
    if (AppConfig.deviceId.isEmpty()) {
        AppConfig.deviceId = DevicesTools.androidId(it)
    }
    AppConfig.channel = WalleChannelReader.getChannel(it.applicationContext).let { channel ->
        if (channel.isNullOrEmpty()) {
            AppConfig.channel.takeIf { item -> item.isNotEmpty() } ?: "default"
        } else {
            channel
        }
    }

    ProcessLifecycleOwner.get().apply {
        lifecycleScope.launch {
            repeatOnLifecycle(Lifecycle.State.RESUMED) {
                AppViewModel.onProcessResume()
            }
        }
        lifecycleScope.launch {
            repeatOnLifecycle(Lifecycle.State.CREATED) {
                AppViewModel.onProcessStop()
            }
        }
    }

    AppToast.initialize(invokeApplication())
}

fun StartupBuilder.proxy() = syncStartup {
    ProxyManager.init(it)
}

fun StartupBuilder.net() = syncStartup { context ->
    val netLog by lazy { SSLog.create("RemoteHttp") }
    Remote.initErrorMessage(context)
    StaticConfig.STATIC_LINES.firstOrNull()?.url?.let { DynamicDomainConfig.useStaticLine(it) }
        ?: DynamicDomainConfig.useTestServer()
    StaticConfig.PLAYWRIGHT_PROXY_URL.takeIf { it.isNotBlank() }?.let { proxyUrl ->
        EastMoneyMarketRepository.PROXY_BASE_URL = proxyUrl
        Log.d("sp_ts", "EastMoney proxy enabled: $proxyUrl")
    }
    SSNet.initialize(BuildConfig.BASE_URL) {
        okhttpBuilder = {
            proxySelector(WhitelistProxySelector())
            addNetworkInterceptor(
                HttpLoggingInterceptor { msg ->
                    val log = msg.toByteArray(Charsets.US_ASCII).toString(Charsets.UTF_8)
                    netLog.d(log)
                }.setLevel(HttpLoggingInterceptor.Level.BODY)
            )
            addInterceptor(PathCalculateInterceptor())
            addInterceptor(PathObfuscationInterceptor())
            addInterceptor(DomainChangeInterceptor())
            addInterceptor(RequestEncryptInterceptor())
            addInterceptor(DecryptInterceptor())
            addInterceptor(ResponseCharsetInterceptor())
            addInterceptor(
                CommonHeaderInterceptor {
                    mutableMapOf(
                        "devicetype" to "1",
                        "devicename" to "${Build.BRAND} ${Build.MODEL}",
                        "deviceid" to AppConfig.deviceId.hash(),
                        "token" to UserConfig.token,
                        "channel-number" to AppConfig.channel,
                        "oaid" to AppConfig.oaid.hash(),
                    )
                }
            )
            eventListenerFactory(OkhttpEventListener.get())
        }
    }

    ProcessLifecycleOwner.get().lifecycleScope.launch {
        if (UserConfig.isLogin()) {
            NewsCache.fetchAndCacheAll()
        }
    }
}

fun StartupBuilder.umeng() = asyncStartup {
    UMConfigure.setLogEnabled(BuildConfig.DEBUG)
    val appKey = "67481fc57e5e6a4eeba57679"
    UMConfigure.preInit(it, appKey, AppConfig.channel)
    MobclickAgent.setPageCollectionMode(MobclickAgent.PageMode.AUTO)
    UMConfigure.init(it, appKey, AppConfig.channel, UMConfigure.DEVICE_TYPE_PHONE, "")
}

fun isVpnProcess(context: Context): Boolean {
    return ProcessTools.isProcess(context) { it.processName == "${context.packageName}:xVPNService" }
}
