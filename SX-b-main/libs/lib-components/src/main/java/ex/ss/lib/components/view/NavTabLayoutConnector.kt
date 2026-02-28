package ex.ss.lib.components.view

import android.content.Context
import android.view.LayoutInflater
import android.widget.ImageView
import android.widget.TextView
import androidx.annotation.ColorRes
import androidx.annotation.DrawableRes
import androidx.core.content.ContextCompat
import androidx.core.view.isVisible
import androidx.viewpager2.widget.ViewPager2
import com.google.android.material.tabs.TabLayout
import com.google.android.material.tabs.TabLayoutMediator
import ex.ss.lib.components.databinding.ItemTabViewBinding

typealias OnTabConfig = (selected: Boolean, titleView: TextView, iconView: ImageView) -> Unit

object NavTabLayoutConnector {

    private val navTabItems = mutableListOf<Pair<ItemTabViewBinding, NavTabItem>>()

    fun bind(
        tabLayout: TabLayout,
        viewPager2: ViewPager2,
        list: List<NavTabItem>,
        onTabConfig: OnTabConfig = { _, _, _ -> },
    ) {
        navTabItems.clear()
        initTabLayout(tabLayout, onTabConfig)
        TabLayoutMediator(tabLayout, viewPager2) { tab, position ->
            val item = list[position]
            val binding = createTabView(tabLayout.context, list[position], onTabConfig)
            tab.customView = binding.root
            navTabItems.add(position, binding to item)
        }.attach()
    }

    private fun createTabView(
        context: Context,
        item: NavTabItem,
        onTabConfig: OnTabConfig,
    ): ItemTabViewBinding {
        val binding = ItemTabViewBinding.inflate(LayoutInflater.from(context))
        configTabView(binding, item, false, onTabConfig)
        return binding
    }

    private fun configTabView(
        binding: ItemTabViewBinding,
        item: NavTabItem,
        selected: Boolean,
        onTabConfig: OnTabConfig,
    ) {
        binding.iv.apply {
            isVisible = item.icon != 0
            setImageResource(item.icon)
            isSelected = selected
        }
        binding.tv.apply {
            text = item.title
            textSize = item.titleSize.toFloat()
            setTextColor(ContextCompat.getColorStateList(context, item.textColor))
            isSelected = selected
        }
        onTabConfig.invoke(selected, binding.tv, binding.iv)
    }

    private fun initTabLayout(tabLayout: TabLayout, onTabConfig: OnTabConfig) {
        tabLayout.setSelectedTabIndicator(null)
        tabLayout.addOnTabSelectedListener(object : TabLayout.OnTabSelectedListener {
            override fun onTabSelected(tab: TabLayout.Tab?) {
                tab?.also { updateTabSelected(it.position, onTabConfig) }
            }

            override fun onTabUnselected(tab: TabLayout.Tab?) {

            }

            override fun onTabReselected(tab: TabLayout.Tab?) {

            }
        })
    }

    private fun updateTabSelected(selectedPosition: Int, onTabConfig: OnTabConfig) {
        navTabItems.onEachIndexed { index, pair ->
            configTabView(pair.first, pair.second, selectedPosition == index, onTabConfig)
        }
    }
}

data class NavTabItem(
    val title: String = "",
    val titleSize: Int = 13,
    @ColorRes val textColor: Int = 0,
    @DrawableRes val icon: Int = 0,
)