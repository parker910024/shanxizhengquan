package ex.ss.lib.components.startup

import android.content.Context

data class Initializer(val isAsync: Boolean, val delay: Long = 0L, val invoke: (Context) -> Unit)
