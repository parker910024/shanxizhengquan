package ex.ss.lib.base.extension

import android.graphics.drawable.Drawable
import android.view.View
import android.widget.TextView
import androidx.activity.OnBackPressedCallback
import androidx.annotation.ColorRes
import androidx.core.content.ContextCompat
import androidx.core.content.res.ResourcesCompat
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.LifecycleOwner

fun Fragment.addOnBackPressedCallback(
    enable: Boolean = true,
    owner: LifecycleOwner,
    onBackPressed: () -> Unit
): OnBackPressedCallback {
    return object : OnBackPressedCallback(enable) {
        override fun handleOnBackPressed() {
            onBackPressed.invoke()
        }
    }.apply {
        requireActivity().onBackPressedDispatcher.addCallback(owner, this)
    }
}

fun FragmentActivity.addOnBackPressedCallback(
    enable: Boolean = true,
    owner: LifecycleOwner,
    onBackPressed: () -> Unit
): OnBackPressedCallback {
    return object : OnBackPressedCallback(enable) {
        override fun handleOnBackPressed() {
            onBackPressed.invoke()
        }
    }.apply {
        onBackPressedDispatcher.addCallback(owner, this)
    }
}

fun TextView.textColor(@ColorRes res: Int) {
    setTextColor(ContextCompat.getColor(context, res))
}


fun TextView.compoundDrawable(
    left: Int? = null, top: Int? = null, right: Int? = null, bottom: Int? = null
) {
    compoundDrawable(
        left?.let { ResourcesCompat.getDrawable(context.resources, it, context.theme) },
        top?.let { ResourcesCompat.getDrawable(context.resources, it, context.theme) },
        right?.let { ResourcesCompat.getDrawable(context.resources, it, context.theme) },
        bottom?.let { ResourcesCompat.getDrawable(context.resources, it, context.theme) })
}

fun TextView.compoundDrawable(
    left: Drawable? = null, top: Drawable? = null, right: Drawable? = null, bottom: Drawable? = null
) {
    setCompoundDrawablesWithIntrinsicBounds(left, top, right, bottom)
}


fun View.setOnAntiViolenceClickListener(
    interval: Int = OnAntiViolenceClickListener.MIN_CLICK_INTERVAL_TIME, listener: (View) -> Unit
) {
    setOnClickListener(OnAntiViolenceClickListener(listener, interval))
}

private class OnAntiViolenceClickListener(
    val listener: (View) -> Unit,
    val interval: Int = MIN_CLICK_INTERVAL_TIME,
    val needAntiViolence: () -> Boolean = { true },
) : View.OnClickListener {
    companion object {
        internal const val MIN_CLICK_INTERVAL_TIME = 600

        // 点击时间记录
        var time: Long = -12345678910
    }

    override fun onClick(view: View) {
        if (!needAntiViolence()) {
            listener(view)
            return
        }
        val current = System.currentTimeMillis()
        when {
            time == -12345678910                            -> {
                time = current
                listener(view)
            }

            current - time < 0 || current - time > interval -> {
                time = System.currentTimeMillis()
                listener(view)
            }
        }
    }
}