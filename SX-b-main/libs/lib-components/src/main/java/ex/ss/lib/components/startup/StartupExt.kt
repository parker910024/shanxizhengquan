package ex.ss.lib.components.startup

import android.content.Context

/**
 *异步初始化
 */
fun StartupBuilder.asyncStartup(delay: Long = 0L, invoke: (Context) -> Unit): Initializer {
    return Initializer(true, delay, invoke).apply { addInitializer(this) }
}

/**
 * 同步初始化
 */
fun StartupBuilder.syncStartup(invoke: (Context) -> Unit): Initializer {
    return Initializer(false, 0L, invoke).apply { addInitializer(this) }
}