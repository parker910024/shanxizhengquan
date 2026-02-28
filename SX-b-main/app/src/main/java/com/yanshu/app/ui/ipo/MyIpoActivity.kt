package com.yanshu.app.ui.ipo

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.view.View
import android.widget.TextView
import androidx.recyclerview.widget.LinearLayoutManager
import com.yanshu.app.R
import com.yanshu.app.base.BasicActivity
import com.yanshu.app.databinding.ActivityMyIpoBinding
import com.yanshu.app.model.IPOViewModel
import com.yanshu.app.ui.dialog.AppDialog
import com.yanshu.app.ui.dialog.AppToast
import ex.ss.lib.base.extension.viewBinding

class MyIpoActivity : BasicActivity<ActivityMyIpoBinding>() {

    override val binding: ActivityMyIpoBinding by viewBinding()
    private lateinit var adapter: MyIpoAdapter
    private var currentTab = 0

    companion object {
        private const val EXTRA_INITIAL_TAB = "initial_tab"

        /** @param initialTab 0=申购中 1=中签 2=未中签，默认0 */
        fun start(context: Context, initialTab: Int = 0) {
            context.startActivity(Intent(context, MyIpoActivity::class.java).apply {
                putExtra(EXTRA_INITIAL_TAB, initialTab)
            })
        }
    }

    override fun initView() {
        binding.ivBack.setOnClickListener { finish() }

        currentTab = intent.getIntExtra(EXTRA_INITIAL_TAB, 0).coerceIn(0, 2)

        adapter = MyIpoAdapter()
        binding.rvList.layoutManager = LinearLayoutManager(this)
        binding.rvList.adapter = adapter

        adapter.setOnRenjiaoClickListener { item ->
            AppDialog.show(supportFragmentManager) {
                title = "确认认缴"
                content = "确定要认缴「${item.name}」吗？"
                cancel = "取消"
                done = "认缴"
                onDone = {
                    binding.progressLoading.visibility = View.VISIBLE
                    IPOViewModel.renjiaoIpo(item.id)
                }
            }
        }

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
        val selectedColor = Color.parseColor("#E23C39")
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
        binding.progressLoading.visibility = View.VISIBLE
        binding.tvEmpty.visibility = View.GONE
        binding.rvList.visibility = View.VISIBLE
        IPOViewModel.loadMyIpoList(status = currentTab)
    }

    private fun observeViewModel() {
        IPOViewModel.myIpoListLiveData.observe(this) { list ->
            binding.progressLoading.visibility = View.GONE
            if (list.isNullOrEmpty()) {
                binding.rvList.visibility = View.GONE
                binding.tvEmpty.visibility = View.VISIBLE
            } else {
                binding.rvList.visibility = View.VISIBLE
                binding.tvEmpty.visibility = View.GONE
                adapter.submitList(list)
            }
        }

        IPOViewModel.operationResult.observe(this) { result ->
            result ?: return@observe
            val (action, success, errorMsg) = result
            if (action == "renjiaoIpo") {
                binding.progressLoading.visibility = View.GONE
                if (success) {
                    AppToast.show("认缴成功")
                    loadData()
                } else {
                    AppToast.show(errorMsg ?: "认缴失败，请重试")
                }
                IPOViewModel.clearOperationResult()
            }
        }
    }
}
