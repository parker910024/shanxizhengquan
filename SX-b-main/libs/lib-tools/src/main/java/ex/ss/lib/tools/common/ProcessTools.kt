package ex.ss.lib.tools.common

import android.app.ActivityManager
import android.content.Context
import android.os.Process

object ProcessTools {

    fun isMainProcess(context: Context): Boolean {
        val myPid = Process.myPid()
        return isProcess(context) { it.processName == context.packageName && it.pid == myPid }
    }

    fun checkProcessAlive(context: Context, processName: String): Boolean {
        return isProcess(context) {
            it.processName == processName
        }
    }


    fun isProcess(
        context: Context,
        onCheck: (ActivityManager.RunningAppProcessInfo) -> Boolean
    ): Boolean {
        context.getSystemService(Context.ACTIVITY_SERVICE).let { it as ActivityManager }.also {
            for (appProcess in it.runningAppProcesses) {
                if (onCheck.invoke(appProcess)) {
                    return true
                }
            }
        }
        return false
    }

}