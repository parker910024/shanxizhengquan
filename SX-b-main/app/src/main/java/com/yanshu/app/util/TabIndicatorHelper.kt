package com.yanshu.app.util

import android.view.View

/**
 * Tab 指示器辅助工具类
 * 用于处理 Tab 切换时指示器的动画移动
 * 
 * 支持两种模式:
 * 1. 动态模式 - 根据 Tab View 的实际位置计算指示器位置
 * 2. 固定宽度模式 - 根据提供的固定宽度(dp)计算指示器位置
 */
class TabIndicatorHelper private constructor(
    private val tabs: List<View>,
    private val indicator: View,
    private val indicatorWidthDp: Int,
    private val fixedColumnWidthsDp: List<Int>?
) {
    private val density: Float by lazy {
        indicator.context.resources.displayMetrics.density
    }
    
    // 固定宽度模式下的列起始位置 (dp)
    private val columnPositions: List<Int> by lazy {
        fixedColumnWidthsDp?.let { widths ->
            var sum = 0
            widths.map { width ->
                val pos = sum
                sum += width
                pos
            }
        } ?: emptyList()
    }

    /**
     * 初始化，在布局完成后调用
     * @param defaultIndex 默认选中的 Tab 索引
     */
    fun init(defaultIndex: Int = 0) {
        indicator.post {
            selectTab(defaultIndex, animate = false)
        }
    }

    /**
     * 选中指定 Tab，移动指示器
     * @param index Tab 索引
     * @param animate 是否使用动画，默认 true
     */
    fun selectTab(index: Int, animate: Boolean = true) {
        if (index < 0 || index >= tabs.size) return
        
        val indicatorWidth = indicatorWidthDp * density
        val indicatorX: Float
        
        if (fixedColumnWidthsDp != null && index < fixedColumnWidthsDp.size) {
            // 固定宽度模式
            val tabWidth = fixedColumnWidthsDp[index] * density
            val tabStartX = columnPositions[index] * density
            indicatorX = tabStartX + (tabWidth - indicatorWidth) / 2f
        } else {
            // 动态模式
            val tab = tabs[index]
            indicatorX = tab.left + (tab.width - indicatorWidth) / 2f
        }
        
        if (animate) {
            indicator.animate()
                .translationX(indicatorX)
                .setDuration(200)
                .start()
        } else {
            indicator.translationX = indicatorX
        }
    }

    companion object {
        /**
         * 创建动态模式的 TabIndicatorHelper
         * 根据 Tab View 的实际位置计算指示器位置
         */
        fun create(
            tabs: List<View>,
            indicator: View,
            indicatorWidthDp: Int = 24
        ): TabIndicatorHelper {
            return TabIndicatorHelper(tabs, indicator, indicatorWidthDp, null)
        }
        
        /**
         * 创建固定宽度模式的 TabIndicatorHelper
         * 根据提供的固定宽度(dp)计算指示器位置
         * @param columnWidthsDp 每个 Tab 的宽度列表 (dp)
         */
        fun createWithFixedWidths(
            tabs: List<View>,
            indicator: View,
            columnWidthsDp: List<Int>,
            indicatorWidthDp: Int = 24
        ): TabIndicatorHelper {
            return TabIndicatorHelper(tabs, indicator, indicatorWidthDp, columnWidthsDp)
        }
    }
}
