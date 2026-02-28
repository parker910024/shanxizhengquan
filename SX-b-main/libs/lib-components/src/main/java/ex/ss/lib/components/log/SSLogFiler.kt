package ex.ss.lib.components.log

import android.content.Context
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.concurrent.ConcurrentLinkedDeque
import java.util.concurrent.atomic.AtomicBoolean

object SSLogFiler : CoroutineScope by MainScope() {

    private val timeFormatter by lazy {
        SimpleDateFormat(
            "yyyy-MM-dd HH:mm:ss",
            Locale.SIMPLIFIED_CHINESE
        )
    }
    private val defaultFileNameFormatter by lazy {
        SimpleDateFormat(
            "yyyy_MM_dd",
            Locale.SIMPLIFIED_CHINESE
        )
    }

    private val open = AtomicBoolean(true)
    private val logItems = ConcurrentLinkedDeque<LogItem>()

    private lateinit var fileNameFormatter: SimpleDateFormat
    private lateinit var currentFile: File

    fun initialize(
        context: Context,
        logFileParent: File? = null,
        fileNameFormatter: SimpleDateFormat = defaultFileNameFormatter
    ) {
        this.fileNameFormatter = fileNameFormatter
        val parentFile = File(logFileParent ?: context.cacheDir, "ss-log").apply { mkdirs() }
        currentFile = getLogFile(parentFile)
        appStartLog()
        launch {
            while (open.get()) {
                val item = logItems.poll()
                if (item != null) {
                    writeFile(currentFile, item.format(timeFormatter))
                } else {
                    delay(100)
                }
            }
        }
    }


    fun appendLog(log: String) {
        if (open.get()) {
            logItems.offer(LogItem(System.currentTimeMillis(), log))
        }
    }

    fun pause() = open.set(false)
    fun open() = open.set(true)
    fun invokeLogFile(): File {
        return currentFile
    }

    private fun appStartLog() {
        val format = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.SIMPLIFIED_CHINESE)
        val time = format.format(System.currentTimeMillis())
        appendLog("\n----------App Start $time----------\n")
    }

    private fun getFileName(): String {
        val formatter = if (this::fileNameFormatter.isInitialized) {
            fileNameFormatter
        } else {
            defaultFileNameFormatter
        }
        return "${formatter.format(System.currentTimeMillis())}.log"
    }

    private fun getLogFile(parent: File): File {
        val fileName = getFileName()
        val file = File(parent, fileName)
        if (!file.exists()) file.createNewFile()
        return file
    }

    private suspend fun writeFile(file: File, content: String) = withContext(Dispatchers.IO) {
        file.appendText("$content\n", Charsets.UTF_8)
    }

    private class LogItem(val time: Long, val log: String) {
        fun format(formatter: SimpleDateFormat): String {
            return "${formatter.format(time)} $log"
        }
    }

}