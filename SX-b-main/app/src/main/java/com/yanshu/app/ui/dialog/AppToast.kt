package com.yanshu.app.ui.dialog

import android.app.Activity
import android.app.Application
import android.app.Application.ActivityLifecycleCallbacks
import android.content.Context
import android.os.Bundle
import android.view.Gravity
import android.view.LayoutInflater
import android.widget.TextView
import android.widget.Toast
import com.yanshu.app.R
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.launch
import java.util.concurrent.atomic.AtomicReference

/**
 * 自定义Toast工具类
 * 显示在屏幕中间，深色背景
 */
object AppToast : CoroutineScope by MainScope() {

    private val currentActivity = AtomicReference<Activity>(null)

    fun initialize(application: Application) {
        application.registerActivityLifecycleCallbacks(object : ActivityLifecycleCallbacks {
            override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {}
            override fun onActivityStarted(activity: Activity) {}
            override fun onActivityResumed(activity: Activity) {
                currentActivity.set(activity)
            }
            override fun onActivityPaused(activity: Activity) {}
            override fun onActivityStopped(activity: Activity) {}
            override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}
            override fun onActivityDestroyed(activity: Activity) {}
        })
    }

    /**
     * 显示短时Toast（无需Context，自动获取当前Activity）
     */
    fun show(msg: String) = launch(Dispatchers.Main) {
        if (isBlack(msg)) return@launch
        val activity = currentActivity.get()
        if (msg.isNotEmpty() && activity != null && !activity.isDestroyed) {
            showToast(activity, msg, Toast.LENGTH_SHORT)
        }
    }

    /**
     * 显示长时Toast（无需Context）
     */
    fun showLong(msg: String) = launch(Dispatchers.Main) {
        if (isBlack(msg)) return@launch
        val activity = currentActivity.get()
        if (msg.isNotEmpty() && activity != null && !activity.isDestroyed) {
            showToast(activity, msg, Toast.LENGTH_LONG)
        }
    }

    /**
     * 显示短时Toast（需要Context）
     */
    fun show(context: Context, message: String) {
        showToast(context, message, Toast.LENGTH_SHORT)
    }

    /**
     * 显示长时Toast（需要Context）
     */
    fun showLong(context: Context, message: String) {
        showToast(context, message, Toast.LENGTH_LONG)
    }

    /**
     * 显示自定义Toast
     */
    private fun showToast(context: Context, message: String, duration: Int) {
        try {
            val toast = Toast(context.applicationContext)
            val inflater = LayoutInflater.from(context)
            val view = inflater.inflate(R.layout.layout_custom_toast, null)
            val tvMessage = view.findViewById<TextView>(R.id.tv_toast_message)
            tvMessage.text = message
            toast.view = view
            toast.duration = duration
            toast.setGravity(Gravity.CENTER, 0, 0)
            toast.show()
        } catch (e: Exception) {
            e.printStackTrace()
            Toast.makeText(context, message, duration).show()
        }
    }

    private fun isBlack(msg: String): Boolean {
        return !BLACK_MSG_LIST.firstOrNull { msg.lowercase().startsWith(it.lowercase()) }
            .isNullOrEmpty()
    }

    private val BLACK_MSG_LIST = hashSetOf("Software caused connection abort")
}

/**
 * Context扩展函数 - 显示短时Toast
 */
fun Context.appToast(message: String) {
    AppToast.show(this, message)
}

/**
 * Context扩展函数 - 显示长时Toast
 */
fun Context.appToastLong(message: String) {
    AppToast.showLong(this, message)
}
