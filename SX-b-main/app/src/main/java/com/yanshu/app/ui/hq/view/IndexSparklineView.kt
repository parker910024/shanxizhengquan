package com.yanshu.app.ui.hq.view

import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.util.AttributeSet
import android.view.View
import androidx.core.content.ContextCompat
import com.yanshu.app.R

/**
 * 指数卡片迷你走势图（轻量 Canvas 实现，无库依赖，无坐标轴，无交互）
 * 数据来源：东方财富 trends2/get API，price 字段列表
 */
class IndexSparklineView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0,
) : View(context, attrs, defStyleAttr) {

    private val linePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = 1.5f
        strokeJoin = Paint.Join.ROUND
        strokeCap = Paint.Cap.ROUND
    }

    private val fillPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.FILL
    }

    private var prices: List<Float> = emptyList()
    private var isUp: Boolean = true
    private val path = Path()
    private val fillPath = Path()

    fun setData(prices: List<Float>, isUp: Boolean) {
        this.prices = prices
        this.isUp = isUp
        val lineColor = ContextCompat.getColor(
            context,
            if (isUp) R.color.hq_rise_color else R.color.hq_fall_color,
        )
        linePaint.color = lineColor
        fillPaint.color = lineColor
        fillPaint.alpha = 40
        invalidate()
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        if (prices.size < 2) return

        val w = width.toFloat()
        val h = height.toFloat()
        if (w == 0f || h == 0f) return

        val minVal = prices.min()
        val maxVal = prices.max()
        val range = maxVal - minVal
        val effectiveRange = if (range < 0.001f) 1f else range

        val stepX = w / (prices.size - 1).toFloat()

        fun xAt(i: Int) = i * stepX
        fun yAt(price: Float) = h - (price - minVal) / effectiveRange * h * 0.85f - h * 0.075f

        path.reset()
        fillPath.reset()

        val x0 = xAt(0)
        val y0 = yAt(prices[0])
        path.moveTo(x0, y0)
        fillPath.moveTo(x0, h)
        fillPath.lineTo(x0, y0)

        for (i in 1 until prices.size) {
            val x = xAt(i)
            val y = yAt(prices[i])
            path.lineTo(x, y)
            fillPath.lineTo(x, y)
        }

        fillPath.lineTo(xAt(prices.size - 1), h)
        fillPath.close()

        canvas.drawPath(fillPath, fillPaint)
        canvas.drawPath(path, linePaint)
    }
}
