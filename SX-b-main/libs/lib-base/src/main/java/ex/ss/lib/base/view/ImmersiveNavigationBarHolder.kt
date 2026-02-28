package ex.ss.lib.base.view

import android.app.Activity
import android.content.Context
import android.graphics.Color
import android.util.AttributeSet
import android.widget.FrameLayout
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat

class ImmersiveNavigationBarHolder @JvmOverloads constructor(
    context: Context, attrs: AttributeSet? = null,
) : FrameLayout(context, attrs) {

    companion object {
        var ImmersiveBar = false
        var BarColor = Color.TRANSPARENT
    }

    init {
        setBackgroundColor(BarColor)
    }

    private val statusBarHeight by lazy {
        (context as? Activity)?.window?.let {
            ViewCompat.getRootWindowInsets(it.decorView)
                ?.getInsets(WindowInsetsCompat.Type.navigationBars())?.bottom ?: 0
        } ?: 0
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        super.onMeasure(widthMeasureSpec, heightMeasureSpec)
        if (ImmersiveBar) {
            setMeasuredDimension(widthMeasureSpec, MeasureSpec.getSize(statusBarHeight))
        }
    }

}