package com.yanshu.app.config

import android.app.Activity
import android.content.Context
import android.content.res.Resources
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.util.DisplayMetrics
import android.util.Log
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.Observer
import com.yanshu.app.R
import com.yanshu.app.data.StaticNode
import com.yanshu.app.floatmenu.FloatItem
import com.yanshu.app.floatmenu.FloatLogoMenu
import com.yanshu.app.floatmenu.FloatMenuView
import com.yanshu.app.proxy.ProxyManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull
import java.lang.ref.WeakReference
import java.net.InetSocketAddress
import java.net.Socket

object FloatMenuManager {
    private const val TAG = "FloatMenuManager"

    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private var configLoaded = false
    private var configLoading = false
    val configReadyLiveData = MutableLiveData<Boolean>()

    private var currentMenu: FloatLogoMenu? = null
    private var menuHostActivity: WeakReference<AppCompatActivity>? = null
    private var latestVisibleActivity: WeakReference<AppCompatActivity>? = null
    private val itemList = ArrayList<FloatItem>()

    fun startConfigLoading() {
        if (configLoaded || configLoading) return
        configLoading = true
        scope.launch {
            try {
                Log.d(TAG, "startConfigLoading: begin")
                StaticConfigManager.loadNodes()
                StaticConfigManager.loadLines()
                StaticConfigManager.loadProxyRules()

                val nodeConnected = tryConnectBestNode()
                AppStateManager.setNodesFailedOrEmpty(!nodeConnected)

                configLoaded = true
                configReadyLiveData.postValue(true)

                latestVisibleActivity?.get()?.let { activity ->
                    if (!activity.isFinishing && !activity.isDestroyed) {
                        ensureShown(activity)
                    }
                }

                Log.d(TAG, "startConfigLoading: done nodeConnected=$nodeConnected")
            } catch (t: Throwable) {
                Log.e(TAG, "startConfigLoading failed", t)
            } finally {
                configLoading = false
            }
        }
    }

    @Deprecated("Global float mode is disabled. Use showInActivity/hideInActivity.")
    fun enableGlobal(context: Context) {
        Log.d(TAG, "enableGlobal ignored in activity-scoped mode")
    }

    @Deprecated("Global float mode is disabled. Use showInActivity/hideInActivity.")
    fun disableGlobal() {
        Log.d(TAG, "disableGlobal ignored in activity-scoped mode")
    }

    fun showInActivity(activity: AppCompatActivity) {
        if (activity.isFinishing || activity.isDestroyed) {
            Log.d(TAG, "showInActivity skipped for invalid activity=${hostName(activity)}")
            return
        }

        latestVisibleActivity = WeakReference(activity)

        if (configLoaded) {
            ensureShown(activity)
            return
        }

        startConfigLoading()
        configReadyLiveData.observe(activity, object : Observer<Boolean> {
            override fun onChanged(loaded: Boolean) {
                if (!loaded) return
                configReadyLiveData.removeObserver(this)

                if (!activity.isFinishing && !activity.isDestroyed) {
                    latestVisibleActivity = WeakReference(activity)
                    ensureShown(activity)
                }
            }
        })
        Log.d(TAG, "showInActivity waiting config host=${hostName(activity)}")
    }

    fun hideInActivity(activity: Activity) {
        val host = menuHostActivity?.get()
        if (host == activity) {
            Log.d(TAG, "hideInActivity host matched=${hostName(host)}")
            destroyCurrentMenu("activity-destroy:${hostName(host)}", clearHost = true)
        } else {
            Log.d(
                TAG,
                "hideInActivity skipped currentHost=${hostName(host)} caller=${hostName(activity)}"
            )
        }
    }

    private fun ensureShown(activity: AppCompatActivity) {
        if (activity.isFinishing || activity.isDestroyed) return

        val host = menuHostActivity?.get()
        when {
            currentMenu == null -> {
                Log.d(TAG, "ensureShown create host=${hostName(activity)}")
                buildAndShowMenu(activity)
            }

            host == null -> {
                Log.d(TAG, "ensureShown recreate because host was lost -> ${hostName(activity)}")
                destroyCurrentMenu("host-lost", clearHost = false)
                buildAndShowMenu(activity)
            }

            host != activity -> {
                Log.d(
                    TAG,
                    "ensureShown recreate because host changed ${hostName(host)} -> ${hostName(activity)}"
                )
                destroyCurrentMenu(
                    "host-changed:${hostName(host)}->${hostName(activity)}",
                    clearHost = false
                )
                buildAndShowMenu(activity)
            }

            else -> {
                try {
                    currentMenu?.show()
                    Log.d(TAG, "ensureShown show existing host=${hostName(activity)}")
                } catch (e: Exception) {
                    Log.w(TAG, "ensureShown show failed, rebuild host=${hostName(activity)}", e)
                    destroyCurrentMenu("show-failed", clearHost = false)
                    buildAndShowMenu(activity)
                }
            }
        }
    }

    private fun buildAndShowMenu(activity: AppCompatActivity) {
        if (currentMenu != null) return

        val lines = StaticConfigManager.getLines()
        val currentLine = StaticConfigManager.getCurrentLine()
        val selectedBgColor = Color.argb(255, 245, 245, 245)
        val normalBgColor = Color.argb(255, 232, 232, 232)

        itemList.clear()
        for (i in lines.indices) {
            val line = lines[i]
            val isCurrent = currentLine?.url == line.url
            val bgColor = if (isCurrent) selectedBgColor else normalBgColor
            val floatItem = FloatItem(
                line.name,
                Color.argb(255, 51, 51, 51),
                bgColor,
                BitmapFactory.decodeResource(activity.resources, R.drawable.yw_menu_account),
                (i + 1).toString()
            )
            floatItem.lineUrl = line.url
            floatItem.hasNodeFailureIndicator = AppStateManager.allNodesFailedOrEmpty
            floatItem.hasNonWhitelistIndicator = !StaticConfigManager.shouldProxy(line.url)
            itemList.add(floatItem)
        }

        if (itemList.isEmpty()) {
            Log.w(TAG, "buildAndShowMenu skipped because no lines loaded")
            return
        }

        currentMenu = FloatLogoMenu.Builder()
            .withActivity(activity)
            .logo(loadHighQualityBitmap(activity.resources, R.drawable.yw_game_logo))
            .drawCicleMenuBg(true)
            .backMenuColor(-0x1b1c1f)
            .setBgDrawable(activity.resources.getDrawable(R.drawable.yw_game_float_menu_bg))
            .setFloatItems(itemList)
            .defaultLocation(FloatLogoMenu.RIGHT)
            .drawRedPointNum(false)
            .setOnMenuExpandListener(object : FloatLogoMenu.OnMenuExpandListener {
                override fun onMenuExpanded() {}
            })
            .showWithListener(object : FloatMenuView.OnMenuClickListener {
                override fun onItemClick(position: Int, title: String?) {
                    StaticConfigManager.switchLine(position)
                    refreshFloatMenuItems(activity)
                }

                override fun dismiss() {}
            })

        menuHostActivity = WeakReference(activity)
        Log.d(TAG, "buildAndShowMenu shown host=${hostName(activity)} items=${itemList.size}")
    }

    private fun destroyCurrentMenu(reason: String, clearHost: Boolean) {
        try {
            currentMenu?.hide()
        } catch (e: Exception) {
            Log.w(TAG, "destroyCurrentMenu hide failed reason=$reason", e)
        } finally {
            currentMenu = null
            if (clearHost) {
                menuHostActivity = null
            }
        }
        Log.d(TAG, "destroyCurrentMenu reason=$reason clearHost=$clearHost")
    }

    private fun refreshFloatMenuItems(activity: AppCompatActivity) {
        if (currentMenu == null) return

        val lines = StaticConfigManager.getLines()
        val currentLine = StaticConfigManager.getCurrentLine()
        val selectedBgColor = Color.argb(255, 245, 245, 245)
        val normalBgColor = Color.argb(255, 232, 232, 232)

        itemList.clear()
        for (i in lines.indices) {
            val line = lines[i]
            val isCurrent = currentLine?.url == line.url
            val bgColor = if (isCurrent) selectedBgColor else normalBgColor
            val floatItem = FloatItem(
                line.name,
                Color.argb(255, 51, 51, 51),
                bgColor,
                BitmapFactory.decodeResource(activity.resources, R.drawable.yw_menu_account),
                (i + 1).toString()
            )
            floatItem.lineUrl = line.url
            floatItem.hasNodeFailureIndicator = AppStateManager.allNodesFailedOrEmpty
            floatItem.hasNonWhitelistIndicator = !StaticConfigManager.shouldProxy(line.url)
            itemList.add(floatItem)
        }

        currentMenu?.setFloatItemList(itemList)
        Log.d(TAG, "refreshFloatMenuItems host=${hostName(activity)} items=${itemList.size}")
    }

    private fun loadHighQualityBitmap(resources: Resources, resId: Int): Bitmap {
        val options = BitmapFactory.Options().apply {
            inScaled = false
            inDensity = DisplayMetrics.DENSITY_DEFAULT
            inTargetDensity = DisplayMetrics.DENSITY_DEFAULT
            inSampleSize = 1
            inPreferredConfig = Bitmap.Config.ARGB_8888
            inJustDecodeBounds = false
        }
        return BitmapFactory.decodeResource(resources, resId, options)
            ?: throw IllegalStateException("Failed to decode bitmap")
    }

    private suspend fun tryConnectBestNode(): Boolean {
        val nodes = StaticConfigManager.getNodes()
        android.util.Log.d("config_ts", "===== 尝试连接最佳节点 =====")
        android.util.Log.d("config_ts", "可用节点数: ${nodes.size}")
        if (nodes.isEmpty()) {
            android.util.Log.w("config_ts", "节点列表为空，跳过连接")
            return false
        }

        val pingResults = nodes.map { node ->
            scope.async(Dispatchers.IO) {
                val latency = tcpPingNode(node)
                android.util.Log.d("config_ts", "  TCP Ping ${node.name}: ${latency?.let { "${it}ms" } ?: "超时/失败"}")
                if (latency != null) node to latency else null
            }
        }.awaitAll().filterNotNull()

        if (pingResults.isEmpty()) {
            android.util.Log.w("config_ts", "所有节点ping均失败")
            return false
        }

        val sorted = pingResults.sortedBy { it.second }
        android.util.Log.d("config_ts", "节点延迟排序:")
        sorted.forEachIndexed { i, (node, latency) ->
            android.util.Log.d("config_ts", "  #$i ${node.name}: ${latency}ms")
        }

        return withTimeoutOrNull(20_000L) {
            for ((node, latency) in sorted) {
                android.util.Log.d("config_ts", "尝试连接节点: ${node.name} (${latency}ms)")
                ProxyManager.startProxyWithUrl(node.url)

                val portOpen = waitForPort(ProxyManager.HTTP_PORT, 5000L)
                if (portOpen) {
                    android.util.Log.d("config_ts", "节点 ${node.name} 连接成功，代理端口已开放")
                    menuHostActivity?.get()?.let { refreshFloatMenuItems(it) }
                    return@withTimeoutOrNull true
                }

                android.util.Log.w("config_ts", "节点 ${node.name} 代理端口未开放，尝试下一个")
                ProxyManager.stopProxy()
                delay(300)
            }
            android.util.Log.w("config_ts", "所有节点连接均失败")
            false
        } ?: run {
            android.util.Log.w("config_ts", "连接节点超时(20s)")
            false
        }
    }

    private fun tcpPingNode(node: StaticNode): Long? {
        return try {
            val withoutScheme = node.url.substringAfter("://")
            val addressPart = withoutScheme.substringAfter("@").substringBefore("?")
            val ip = addressPart.substringBefore(":")
            val port = addressPart.substringAfter(":").toInt()

            val socket = Socket()
            val start = System.currentTimeMillis()
            socket.connect(InetSocketAddress(ip, port), 3000)
            val latency = System.currentTimeMillis() - start
            socket.close()
            latency
        } catch (_: Exception) {
            null
        }
    }

    private suspend fun waitForPort(port: Int, timeout: Long): Boolean = withContext(Dispatchers.IO) {
        val start = System.currentTimeMillis()
        while (System.currentTimeMillis() - start < timeout) {
            try {
                Socket().use { s ->
                    s.connect(InetSocketAddress("127.0.0.1", port), 200)
                    return@withContext true
                }
            } catch (_: Exception) {
                delay(200)
            }
        }
        false
    }

    private fun hostName(activity: Activity?): String = activity?.javaClass?.simpleName ?: "null"
}
