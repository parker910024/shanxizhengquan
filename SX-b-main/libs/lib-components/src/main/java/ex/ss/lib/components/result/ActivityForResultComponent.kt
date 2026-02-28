package ex.ss.lib.components.result

import androidx.activity.result.contract.ActivityResultContract
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.LifecycleRegistry
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.withContext
import java.util.concurrent.atomic.AtomicInteger
import kotlin.coroutines.suspendCoroutine


private val nextRequestKey = AtomicInteger(0)

suspend fun <I, O> FragmentActivity.launchForResult(
    contracts: ActivityResultContract<I, O>,
    input: I,
): O = withContext(Dispatchers.Main) {
    val requestKey = nextRequestKey.getAndIncrement().toString()
    ActivityResultLifecycle().use { lifecycle, start ->
        suspendCoroutine { c ->
            activityResultRegistry.register(requestKey, lifecycle, contracts) {
                c.resumeWith(Result.success(it))
            }.apply { start() }.launch(input)
        }
    }
}

class ActivityResultLifecycle : LifecycleOwner {

    override val lifecycle: LifecycleRegistry = LifecycleRegistry(this)

    init {
        lifecycle.currentState = Lifecycle.State.INITIALIZED
    }

    suspend fun <T> use(block: suspend (lifecycle: ActivityResultLifecycle, onStart: () -> Unit) -> T): T {
        return try {
            markCreated()
            block(this, this::markStarted)
        } finally {
            withContext(NonCancellable) {
                markDestroy()
            }
        }
    }

    private fun markCreated() {
        lifecycle.currentState = Lifecycle.State.CREATED
    }

    private fun markStarted() {
        lifecycle.currentState = Lifecycle.State.STARTED
        lifecycle.currentState = Lifecycle.State.RESUMED
    }

    private fun markDestroy() {
        lifecycle.currentState = Lifecycle.State.DESTROYED
    }
}