package com.yanshu.app.singbox

import android.content.Context
import kotlinx.coroutines.*
import java.io.File
import java.net.Socket

object SingBoxProcess {

    private const val CONFIG_FILE = "singbox_config.json"

    private var context: Context? = null
    private var statusCallback: Callback? = null
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    private var boxService: Any? = null
    private var initialized = false
    private var initFailed = false

    fun init(ctx: Context) {
        context = ctx.applicationContext
    }

    private fun ensureInitialized(): Boolean {
        if (initialized) return true
        if (initFailed) return false

        val ctx = context ?: return false

        return try {
            go.Seq.setContext(ctx)

            val baseDir = ctx.filesDir
            val workingDir = ctx.getExternalFilesDir(null) ?: ctx.filesDir
            val tempDir = ctx.cacheDir

            baseDir.mkdirs()
            workingDir.mkdirs()
            tempDir.mkdirs()

            val options = io.nekohasekai.libbox.SetupOptions()
            options.basePath = baseDir.path
            options.workingPath = workingDir.path
            options.tempPath = tempDir.path

            io.nekohasekai.libbox.Libbox.setup(options)

            initialized = true
            true
        } catch (e: Throwable) {
            initFailed = true
            false
        }
    }

    fun setCallback(callback: Callback?) {
        statusCallback = callback
    }

    fun start(configJson: String) {
        scope.launch {
            try {
                stopSync()

                waitForPortRelease(VlessToSingboxConverter.HTTP_PORT, 5000L)

                withContext(Dispatchers.Main) {
                    statusCallback?.connectionStatusDidChange(Callback.K_Connecting)
                }

                if (!ensureInitialized()) {
                    withContext(Dispatchers.Main) {
                        statusCallback?.connectionStatusDidChange(Callback.K_Disconnected)
                    }
                    return@launch
                }

                try {
                    val configFile = File(context?.filesDir, CONFIG_FILE)
                    configFile.writeText(configJson)
                } catch (_: Exception) {
                }

                val platformInterface = SimplePlatformInterface(context!!)
                val service = io.nekohasekai.libbox.Libbox.newService(configJson, platformInterface)

                service.start()
                boxService = service

                val timeout = 5000L
                val startTime = System.currentTimeMillis()
                var connected = false

                while (System.currentTimeMillis() - startTime < timeout) {
                    if (checkPort(VlessToSingboxConverter.HTTP_PORT)) {
                        connected = true
                        break
                    }
                    delay(200)
                }

                if (connected) {
                    withContext(Dispatchers.Main) {
                        statusCallback?.connectionStatusDidChange(Callback.K_Connected)
                    }
                } else {
                    stop()
                }
            } catch (e: Throwable) {
                withContext(Dispatchers.Main) {
                    statusCallback?.connectionStatusDidChange(Callback.K_Disconnected)
                }
            }
        }
    }

    fun stop() {
        try {
            (boxService as? io.nekohasekai.libbox.BoxService)?.close()
            boxService = null
        } catch (_: Throwable) {
        }
        statusCallback?.connectionStatusDidChange(Callback.K_Disconnected)
    }

    private suspend fun stopSync() {
        try {
            val service = boxService as? io.nekohasekai.libbox.BoxService
            if (service != null) {
                service.close()
                boxService = null
                delay(500)
            }
        } catch (_: Throwable) {
        }
        withContext(Dispatchers.Main) {
            statusCallback?.connectionStatusDidChange(Callback.K_Disconnected)
        }
    }

    fun isRunning(): Boolean {
        return boxService != null && checkPort(VlessToSingboxConverter.HTTP_PORT)
    }

    private fun checkPort(port: Int): Boolean {
        return try {
            Socket().use { socket ->
                socket.connect(java.net.InetSocketAddress("127.0.0.1", port), 500)
                true
            }
        } catch (_: Exception) {
            false
        }
    }

    private suspend fun waitForPortRelease(port: Int, timeout: Long): Boolean {
        val startTime = System.currentTimeMillis()
        while (System.currentTimeMillis() - startTime < timeout) {
            if (!checkPort(port)) {
                return true
            }
            delay(100)
        }
        return !checkPort(port)
    }

    fun release() {
        stop()
        scope.cancel()
    }
}
