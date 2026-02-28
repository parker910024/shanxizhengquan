package com.yanshu.app.util

import android.content.Context
import android.content.ContextWrapper
import android.view.View
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.LifecycleOwner
import androidx.viewpager2.widget.ViewPager2
import java.util.concurrent.atomic.AtomicInteger

object TabWrapper {

    private val currentIndex = AtomicInteger(-1)
    private val tabsMapper = mutableMapOf<Int, TabItem>()
    private val listenerMapper = mutableListOf<OnTabSelectListener>()

    fun register(item: TabItem): TabItem {
        return register(item.index, item)
    }

    fun register(index: Int, item: TabItem): TabItem {
        tabsMapper[index] = item
        return item
    }

    fun selectTab(index: Int) {
        tabSelected(index, true)
    }

    fun onTabSelectListener(listener: OnTabSelectListener) {
        listenerMapper.add(listener)
    }

    private fun tabSelected(index: Int, isClick: Boolean = true) {
        if (currentIndex.get() != index) {
            currentIndex.set(index)  // 添加：更新当前索引
            for (item in tabsMapper) {
                item.value.onSelect(item.key == index)
            }
            for (listener in listenerMapper) {
                listener.onTabSelect(index, isClick)
            }
        }
    }

    fun bindViewPager(
        viewPager2: ViewPager2,
        smoothScroll: Boolean = false,
        onTabSelect: (Int) -> Unit = {},
    ) {
        listenerMapper.add(object : OnTabSelectListener {
            override fun onTabSelect(position: Int, isClick: Boolean) {
                onTabSelect.invoke(position)
                if (isClick) viewPager2.setCurrentItem(position, smoothScroll)
            }
        })
        viewPager2.context.getLifecycle()?.also { lifecycle ->
            lifecycle.addObserver(LifecycleEventObserver { _, event ->
                if (event == Lifecycle.Event.ON_DESTROY) {
                    listenerMapper.clear()
                }
            })
        }
    }

    internal fun Context?.getLifecycle(): Lifecycle? {
        var context: Context? = this
        while (true) {
            when (context) {
                is LifecycleOwner -> return context.lifecycle
                !is ContextWrapper -> return null
                else -> context = context.baseContext
            }
        }
    }
}

interface OnTabSelectListener {
    fun onTabSelect(position: Int, isClick: Boolean)
}

fun createTabItem(
    index: Int,
    clickViews: List<View>,
    onSelect: (select: Boolean) -> Unit,
): TabItem {
    return object : TabItem(index) {
        override val clickViews: List<View>
            get() = clickViews

        override fun onSelect(select: Boolean) {
            clickViews.onEach { it.isSelected = select }
            onSelect.invoke(select)
        }
    }
}

abstract class TabItem(val index: Int) {
    abstract fun onSelect(select: Boolean)
    abstract val clickViews: List<View>
    private var onClickCheck: (() -> Boolean)? = null

    init {
        for (clickView in clickViews) {
            clickView.setOnClickListener {
                if (onClickCheck?.invoke() != false) {
                    TabWrapper.selectTab(index)
                }
            }
        }
    }

    fun setOnClickCheck(onCheck: () -> Boolean): TabItem {
        this.onClickCheck = onCheck
        return this
    }
}