package ex.ss.lib.base.view

import android.content.Context
import android.graphics.Color
import android.util.AttributeSet
import android.widget.FrameLayout
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat

class ImmersiveStatusBarHolder @JvmOverloads constructor(
    context: Context, attrs: AttributeSet? = null,
) : FrameLayout(context, attrs) {

    companion object {
        var ImmersiveBar = false
        var BarColor = Color.TRANSPARENT
    }

    private var statusBarHeight = 0

    init {
        setBackgroundColor(BarColor)
        // 先用系统资源获取一个初始值
        statusBarHeight = getStatusBarHeightFromResource()
        
        // 监听 WindowInsets 更新
        ViewCompat.setOnApplyWindowInsetsListener(this) { _, insets ->
            val newHeight = insets.getInsets(WindowInsetsCompat.Type.statusBars()).top
            if (newHeight > 0 && statusBarHeight != newHeight) {
                statusBarHeight = newHeight
                requestLayout()
            }
            insets
        }
    }

    private fun getStatusBarHeightFromResource(): Int {
        val resourceId = resources.getIdentifier("status_bar_height", "dimen", "android")
        return if (resourceId > 0) {
            resources.getDimensionPixelSize(resourceId)
        } else {
            0
        }
    }

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        // 主动请求 WindowInsets
        requestApplyInsets()
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        super.onMeasure(widthMeasureSpec, heightMeasureSpec)
        if (ImmersiveBar && statusBarHeight > 0) {
            setMeasuredDimension(widthMeasureSpec, statusBarHeight)
        }
    }

}
