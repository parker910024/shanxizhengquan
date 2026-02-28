package com.yanshu.app.ui.hq

import android.content.Context
import android.content.Intent
import android.view.View
import androidx.core.content.ContextCompat
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import com.yanshu.app.R
import com.yanshu.app.base.BasicActivity
import com.yanshu.app.databinding.ActivityBulkTradeHoldingBinding
import com.yanshu.app.model.IPOViewModel
import com.yanshu.app.repo.contract.ContractRemote
import com.yanshu.app.ui.hq.adapter.HoldingAdapter
import com.yanshu.app.ui.position.HoldingDetailActivity
import ex.ss.lib.base.extension.viewBinding
import kotlinx.coroutines.launch

/**
 * 大宗交易持仓记录页面（当前持仓 / 历史持仓）
 */
class BulkTradeHoldingActivity : BasicActivity<ActivityBulkTradeHoldingBinding>() {

    override val binding: ActivityBulkTradeHoldingBinding by viewBinding()

    private val currentAdapter = HoldingAdapter(
        isHistory = false,
        onItemClick = { item -> HoldingDetailActivity.startReadOnly(this, item, isHistory = false) },
    )
    private val historyAdapter = HoldingAdapter(
        isHistory = true,
        onItemClick = { item -> HoldingDetailActivity.startReadOnly(this, item, isHistory = true) },
    )
    private var isCurrentTab = true

    companion object {
        fun start(context: Context) {
            context.startActivity(Intent(context, BulkTradeHoldingActivity::class.java))
        }
    }

    override fun initView() {
        binding.ivBack.setOnClickListener { finish() }
        binding.rvList.layoutManager = LinearLayoutManager(this)
        binding.rvList.adapter = currentAdapter

        binding.tabCurrent.setOnClickListener { switchTab(true) }
        binding.tabHistory.setOnClickListener { switchTab(false) }

        updateTabUI()
        observeViewModel()
    }

    override fun initData() {
        IPOViewModel.loadBlockTradeHolding()
        loadTitle()
    }

    private fun loadTitle() {
        lifecycleScope.launch {
            val response = ContractRemote.callApiSilent { getConfig() }
            val name = response.data?.dz_syname?.trim()
            if (!name.isNullOrEmpty()) {
                binding.tvTitle.text = name
            }
        }
    }

    private fun switchTab(current: Boolean) {
        if (isCurrentTab == current) return
        isCurrentTab = current
        updateTabUI()
        binding.rvList.adapter = if (current) currentAdapter else historyAdapter
        if (!current) IPOViewModel.loadBlockTradeHistory()
        updateEmpty()
    }

    private fun updateTabUI() {
        val selectedColor = ContextCompat.getColor(this, R.color.black)
        val normalColor = ContextCompat.getColor(this, R.color.hq_text_gray)
        val accentColor = ContextCompat.getColor(this, R.color.hq_rise_color)

        binding.tvTabCurrent.setTextColor(if (isCurrentTab) selectedColor else normalColor)
        binding.tvTabCurrent.paint.isFakeBoldText = isCurrentTab
        binding.indicatorCurrent.setBackgroundColor(if (isCurrentTab) accentColor else 0)

        binding.tvTabHistory.setTextColor(if (!isCurrentTab) selectedColor else normalColor)
        binding.tvTabHistory.paint.isFakeBoldText = !isCurrentTab
        binding.indicatorHistory.setBackgroundColor(if (!isCurrentTab) accentColor else 0)
    }

    private fun observeViewModel() {
        IPOViewModel.blockTradeHoldingLiveData.observe(this) { data ->
            val list = data?.list ?: emptyList()
            currentAdapter.submitList(list)
            if (isCurrentTab) updateEmpty(list.isEmpty())
        }
        IPOViewModel.blockTradeHistoryLiveData.observe(this) { data ->
            val list = data?.list ?: emptyList()
            historyAdapter.submitList(list)
            if (!isCurrentTab) updateEmpty(list.isEmpty())
        }
    }

    private fun updateEmpty(empty: Boolean = true) {
        binding.rvList.visibility = if (empty) View.GONE else View.VISIBLE
        binding.tvEmpty.visibility = if (empty) View.VISIBLE else View.GONE
    }
}
