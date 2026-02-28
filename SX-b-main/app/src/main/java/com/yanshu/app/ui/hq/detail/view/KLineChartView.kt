package com.yanshu.app.ui.hq.detail.view

import android.content.Context
import android.graphics.Paint
import android.util.AttributeSet
import android.widget.FrameLayout
import com.github.mikephil.charting.charts.CandleStickChart
import com.github.mikephil.charting.components.XAxis
import com.github.mikephil.charting.data.CandleData
import com.github.mikephil.charting.data.CandleDataSet
import com.github.mikephil.charting.data.CandleEntry
import com.github.mikephil.charting.formatter.ValueFormatter
import com.yanshu.app.R
import com.yanshu.app.ui.hq.detail.model.KLinePoint

class KLineChartView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
) : FrameLayout(context, attrs) {

    private val chart = CandleStickChart(context)

    init {
        addView(chart, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT))
        setupChart()
    }

    fun setData(points: List<KLinePoint>) {
        if (points.isEmpty()) {
            chart.clear()
            chart.setNoDataText("No K-line data")
            return
        }

        val entries = points.mapIndexed { index, point ->
            CandleEntry(
                index.toFloat(),
                point.high.toFloat(),
                point.low.toFloat(),
                point.open.toFloat(),
                point.close.toFloat(),
            )
        }

        val dataSet = CandleDataSet(entries, "K line").apply {
            shadowColorSameAsCandle = true
            increasingColor = resources.getColor(R.color.hq_rise_color, null)
            increasingPaintStyle = Paint.Style.FILL
            decreasingColor = resources.getColor(R.color.hq_fall_color, null)
            decreasingPaintStyle = Paint.Style.FILL
            neutralColor = resources.getColor(R.color.hq_text_gray, null)
            setDrawValues(false)
            shadowWidth = 0.7f
        }
        chart.data = CandleData(dataSet)
        chart.xAxis.valueFormatter = object : ValueFormatter() {
            override fun getFormattedValue(value: Float): String {
                val index = value.toInt()
                val raw = points.getOrNull(index)?.time.orEmpty()
                val datePart = raw.substringBefore(' ')
                return if (datePart.length >= 10) datePart.substring(5) else datePart
            }
        }
        chart.setVisibleXRangeMaximum(60f)
        chart.moveViewToX((points.size - 1).coerceAtLeast(0).toFloat())
        chart.invalidate()
    }

    private fun setupChart() {
        chart.description.isEnabled = false
        chart.legend.isEnabled = false
        chart.setNoDataText("No K-line data")
        chart.setScaleEnabled(true)
        chart.setPinchZoom(true)
        chart.axisRight.isEnabled = false

        chart.xAxis.apply {
            position = XAxis.XAxisPosition.BOTTOM
            textColor = resources.getColor(R.color.hq_text_gray, null)
            setDrawGridLines(false)
            granularity = 1f
        }

        chart.axisLeft.apply {
            textColor = resources.getColor(R.color.hq_text_gray, null)
            setDrawGridLines(true)
            gridColor = resources.getColor(R.color.hq_divider_color, null)
            labelCount = 5
        }
    }
}
