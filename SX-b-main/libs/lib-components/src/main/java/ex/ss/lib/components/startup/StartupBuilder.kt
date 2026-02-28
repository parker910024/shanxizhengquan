package ex.ss.lib.components.startup

import android.app.Application

class StartupBuilder internal constructor() {

    private lateinit var app: Application

    internal val initializeList = mutableListOf<Initializer>()

    internal fun addInitializer(initializer: Initializer) {
        initializeList.add(initializer)
    }

    fun invokeApplication(): Application {
        return app
    }

    fun setApplication(app: Application): StartupBuilder {
        this.app = app
        return this
    }

}