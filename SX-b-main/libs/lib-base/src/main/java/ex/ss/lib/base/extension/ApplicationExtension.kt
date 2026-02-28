package ex.ss.lib.base.extension

import android.app.Activity
import android.app.Application
import android.os.Bundle
import androidx.lifecycle.Lifecycle


fun Application.registerActivityLifecycleEvent(onEvent: (Activity, Lifecycle.Event) -> Unit) {
    registerActivityLifecycleCallbacks(object : Application.ActivityLifecycleCallbacks {
        override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {
            onEvent.invoke(activity, Lifecycle.Event.ON_CREATE)
        }

        override fun onActivityStarted(activity: Activity) {
            onEvent.invoke(activity, Lifecycle.Event.ON_START)
        }

        override fun onActivityResumed(activity: Activity) {
            onEvent.invoke(activity, Lifecycle.Event.ON_RESUME)
        }

        override fun onActivityPaused(activity: Activity) {
            onEvent.invoke(activity, Lifecycle.Event.ON_PAUSE)
        }

        override fun onActivityStopped(activity: Activity) {
            onEvent.invoke(activity, Lifecycle.Event.ON_STOP)
        }

        override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {
        }

        override fun onActivityDestroyed(activity: Activity) {
            onEvent.invoke(activity, Lifecycle.Event.ON_DESTROY)
        }

    })
}