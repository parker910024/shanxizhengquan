package ex.ss.lib.components.view

import android.app.Activity
import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Rect
import android.util.AttributeSet
import android.view.View
import android.view.ViewGroup

class WatermarkView @JvmOverloads constructor(
    context: Context, attrs: AttributeSet? = null, defStyleAttr: Int = 0
) : View(context, attrs, defStyleAttr) {

    private var watermarkViewConfig = WatermarkViewConfig()
    private val paint by lazy {
        Paint().apply {
            isAntiAlias = true
        }
    }

    fun setConfig(config: WatermarkViewConfig) {
        watermarkViewConfig = config
        postInvalidate()
    }


    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        canvas.drawRotate(watermarkViewConfig) {
            canvas.drawWatermarkBg(watermarkViewConfig)
            canvas.drawWatermarkText(watermarkViewConfig)
        }
    }

    private fun Canvas.drawWatermarkBg(config: WatermarkViewConfig) {
        drawColor(config.watermarkBgColor)
    }


    private fun Canvas.drawWatermarkText(config: WatermarkViewConfig) {
        if (config.watermarkText.isEmpty()) return
        paint.reset()
        paint.color = config.watermarkTextColor
        paint.textSize = config.watermarkTextSize
        val textBounds = Rect()
        paint.getTextBounds(config.watermarkText, 0, config.watermarkText.length, textBounds)
        val textWidth = textBounds.width() + config.watermarkHorizontalDistance
        val textHeight = textBounds.height() + config.watermarkVerticalDistance
        val horizontalCount =
            width / textWidth + 1 + config.watermarkHorizontalOffset + config.watermarkHorizontalOver
        val verticalCount =
            height / textHeight + 1 + config.watermarkVerticalOffset + config.watermarkVerticalOver
        for (horizontalIndex in 0 until horizontalCount) {
            for (verticalIndex in 0 until verticalCount) {
                val x = (horizontalIndex - config.watermarkHorizontalOffset) * textWidth * 1F
                val y = (verticalIndex - config.watermarkVerticalOffset) * textHeight * 1F
                drawText(config.watermarkText, x, y, paint)
            }
        }
    }

    private fun Canvas.drawRotate(config: WatermarkViewConfig, block: () -> Unit) {
        save()
        rotate(config.watermarkRotateDegree, width / 2F, height / 2F)
        block.invoke()
        restore()
    }
}


object WatermarkViewHelper {
    fun appendToActivity(
        activity: Activity,
        config: WatermarkViewConfig = WatermarkViewConfig()
    ): WatermarkView {
        return appendToViewGroup((activity.window.decorView as ViewGroup), config)
    }

    fun appendToViewGroup(viewGroup: ViewGroup, config: WatermarkViewConfig): WatermarkView {
        val context = viewGroup.context
        return WatermarkView(context).apply {
            setConfig(config)
            viewGroup.addView(
                this,
                ViewGroup.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT
                )
            )
        }
    }
}


data class WatermarkViewConfig(
    var watermarkBgColor: Int = Color.TRANSPARENT, //水印背景颜色
    var watermarkText: String = "",//水印文字
    var watermarkTextColor: Int = Color.GRAY, //水印文字颜色
    var watermarkTextSize: Float = 0F,//水印文字大小
    var watermarkHorizontalDistance: Int = 0,//水印水平间隔
    var watermarkVerticalDistance: Int = 0,//水印垂直间隔
    var watermarkRotateDegree: Float = 0F,//水印旋转角度
    //旋转之后，会有空白区域，可以上下左右多绘制一些
    var watermarkHorizontalOffset: Int = 0,//水印左侧绘制列数
    var watermarkHorizontalOver: Int = 0,//水印右侧绘制列数
    var watermarkVerticalOffset: Int = 0,//水印上方绘制列数
    var watermarkVerticalOver: Int = 0,//水印下方绘制列数
)
