package ex.ss.lib.components.view

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

    fun register(item: TabItem) {
        register(item.index, item)
    }

    fun register(index: Int, item: TabItem) {
        tabsMapper[index] = item
    }

    fun selectTab(index: Int) {
        if (currentIndex.get() != index) {
            for (item in tabsMapper) {
                item.value.onSelect(item.key == index)
            }
            for (listener in listenerMapper) {
                listener.onTabSelect(index)
            }
        }
    }

    fun onTabSelectListener(listener: OnTabSelectListener) {
        listenerMapper.add(listener)
    }

    fun bindViewPager(
        viewPager2: ViewPager2,
        smoothScroll: Boolean = false,
        onTabSelect: (Int) -> Unit = {}
    ) {
        listenerMapper.add(object : OnTabSelectListener {
            override fun onTabSelect(position: Int) {
                onTabSelect.invoke(position)
                viewPager2.setCurrentItem(position, smoothScroll)
            }
        })
        viewPager2.context.getLifecycle()?.also { lifecycle ->
            lifecycle.addObserver(LifecycleEventObserver { source, event ->
                if (event == Lifecycle.Event.ON_DESTROY) {
                    listenerMapper.clear()
                }
            })
        }
    }

    private fun Context?.getLifecycle(): Lifecycle? {
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
    fun onTabSelect(position: Int)
}

fun createTabItem(
    index: Int, clickViews: List<View>, onSelect: (select: Boolean) -> Unit = {}
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

    init {
        for (clickView in clickViews) {
            clickView.setOnClickListener {
                TabWrapper.selectTab(index)
            }
        }
    }

}
