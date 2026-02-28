package ex.ss.lib.base.extension

import android.content.Context
import android.util.DisplayMetrics
import android.util.TypedValue

object DimensExtension {

    private lateinit var displayMetrics: DisplayMetrics

    fun init(context: Context) {
        displayMetrics = context.resources.displayMetrics
    }

    fun dpToPx(value: Float): Float {
        return TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, value, displayMetrics)
    }

    fun spToPx(value: Float): Float {
        return TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, value, displayMetrics)
    }

    fun getScreenWidth(): Int {
        return displayMetrics.widthPixels
    }

    fun getScreenHeight(): Int {
        return displayMetrics.heightPixels
    }
}

val Int.dp: Int
    get() = DimensExtension.dpToPx(this.toFloat()).toInt()

val Float.dp: Float
    get() = DimensExtension.dpToPx(this)

val Int.sp: Int
    get() = DimensExtension.spToPx(this.toFloat()).toInt()

val Float.sp: Float
    get() = DimensExtension.spToPx(this)

val screenWidth: Int
    get() = DimensExtension.getScreenWidth()

val screenHeight: Int
    get() = DimensExtension.getScreenHeight()
