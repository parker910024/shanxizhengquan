package ex.ss.lib.base.view

import android.app.Application
import androidx.core.view.WindowCompat
import androidx.lifecycle.Lifecycle
import ex.ss.lib.base.extension.registerActivityLifecycleEvent

object StatusBarUtils {

    fun setLightMode(application: Application, isLightMode: Boolean) {
        application.registerActivityLifecycleEvent { activity, event ->
            if (event == Lifecycle.Event.ON_CREATE || event == Lifecycle.Event.ON_RESUME) {
                WindowCompat.getInsetsController(activity.window, activity.window.decorView).also {
                    it.isAppearanceLightStatusBars = isLightMode
                }
            }
        }
    }

}