package ex.ss.lib.components.log

import android.util.Log
import java.util.concurrent.atomic.AtomicBoolean

object SSLog : ILogger {

    private val logger by lazy { create("SSLog") }

    private val openLog = AtomicBoolean(false)

    private var logPrinter: ((priority: Int, tag: String, msg: String) -> Unit)? = null

    fun debug(debug: Boolean) {
        openLog.set(debug)
    }

    fun create(tag: String, open: Boolean = true): ILogger {
        return object : ILoggerImpl(tag) {
            override val debug: Boolean
                get() = open && openLog.get()
            override val printer: ((priority: Int, tag: String, msg: String) -> Unit)?
                get() = logPrinter
        }
    }

    fun println(printer: (priority: Int, tag: String, msg: String) -> Unit) {
        this.logPrinter = printer
    }

    fun priorityName(priority: Int): String {
        return when (priority) {
            Log.VERBOSE -> "V"
            Log.DEBUG -> "D"
            Log.INFO -> "I"
            Log.WARN -> "W"
            Log.ERROR -> "E"
            Log.ASSERT -> "A"
            else -> "$priority"
        }
    }

    override fun v(vararg values: Any) {
        logger.v(*values)
    }

    override fun d(vararg values: Any) {
        logger.d(*values)
    }

    override fun i(vararg values: Any) {
        logger.i(*values)
    }

    override fun w(vararg values: Any) {
        logger.w(*values)
    }

    override fun e(vararg values: Any) {
        logger.e(*values)
    }

    override fun a(vararg values: Any) {
        logger.a(*values)
    }

}

interface ILogger {
    fun v(vararg values: Any)
    fun d(vararg values: Any)
    fun i(vararg values: Any)
    fun w(vararg values: Any)
    fun e(vararg values: Any)
    fun a(vararg values: Any)
}

abstract class ILoggerImpl(private val tag: String) : ILogger {

    abstract val debug: Boolean

    abstract val printer: ((priority: Int, tag: String, msg: String) -> Unit)?

    override fun v(vararg values: Any) {
        println(Log.VERBOSE, *values)
    }

    override fun d(vararg values: Any) {
        println(Log.DEBUG, *values)
    }

    override fun i(vararg values: Any) {
        println(Log.INFO, *values)
    }

    override fun w(vararg values: Any) {
        println(Log.WARN, *values)
    }

    override fun e(vararg values: Any) {
        println(Log.ERROR, *values)
    }

    override fun a(vararg values: Any) {
        println(Log.ASSERT, *values)
    }

    private fun println(priority: Int, vararg values: Any) {
        val msg = values.map { "$it" }.joinToString { it }
        if (debug) {
            Log.println(priority, tag, msg)
        }
        printer?.invoke(priority, tag, msg)
    }

}