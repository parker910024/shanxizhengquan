package com.yanshu.app.ui.home

import android.util.TypedValue
import android.view.ViewGroup
import android.widget.ImageView
import androidx.recyclerview.widget.RecyclerView
import com.yanshu.app.R
import com.yanshu.app.data.BannerItem
import com.yanshu.app.util.ImageUrlUtils
import com.youth.banner.adapter.BannerAdapter

/**
 * 首页轮播图适配器（对接 api/index/banner）
 */
class HomeBannerAdapter(
    data: List<BannerItem>,
    private val onItemClick: ((BannerItem) -> Unit)? = null
) : BannerAdapter<BannerItem, HomeBannerAdapter.BannerViewHolder>(data) {

    override fun onCreateHolder(parent: ViewGroup, viewType: Int): BannerViewHolder {
        val minHeightPx = TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP, 110f, parent.context.resources.displayMetrics
        ).toInt()
        val imageView = ImageView(parent.context).apply {
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
            minimumHeight = minHeightPx
            // Force all banners to fill the same container height.
            scaleType = ImageView.ScaleType.FIT_XY
        }
        return BannerViewHolder(imageView)
    }

    override fun onBindView(holder: BannerViewHolder, data: BannerItem, position: Int, size: Int) {
        holder.imageView.scaleType = ImageView.ScaleType.FIT_XY
        holder.imageView.setImageResource(R.drawable.bg_home_header_city)
        ImageUrlUtils.loadWithFallback(
            imageView = holder.imageView,
            path = data.image,
            placeholderResId = R.drawable.bg_home_header_city,
            errorResId = R.drawable.bg_home_header_city,
            adaptiveScaleType = false,
        )
        holder.imageView.setOnClickListener {
            onItemClick?.invoke(data)
        }
    }

    class BannerViewHolder(val imageView: ImageView) : RecyclerView.ViewHolder(imageView)
}
