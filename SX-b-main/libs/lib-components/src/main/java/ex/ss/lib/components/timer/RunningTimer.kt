package ex.ss.lib.components.timer

import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicLong

object RunningTimer {

    private var timerJob: Job? = null

    private var listener: ((Long) -> Unit)? = null

    private val isRunning = AtomicBoolean(false)
    private val initializeTime = AtomicLong(0)

    fun binding(owner: LifecycleOwner) {
        owner.lifecycle.addObserver(LifecycleEventObserver { source, event ->
            if (event == Lifecycle.Event.ON_START) {
                startTimer(owner)
            } else if (event == Lifecycle.Event.ON_STOP) {
                stopTimer()
            }
        })
    }

    fun onListener(listener: (Long) -> Unit) {
        this.listener = listener
    }

    fun start(owner: LifecycleOwner) {
        if (isRunning.get()) return
        initializeTime.set(System.currentTimeMillis())
        startTimer(owner)
    }

    fun stop() {
        if (!isRunning.get()) return
        initializeTime.set(0)
        stopTimer()
        listener?.invoke(0L)
    }

    private fun startTimer(owner: LifecycleOwner) {
        if (initializeTime.get() <= 0) return
        timerJob = owner.lifecycleScope.launch {
            isRunning.set(true)
            while (true) {
                if (initializeTime.get() <= 0) {
                    withContext(Dispatchers.Main) { listener?.invoke(0L) }
                    break
                } else {
                    withContext(Dispatchers.Main) {
                        val time = System.currentTimeMillis() - initializeTime.get()
                        listener?.invoke(time)
                        delay(1000)
                    }
                }
            }
            isRunning.set(false)
        }
    }

    private fun stopTimer() {
        isRunning.set(false)
        timerJob?.cancel()
    }

}