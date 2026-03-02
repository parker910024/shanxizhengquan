package com.yanshu.app.ui.contract

import android.content.Context
import android.util.AttributeSet
import android.view.MotionEvent
import android.webkit.WebView

class NoHorizontalScrollWebView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0,
) : WebView(context, attrs, defStyleAttr) {

    init {
        isHorizontalScrollBarEnabled = false
        settings.apply {
            setSupportZoom(false)
            builtInZoomControls = false
            displayZoomControls = false
        }
    }

    override fun computeHorizontalScrollRange(): Int {
        return computeHorizontalScrollExtent()
    }

    override fun scrollTo(x: Int, y: Int) {
        // Lock horizontal scrolling to 0 and keep vertical scrolling.
        super.scrollTo(0, y)
    }

    override fun overScrollBy(
        deltaX: Int,
        deltaY: Int,
        scrollX: Int,
        scrollY: Int,
        scrollRangeX: Int,
        scrollRangeY: Int,
        maxOverScrollX: Int,
        maxOverScrollY: Int,
        isTouchEvent: Boolean,
    ): Boolean {
        return super.overScrollBy(
            0,
            deltaY,
            0,
            scrollY,
            0,
            scrollRangeY,
            0,
            maxOverScrollY,
            isTouchEvent,
        )
    }

    override fun onInterceptTouchEvent(ev: MotionEvent): Boolean {
        if (ev.pointerCount > 1) {
            return true
        }
        return super.onInterceptTouchEvent(ev)
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        if (event.pointerCount > 1) {
            return true
        }
        return super.onTouchEvent(event)
    }
}
