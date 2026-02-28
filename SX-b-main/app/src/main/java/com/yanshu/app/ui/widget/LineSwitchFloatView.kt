package com.yanshu.app.ui.widget

import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageView
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import com.yanshu.app.R
import com.yanshu.app.config.StaticConfigManager
import com.yanshu.app.data.ApiLine
import com.yanshu.app.proxy.ProxyManager
import com.yanshu.app.singbox.Callback
import kotlin.math.abs

class LineSwitchFloatView(private val activity: AppCompatActivity) {

    companion object {
        private const val COLOR_BORDER_DEFAULT = "#331A73E8"
        private const val COLOR_BORDER_CONNECTED = "#660F9D58"
        private const val COLOR_BORDER_CONNECTING = "#66FF9800"
    }

    private val density = activity.resources.displayMetrics.density
    private val btnSize = (48 * density).toInt()
    private val btnMargin = (10 * density).toInt()
    private val borderWidth = (3 * density).toInt()

    private val button: ImageView = createButton()

    private var downRawY = 0f
    private var downBtnY = 0f
    private var isDragging = false

    private fun createButton(): ImageView {
        val iv = ImageView(activity)
        iv.setImageResource(R.mipmap.ic_launcher_round)
        iv.scaleType = ImageView.ScaleType.CENTER_CROP
        iv.background = ringDrawable(Color.parseColor(COLOR_BORDER_DEFAULT))
        iv.elevation = 12f * density
        iv.setPadding(borderWidth, borderWidth, borderWidth, borderWidth)

        iv.setOnTouchListener { v, event ->
            handleTouch(v, event)
        }
        return iv
    }

    private fun ringDrawable(color: Int): GradientDrawable {
        return GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            setStroke(borderWidth, color)
            setColor(Color.WHITE)
        }
    }

    private fun handleTouch(v: View, event: MotionEvent): Boolean {
        when (event.action) {
            MotionEvent.ACTION_DOWN -> {
                downRawY = event.rawY
                downBtnY = v.y
                isDragging = false
                return true
            }
            MotionEvent.ACTION_MOVE -> {
                val dy = event.rawY - downRawY
                if (!isDragging && abs(dy) > 8f) isDragging = true
                if (isDragging) {
                    val parent = v.parent as? FrameLayout ?: return true
                    val newY = (downBtnY + dy)
                        .coerceAtLeast(0f)
                        .coerceAtMost((parent.height - v.height).toFloat())
                    (v.layoutParams as FrameLayout.LayoutParams).apply {
                        topMargin = newY.toInt()
                        gravity = Gravity.END or Gravity.TOP
                    }
                    v.requestLayout()
                }
                return true
            }
            MotionEvent.ACTION_UP -> {
                if (!isDragging) showLineDialog()
                return true
            }
        }
        return false
    }

    private fun showLineDialog() {
        val lines = StaticConfigManager.getLines()
        if (lines.isEmpty()) return

        val currentLine = StaticConfigManager.getCurrentLine()
        val currentIndex = lines.indexOf(currentLine)

        val proxyTag = if (ProxyManager.isRunning()) "  [代理已连接]" else "  [代理未连接]"

        val items = lines.mapIndexed { i, line ->
            val mark = if (i == currentIndex) "✓ " else "   "
            "$mark${line.name}  (${line.url})"
        }.toTypedArray()

        AlertDialog.Builder(activity)
            .setTitle("切换线路$proxyTag")
            .setItems(items) { _, which -> switchTo(which, lines) }
            .setNegativeButton("取消", null)
            .show()
    }

    private fun switchTo(index: Int, lines: List<ApiLine>) {
        StaticConfigManager.switchLine(index)
        button.background = ringDrawable(Color.parseColor(COLOR_BORDER_CONNECTED))
        activity.window.decorView.postDelayed({ updateBorderColor() }, 1500)
    }

    fun show() {
        val decorView = activity.window.decorView as? FrameLayout ?: return
        if (button.parent != null) return

        val params = FrameLayout.LayoutParams(btnSize, btnSize).apply {
            gravity = Gravity.END or Gravity.TOP
            topMargin = decorView.height / 3
            marginEnd = btnMargin
        }
        decorView.post {
            if (button.parent == null) {
                params.topMargin = decorView.height / 3
                decorView.addView(button, params)
            }
        }
        observeProxyStatus()
    }

    fun hide() {
        (button.parent as? ViewGroup)?.removeView(button)
    }

    fun refreshLines() {
        updateBorderColor()
    }

    private fun observeProxyStatus() {
        ProxyManager.statusLiveData.observe(activity) { status ->
            val color = when (status) {
                Callback.K_Connected -> COLOR_BORDER_CONNECTED
                Callback.K_Connecting -> COLOR_BORDER_CONNECTING
                else -> COLOR_BORDER_DEFAULT
            }
            button.background = ringDrawable(Color.parseColor(color))
        }
    }

    private fun updateBorderColor() {
        val color = if (ProxyManager.isRunning()) COLOR_BORDER_CONNECTED else COLOR_BORDER_DEFAULT
        button.background = ringDrawable(Color.parseColor(color))
    }
}
