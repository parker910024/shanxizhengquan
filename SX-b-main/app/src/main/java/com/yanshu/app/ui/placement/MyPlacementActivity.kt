package com.yanshu.app.ui.placement

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.view.View
import android.widget.TextView
import androidx.recyclerview.widget.LinearLayoutManager
import com.yanshu.app.R
import com.yanshu.app.base.BasicActivity
import com.yanshu.app.databinding.ActivityMyPlacementBinding
import com.yanshu.app.model.IPOViewModel
import ex.ss.lib.base.extension.viewBinding

/**
 * 配售记录页面
 */
class MyPlacementActivity : BasicActivity<ActivityMyPlacementBinding>() {

    override val binding: ActivityMyPlacementBinding by viewBinding()
    private lateinit var adapter: MyPlacementAdapter
    private var currentTab = 0 // 0=申购中 1=中签 2=未中签

    companion object {
        fun start(context: Context) {
            context.startActivity(Intent(context, MyPlacementActivity::class.java))
        }
    }

    override fun initView() {
        binding.ivBack.setOnClickListener { finish() }

        adapter = MyPlacementAdapter()
        binding.rvList.layoutManager = LinearLayoutManager(this)
        binding.rvList.adapter = adapter

        val tabs = listOf(binding.tabSubscribing, binding.tabWon, binding.tabLost)
        tabs.forEachIndexed { index, tab ->
            tab.setOnClickListener { selectTab(index, tabs) }
        }
        updateTabUI(tabs)
        observeViewModel()
    }

    override fun initData() {
        loadData()
    }

    private fun selectTab(index: Int, tabs: List<TextView>) {
        if (currentTab != index) {
            currentTab = index
            updateTabUI(tabs)
            loadData()
        }
    }

    private fun updateTabUI(tabs: List<TextView>) {
        val selectedColor = Color.parseColor("#FB443C")
        val normalColor = Color.parseColor("#6D6D6D")
        tabs.forEachIndexed { i, tab ->
            val selected = i == currentTab
            tab.setTextColor(if (selected) selectedColor else normalColor)
            tab.setTypeface(null, if (selected) Typeface.BOLD else Typeface.NORMAL)
            tab.setBackgroundResource(
                if (selected) R.drawable.bg_ipo_tab_selected_red
                else R.drawable.bg_ipo_tab_normal_red
            )
        }
    }

    private fun loadData() {
        IPOViewModel.loadMyPlacementList(status = currentTab)
    }

    private fun observeViewModel() {
        IPOViewModel.myPlacementListLiveData.observe(this) { list ->
            adapter.submitList(list)
            binding.rvList.visibility = if (list.isNullOrEmpty()) View.GONE else View.VISIBLE
            binding.tvEmpty.visibility = if (list.isNullOrEmpty()) View.VISIBLE else View.GONE
        }
    }
}
