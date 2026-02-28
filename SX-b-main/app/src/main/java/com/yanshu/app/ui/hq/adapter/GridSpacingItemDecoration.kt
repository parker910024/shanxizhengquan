package com.yanshu.app.ui.hq.adapter

import android.graphics.Rect
import android.view.View
import androidx.recyclerview.widget.RecyclerView

/**
 * 为 GridLayoutManager 提供均等间距：列间距相等，且与外边缘间距一致。
 * @param spanCount 列数
 * @param spacing   总间距（px），会被均分到每列两侧
 * @param includeEdge 是否在最左/最右列外侧也加相同间距
 */
class GridSpacingItemDecoration(
    private val spanCount: Int,
    private val spacing: Int,
    private val includeEdge: Boolean = false
) : RecyclerView.ItemDecoration() {

    override fun getItemOffsets(outRect: Rect, view: View, parent: RecyclerView, state: RecyclerView.State) {
        val position = parent.getChildAdapterPosition(view)
        val column = position % spanCount

        if (includeEdge) {
            outRect.left = spacing - column * spacing / spanCount
            outRect.right = (column + 1) * spacing / spanCount
        } else {
            outRect.left = column * spacing / spanCount
            outRect.right = spacing - (column + 1) * spacing / spanCount
        }

        if (position >= spanCount) {
            outRect.top = spacing
        }
    }
}
