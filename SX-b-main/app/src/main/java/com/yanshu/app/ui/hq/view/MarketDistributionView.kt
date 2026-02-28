package com.yanshu.app.ui.hq.view

import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.util.AttributeSet
import android.view.View
import androidx.core.content.ContextCompat
import com.yanshu.app.R
import com.yanshu.app.ui.hq.model.MarketDistribution

/**
 * 市场涨跌分布柱状图
 * 显示11个区间的涨跌分布：涨停、>7%、5-7%、3-5%、0-3%、平盘、0-3%、3-5%、5-7%、>7%、跌停
 */
class MarketDistributionView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : View(context, attrs, defStyleAttr) {

    private var distribution: MarketDistribution? = null

    // 柱状图颜色（从左到右：深红→浅红→灰→浅绿→深绿）
    private val barColors: IntArray = intArrayOf(
        ContextCompat.getColor(context, R.color.hq_bar_rise_stop),   // 涨停
        ContextCompat.getColor(context, R.color.hq_bar_rise_high),   // >7%
        ContextCompat.getColor(context, R.color.hq_bar_rise_mid),    // 5-7%
        ContextCompat.getColor(context, R.color.hq_bar_rise_low),    // 3-5%
        ContextCompat.getColor(context, R.color.hq_bar_rise_low),    // 0-3%
        ContextCompat.getColor(context, R.color.hq_bar_flat),        // 平盘
        ContextCompat.getColor(context, R.color.hq_bar_fall_low),    // 0-3%
        ContextCompat.getColor(context, R.color.hq_bar_fall_mid),    // 3-5%
        ContextCompat.getColor(context, R.color.hq_bar_fall_high),   // 5-7%
        ContextCompat.getColor(context, R.color.hq_bar_fall_high),   // >7%
        ContextCompat.getColor(context, R.color.hq_bar_fall_stop)    // 跌停
    )

    // 底部标签
    private val labels = arrayOf(
        "涨停", ">7%", "5~7%", "3~5%", "0~3%", "平盘", "0~3%", "3~5%", "5~7%", ">7%", "跌停"
    )

    // 画笔
    private val barPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.FILL
    }

    private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        textAlign = Paint.Align.CENTER
        color = ContextCompat.getColor(context, R.color.hq_text_gray)
    }

    private val valueTextPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        textAlign = Paint.Align.CENTER
    }

    // 尺寸
    private val density = resources.displayMetrics.density
    private val barCornerRadius = 2 * density
    private val barMinHeight = 4 * density
    private val valueTextSize = 10 * density
    private val labelTextSize = 10 * density
    private val topPadding = 24 * density      // 顶部留出数值空间
    private val bottomPadding = 20 * density   // 底部标签空间
    private val barGap = 4 * density           // 柱子间距

    private val barRect = RectF()

    init {
        textPaint.textSize = labelTextSize
        valueTextPaint.textSize = valueTextSize
    }

    /**
     * 设置分布数据
     */
    fun setData(data: MarketDistribution) {
        distribution = data
        invalidate()
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)

        val data = distribution ?: return
        val values = data.toList()
        val maxValue = data.maxValue().coerceAtLeast(1)

        val barCount = 11
        val availableWidth = width - paddingLeft - paddingRight
        val barWidth = (availableWidth - barGap * (barCount - 1)) / barCount
        val chartHeight = height - paddingTop - paddingBottom - topPadding - bottomPadding

        for (i in 0 until barCount) {
            val value = values[i]
            val barHeight = if (value > 0) {
                (value.toFloat() / maxValue * chartHeight).coerceAtLeast(barMinHeight)
            } else {
                barMinHeight
            }

            val left = paddingLeft + i * (barWidth + barGap)
            val right = left + barWidth
            val bottom = height - paddingBottom - bottomPadding
            val top = bottom - barHeight

            // 绘制柱子
            barPaint.color = barColors[i]
            barRect.set(left, top, right, bottom)
            canvas.drawRoundRect(barRect, barCornerRadius, barCornerRadius, barPaint)

            // 绘制柱子上方数值
            val centerX = left + barWidth / 2
            valueTextPaint.color = barColors[i]
            canvas.drawText(
                value.toString(),
                centerX,
                top - 6 * density,
                valueTextPaint
            )

            // 绘制底部标签
            canvas.drawText(
                labels[i],
                centerX,
                height - paddingBottom - 4 * density,
                textPaint
            )
        }
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val desiredHeight = (160 * density).toInt()
        val heightMode = MeasureSpec.getMode(heightMeasureSpec)
        val heightSize = MeasureSpec.getSize(heightMeasureSpec)

        val height = when (heightMode) {
            MeasureSpec.EXACTLY -> heightSize
            MeasureSpec.AT_MOST -> desiredHeight.coerceAtMost(heightSize)
            else -> desiredHeight
        }

        setMeasuredDimension(MeasureSpec.getSize(widthMeasureSpec), height)
    }
}
