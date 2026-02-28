package ex.ss.lib.components.startup

import android.app.Application
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

object StartupComponent {

    private val mainScope by lazy { MainScope() }

    fun onCreate(app: Application, builderInvoker: StartupBuilder.() -> Unit) {
        val builder = StartupBuilder().setApplication(app).apply(builderInvoker)
        initialize(builder)
    }

    private val lazyBuilder by lazy { StartupBuilder() }

    fun lazy(app: Application, builderInvoker: StartupBuilder.() -> Unit) {
        lazyBuilder.setApplication(app).apply(builderInvoker)
    }

    fun doLazy() {
        initialize(lazyBuilder)
    }

    private fun initialize(builder: StartupBuilder) {
        val context = builder.invokeApplication()
        builder.initializeList.forEach {
            if (it.isAsync) {
                mainScope.launch {
                    if (it.delay > 0L) delay(it.delay)
                    it.invoke(context)
                }
            } else {
                it.invoke(context)
            }
        }
    }
}

