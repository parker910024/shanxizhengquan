package com.yanshu.app.util

import android.util.Log
import android.widget.ImageView
import androidx.core.content.ContextCompat
import coil.load
import com.yanshu.app.BuildConfig
import com.yanshu.app.config.AppConfigCenter
import okhttp3.Headers
import android.graphics.drawable.Drawable

object ImageUrlUtils {

    private const val TAG = "ImageUrlUtils"
    @Volatile
    private var runtimeImageBaseUrl: String? = null

    fun updateImageBaseUrl(url: String?) {
        val normalized = url.orEmpty().trim().trimEnd('/')
        runtimeImageBaseUrl = normalized.ifEmpty { null }
        if (!normalized.isNullOrBlank()) {
            Log.d(TAG, "image base url updated: $normalized")
        }
    }

    private fun currentImageBaseUrl(): String {
        return runtimeImageBaseUrl ?: BuildConfig.IMAGE_BASE_URL.trimEnd('/')
    }

    private fun applyAdaptiveScaleType(imageView: ImageView, drawable: Drawable?) {
        if (drawable == null) return
        val imageW = drawable.intrinsicWidth
        val imageH = drawable.intrinsicHeight
        if (imageW <= 0 || imageH <= 0) return

        val viewW = imageView.width.takeIf { it > 0 } ?: imageView.resources.displayMetrics.widthPixels
        val viewH = imageView.height.takeIf { it > 0 }
            ?: imageView.layoutParams?.height?.takeIf { it > 0 }
            ?: return
        if (viewH <= 0) return

        val imageRatio = imageW.toFloat() / imageH.toFloat()
        val viewRatio = viewW.toFloat() / viewH.toFloat()
        val targetScaleType =
            if (imageRatio > viewRatio * 1.18f) ImageView.ScaleType.FIT_CENTER
            else ImageView.ScaleType.CENTER_CROP

        if (imageView.scaleType != targetScaleType) {
            imageView.scaleType = targetScaleType
            Log.d(
                TAG,
                "adaptive scaleType=${targetScaleType.name}, imageRatio=$imageRatio, viewRatio=$viewRatio"
            )
        }
    }

    fun api(path: String?): String {
        val raw = path.orEmpty().trim()
        if (raw.isEmpty()) return ""
        if (raw.startsWith("http://") || raw.startsWith("https://")) return raw
        return AppConfigCenter.baseDomain.trimEnd('/') + "/" + raw.trimStart('/')
    }

    fun oss(path: String?): String {
        val raw = path.orEmpty().trim()
        if (raw.isEmpty()) return ""
        if (raw.startsWith("http://") || raw.startsWith("https://")) return raw
        return currentImageBaseUrl() + "/" + raw.trimStart('/')
    }

    fun loadWithFallback(
        imageView: ImageView,
        path: String?,
        placeholderResId: Int = 0,
        errorResId: Int = placeholderResId,
        adaptiveScaleType: Boolean = true,
    ) {
        val ossUrl = oss(path)
        val placeholderDrawable = if (placeholderResId != 0) {
            ContextCompat.getDrawable(imageView.context, placeholderResId)
        } else {
            null
        }
        val errorDrawable = if (errorResId != 0) {
            ContextCompat.getDrawable(imageView.context, errorResId)
        } else {
            null
        }
        if (ossUrl.isEmpty()) {
            imageView.setImageDrawable(placeholderDrawable)
            return
        }
        val ossReferer = currentImageBaseUrl() + "/"
        val apiReferer = AppConfigCenter.baseDomain.trimEnd('/') + "/"
        imageView.load(ossUrl) {
            if (placeholderDrawable != null) placeholder(placeholderDrawable)
            if (errorDrawable != null) error(errorDrawable)
            headers(
                Headers.Builder()
                    .add("Referer", ossReferer)
                    .build()
            )
            listener(
                onSuccess = { _, result ->
                    if (adaptiveScaleType) {
                        applyAdaptiveScaleType(imageView, result.drawable)
                    }
                },
                onError = { _, result ->
                    Log.w(TAG, "load oss failed: $ossUrl, reason=${result.throwable.message}")
                    val apiUrl = api(path)
                    if (apiUrl.isNotEmpty() && apiUrl != ossUrl) {
                        imageView.load(apiUrl) {
                            if (placeholderDrawable != null) placeholder(placeholderDrawable)
                            if (errorDrawable != null) error(errorDrawable)
                            headers(
                                Headers.Builder()
                                    .add("Referer", apiReferer)
                                    .build()
                            )
                            listener(
                                onSuccess = { _, apiSuccess ->
                                    if (adaptiveScaleType) {
                                        applyAdaptiveScaleType(imageView, apiSuccess.drawable)
                                    }
                                },
                                onError = { _, apiResult ->
                                    Log.w(
                                        TAG,
                                        "load api failed: $apiUrl, reason=${apiResult.throwable.message}"
                                    )
                                }
                            )
                        }
                    }
                }
            )
        }
    }

    /**
     * 直接用接口同源 BASE_URL 加载（用于首页轮播等与接口同域的资源）.
     * @param placeholderResId 加载中/失败时占位图，0 表示不设置
     * @param errorResId 加载失败时显示图，0 表示不设置
     */
    fun loadFromApi(
        imageView: ImageView,
        path: String?,
        placeholderResId: Int = 0,
        errorResId: Int = 0,
    ) {
        val url = api(path)
        if (url.isEmpty()) {
            imageView.setImageDrawable(
                if (placeholderResId != 0) ContextCompat.getDrawable(imageView.context, placeholderResId) else null
            )
            return
        }
        imageView.load(url) {
            if (placeholderResId != 0) placeholder(ContextCompat.getDrawable(imageView.context, placeholderResId))
            if (errorResId != 0) error(ContextCompat.getDrawable(imageView.context, errorResId))
        }
    }
}
