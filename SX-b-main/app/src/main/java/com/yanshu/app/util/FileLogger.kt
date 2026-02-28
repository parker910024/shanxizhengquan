package com.yanshu.app.util

import android.content.Context
import com.yanshu.app.config.UserConfig
import ex.ss.lib.components.log.SSLog
import ex.ss.lib.tools.extension.formatDate
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.util.concurrent.ConcurrentLinkedQueue
import java.util.concurrent.atomic.AtomicBoolean

object FileLogger {

    private lateinit var sdkLogFile: File
    private lateinit var appLogFile: File

    val sdk: ILoggerWriter by lazy { FileLoggerWriter(sdkLogFile) }
    val app: ILoggerWriter by lazy { FileLoggerWriter(appLogFile) }

    fun initialize(context: Context) {
        sdkLogFile = createLogFile(context, "sdk-log.log")
        appLogFile = createLogFile(context, "app-log.log")
    }

    fun getLogFile(): List<File> {
        return arrayListOf(sdkLogFile, appLogFile)
    }

    suspend fun copyToUploadFile(context: Context, srcFiles: List<File>): File? =
        withContext(Dispatchers.IO) {
            if (srcFiles.none { it.exists() }) return@withContext null
            val dir = File(context.cacheDir, "upload").apply { mkdirs() }
            val info = UserConfig.getUser()
            val account = info?.mobile.orEmpty().ifEmpty { "unknown" }
            val userId = info?.id ?: 0
            val fileName = "android-${
                System.currentTimeMillis().formatDate("yyyyMMddHHmmss")
            }-$account-$userId.log"
            return@withContext File(dir, fileName).also { target ->
                srcFiles.filter { file -> file.exists() }.map { file ->
                    "\n>>${file.name}<<\n" + file.readText()
                }.onEach {
                    target.appendText(it)
                }
            }
        }

    private fun createLogFile(context: Context, fileName: String): File {
        val dir = getLogFileDir(context)
        return File(dir, fileName)
    }

    fun getLogFileDir(context: Context, prefix: String = ""): File {
        return File(
            File(context.dataDir, "log"), "${prefix}vs-log"
        ).also {
            if (it.exists()) it.deleteRecursively()
            if (!it.exists()) it.mkdirs()
        }
    }

}

interface ILoggerWriter {

    fun write(msg: String)

    fun toggle(toggle: Boolean)

    fun clear(): Boolean
}

class FileLoggerWriter(private val logFile: File) : ILoggerWriter,
    CoroutineScope by CoroutineScope(SupervisorJob() + Dispatchers.IO) {

    private val log by lazy { SSLog.create("FileLoggerWriter") }
    private val logLinkedQueue = ConcurrentLinkedQueue<LogMessage>()
    private val start = AtomicBoolean(true)

    init {
        if (logFile.exists()) {
            logFile.createNewFile()
        } else {
            logFile.parentFile.also { if (it != null && !it.exists()) it.mkdirs() }
        }
        startLoggerMonitor()
    }

    private fun startLoggerMonitor() = launch {
        while (start.get()) {
            val msg = logLinkedQueue.poll()
            if (msg != null) {
                runCatching {
                    logFile.appendText("${msg.time.formatDate()} ${msg.msg}\n")
                }
            }
        }
    }

    override fun write(msg: String) {
        logLinkedQueue.offer(LogMessage(msg,System.currentTimeMillis()))
    }

    override fun toggle(toggle: Boolean) {
        start.set(toggle)
    }

    override fun clear(): Boolean {
        val origin = start.getAndSet(false)
        val delete = if (logFile.exists()) logFile.delete() else true
        start.set(origin)
        return delete
    }


}

data class LogMessage(val msg: String, val time: Long)
