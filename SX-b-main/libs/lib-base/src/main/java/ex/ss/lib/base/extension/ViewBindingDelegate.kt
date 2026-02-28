package ex.ss.lib.base.extension

import android.content.Context
import android.view.LayoutInflater
import androidx.annotation.MainThread
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.LifecycleOwner
import androidx.viewbinding.ViewBinding
import kotlin.properties.ReadOnlyProperty
import kotlin.reflect.KProperty

inline fun <reified VB : ViewBinding> FragmentActivity.viewBinding(): ReadOnlyProperty<Any?, VB> {
    val inflateMethod = VB::class.java.getMethod("inflate", LayoutInflater::class.java)
    return ViewBindingDelegate({ this }, { lifecycle }) { inflateMethod.invoke(null, it) as VB }
}

inline fun <reified VB : ViewBinding> Fragment.viewBinding(): ReadOnlyProperty<Any?, VB> {
    val inflateMethod = VB::class.java.getMethod("inflate", LayoutInflater::class.java)
    return ViewBindingDelegate({ requireContext() }, { viewLifecycleOwner.lifecycle }) {
        inflateMethod.invoke(null, it) as VB
    }
}


class ViewBindingDelegate<VB : ViewBinding>(
    private val contextInvoke: () -> Context,
    private var lifecycleInvoke: () -> Lifecycle,
    private val viewBind: (LayoutInflater) -> VB
) : ReadOnlyProperty<Any?, VB> {
    private var viewBinding: VB? = null

    @MainThread
    override fun getValue(thisRef: Any?, property: KProperty<*>): VB {
        viewBinding?.also { return it }
        val layoutInflater = LayoutInflater.from(contextInvoke())
        val vb = viewBind.invoke(layoutInflater)
        viewBinding = vb
        lifecycleInvoke().also {
            it.addObserver(ViewBindingLifecycle(it) {
                viewBinding = null
            })
        }
        return viewBinding!!
    }

    class ViewBindingLifecycle(private val lifecycle: Lifecycle, private val onClear: () -> Unit) :
        LifecycleEventObserver {
        override fun onStateChanged(source: LifecycleOwner, event: Lifecycle.Event) {
            if (event == Lifecycle.Event.ON_DESTROY) {
                lifecycle.removeObserver(this)
                onClear.invoke()
            }
        }
    }
}