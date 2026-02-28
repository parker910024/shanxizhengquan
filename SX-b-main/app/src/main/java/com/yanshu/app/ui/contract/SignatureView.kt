package com.yanshu.app.ui.contract

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.util.AttributeSet
import android.view.MotionEvent
import android.view.View
import kotlin.math.ceil
import kotlin.math.floor
import kotlin.math.max
import kotlin.math.min

class SignatureView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0,
) : View(context, attrs, defStyleAttr) {

    private val paint = Paint().apply {
        isAntiAlias = true
        isDither = true
        color = Color.BLACK
        style = Paint.Style.STROKE
        strokeJoin = Paint.Join.ROUND
        strokeCap = Paint.Cap.ROUND
        strokeWidth = 8f
    }

    private val path = Path()
    private var canvasBitmap: Bitmap? = null
    private var drawCanvas: Canvas? = null
    private var lastX = 0f
    private var lastY = 0f
    private var hasSignature = false
    private var minDrawX = Float.MAX_VALUE
    private var minDrawY = Float.MAX_VALUE
    private var maxDrawX = Float.MIN_VALUE
    private var maxDrawY = Float.MIN_VALUE

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        super.onSizeChanged(w, h, oldw, oldh)
        if (w > 0 && h > 0) {
            canvasBitmap?.recycle()
            canvasBitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
            drawCanvas = Canvas(canvasBitmap!!)
            drawCanvas?.drawColor(Color.WHITE)
            resetDrawBounds()
        }
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        canvasBitmap?.let { canvas.drawBitmap(it, 0f, 0f, null) }
        canvas.drawPath(path, paint)
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        val x = event.x
        val y = event.y
        when (event.action) {
            MotionEvent.ACTION_DOWN -> {
                path.moveTo(x, y)
                lastX = x
                lastY = y
                hasSignature = true
                updateDrawBounds(x, y)
                return true
            }

            MotionEvent.ACTION_MOVE -> {
                path.quadTo(lastX, lastY, (x + lastX) / 2, (y + lastY) / 2)
                updateDrawBounds(lastX, lastY)
                updateDrawBounds((x + lastX) / 2, (y + lastY) / 2)
                lastX = x
                lastY = y
                updateDrawBounds(x, y)
            }

            MotionEvent.ACTION_UP -> {
                path.lineTo(x, y)
                updateDrawBounds(x, y)
                drawCanvas?.drawPath(path, paint)
                path.reset()
            }
        }
        invalidate()
        return true
    }

    fun clear() {
        path.reset()
        canvasBitmap?.eraseColor(Color.WHITE)
        hasSignature = false
        resetDrawBounds()
        invalidate()
    }

    fun hasSignature(): Boolean = hasSignature

    fun getCroppedSignatureBitmap(): Bitmap? {
        val bitmap = canvasBitmap ?: return null
        if (!hasSignature || minDrawX == Float.MAX_VALUE || minDrawY == Float.MAX_VALUE) {
            return null
        }
        val padding = 20
        val left = max(0, floor(minDrawX).toInt() - padding)
        val top = max(0, floor(minDrawY).toInt() - padding)
        val right = min(bitmap.width - 1, ceil(maxDrawX).toInt() + padding)
        val bottom = min(bitmap.height - 1, ceil(maxDrawY).toInt() + padding)

        val cropWidth = max(1, right - left + 1)
        val cropHeight = max(1, bottom - top + 1)
        if (left == 0 && top == 0 && cropWidth == bitmap.width && cropHeight == bitmap.height) {
            return bitmap
        }
        return Bitmap.createBitmap(bitmap, left, top, cropWidth, cropHeight)
    }

    private fun resetDrawBounds() {
        minDrawX = Float.MAX_VALUE
        minDrawY = Float.MAX_VALUE
        maxDrawX = Float.MIN_VALUE
        maxDrawY = Float.MIN_VALUE
    }

    private fun updateDrawBounds(x: Float, y: Float) {
        minDrawX = min(minDrawX, x)
        minDrawY = min(minDrawY, y)
        maxDrawX = max(maxDrawX, x)
        maxDrawY = max(maxDrawY, y)
    }
}
