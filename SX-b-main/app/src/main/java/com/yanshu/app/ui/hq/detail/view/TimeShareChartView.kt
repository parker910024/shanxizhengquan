package com.yanshu.app.ui.hq.detail.view

import android.content.Context
import android.util.AttributeSet
import android.widget.FrameLayout
import com.github.mikephil.charting.charts.LineChart
import com.github.mikephil.charting.components.XAxis
import com.github.mikephil.charting.data.Entry
import com.github.mikephil.charting.data.LineData
import com.github.mikephil.charting.data.LineDataSet
import com.github.mikephil.charting.formatter.ValueFormatter
import com.yanshu.app.R
import com.yanshu.app.ui.hq.detail.model.TimeSharePoint
import kotlin.math.max
import kotlin.math.min

class TimeShareChartView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
) : FrameLayout(context, attrs) {

    private val chart = LineChart(context)

    init {
        addView(chart, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT))
        setupChart()
    }

    fun setData(points: List<TimeSharePoint>, preClose: Double?) {
        if (points.isEmpty()) {
            chart.clear()
            chart.setNoDataText("No time-share data")
            return
        }

        val priceEntries = points.mapIndexed { index, point ->
            Entry(index.toFloat(), point.price.toFloat())
        }
        val avgEntries = points.mapIndexed { index, point ->
            Entry(index.toFloat(), point.avgPrice.toFloat())
        }

        val priceDataSet = LineDataSet(priceEntries, "Price").apply {
            color = resources.getColor(R.color.hq_rise_color, null)
            lineWidth = 1.4f
            setDrawCircles(false)
            setDrawValues(false)
            setDrawFilled(true)
            fillColor = resources.getColor(R.color.hq_rise_color, null)
            fillAlpha = 36
            highLightColor = resources.getColor(R.color.hq_text_gray, null)
        }
        val avgDataSet = LineDataSet(avgEntries, "Avg").apply {
            color = resources.getColor(R.color.hq_indicator_color, null)
            lineWidth = 1f
            setDrawCircles(false)
            setDrawValues(false)
            setDrawFilled(false)
        }

        chart.data = LineData(priceDataSet, avgDataSet)
        chart.xAxis.valueFormatter = object : ValueFormatter() {
            override fun getFormattedValue(value: Float): String {
                val index = value.toInt()
                val raw = points.getOrNull(index)?.time.orEmpty()
                return raw.substringAfter(' ').substringBefore(':').ifBlank { raw.takeLast(5) }
            }
        }

        updateAxisRange(points, preClose)
        chart.invalidate()
    }

    private fun setupChart() {
        chart.description.isEnabled = false
        chart.legend.isEnabled = false
        chart.setNoDataText("No time-share data")
        chart.setScaleEnabled(false)
        chart.setPinchZoom(false)
        chart.setTouchEnabled(true)
        chart.axisRight.isEnabled = false

        chart.xAxis.apply {
            position = XAxis.XAxisPosition.BOTTOM
            setDrawGridLines(false)
            granularity = 1f
            labelCount = 5
            textColor = resources.getColor(R.color.hq_text_gray, null)
            valueFormatter = object : ValueFormatter() {
                override fun getFormattedValue(value: Float): String = ""
            }
        }

        chart.axisLeft.apply {
            textColor = resources.getColor(R.color.hq_text_gray, null)
            setDrawGridLines(true)
            gridColor = resources.getColor(R.color.hq_divider_color, null)
            labelCount = 5
        }
    }

    private fun updateAxisRange(points: List<TimeSharePoint>, preClose: Double?) {
        val prices = points.map { it.price }
        val minValue = prices.minOrNull() ?: return
        val maxValue = prices.maxOrNull() ?: return

        val center = preClose ?: (minValue + maxValue) / 2.0
        val margin = max(0.01, max(maxValue - center, center - minValue) * 1.05)
        val axisMin = min(minValue, center - margin)
        val axisMax = max(maxValue, center + margin)

        chart.axisLeft.axisMinimum = axisMin.toFloat()
        chart.axisLeft.axisMaximum = axisMax.toFloat()
    }
}
