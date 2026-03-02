package com.yanshu.app.ui.hq

import android.app.Dialog
import android.content.Context
import android.content.Intent
import android.view.View
import android.view.WindowManager
import androidx.core.content.ContextCompat
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import com.yanshu.app.R
import com.yanshu.app.base.BasicActivity
import com.yanshu.app.data.HoldingItem
import com.yanshu.app.data.SellRequest
import com.yanshu.app.data.SellStockRequest
import com.yanshu.app.databinding.ActivityBulkTradeHoldingBinding
import com.yanshu.app.databinding.DialogTradeConfirmBinding
import com.yanshu.app.model.IPOViewModel
import com.yanshu.app.repo.contract.ContractRemote
import com.yanshu.app.ui.dialog.AppDialog
import com.yanshu.app.ui.dialog.AppToast
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
        onSellClick = { item -> onSellClick(item) },
        onItemClick = { item -> HoldingDetailActivity.startForBulkTrade(this, item) },
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
        if (!current) {
            // 切到历史持仓：先显示 loading，等数据回来再更新
            showLoading()
            IPOViewModel.loadBlockTradeHistory()
        } else {
            // 切回当前持仓：直接刷新已有数据的空状态
            updateEmpty(currentAdapter.itemCount == 0)
        }
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

    /** 大宗持仓：不依赖 mrSellLst（大宗与普通持仓不同表），直接弹窗确认，以平仓接口返回为准 */
    private fun onSellClick(holdingItem: HoldingItem) {
        showConfirmSellDialog(holdingItem)
    }

    /** 确认卖出弹窗，点击确认后提交卖出 */
    private fun showConfirmSellDialog(item: HoldingItem) {
        val price = item.caiBuyDouble()
        val shares = item.number.toIntOrNull() ?: 0
        val total = price * shares

        val dialog = Dialog(this)
        dialog.requestWindowFeature(android.view.Window.FEATURE_NO_TITLE)
        val db = DialogTradeConfirmBinding.inflate(layoutInflater)
        dialog.setContentView(db.root)

        db.tvDialogTitle.text = "确认卖出吗?"
        db.btnConfirmOk.text = "确认"
        db.btnConfirmOk.setBackgroundResource(R.drawable.bg_btn_primary)
        db.tvConfirmName.text = item.title.ifBlank { item.code }
        db.tvConfirmPrice.text = String.format("%.2f", price)
        db.tvConfirmShares.text = "${shares}股"
        db.tvConfirmTotal.text = String.format("%.2f", total)

        db.btnConfirmCancel.setOnClickListener { dialog.dismiss() }
        db.btnConfirmOk.setOnClickListener {
            dialog.dismiss()
            submitSell(item, price, shares)
        }

        dialog.window?.apply {
            setLayout(
                (resources.displayMetrics.widthPixels * 0.85).toInt(),
                WindowManager.LayoutParams.WRAP_CONTENT,
            )
            setBackgroundDrawableResource(android.R.color.transparent)
        }
        dialog.show()
    }

    private fun submitSell(item: HoldingItem, price: Double, shares: Int) {
        val lots = (shares / 100).coerceAtLeast(0)
        if (lots <= 0) {
            AppToast.show("股数无效")
            return
        }
        lifecycleScope.launch {
            val primaryResp = ContractRemote.callApiSilent {
                sell(
                    SellRequest(
                        id = item.id,
                        allcode = item.allcode,
                        canBuy = lots,
                        sellprice = price,
                    )
                )
            }
            val resp = if (!primaryResp.isSuccess() && isApiNotFound(primaryResp.failed.msg)) {
                ContractRemote.callApiSilent {
                    sellStockLegacy(SellStockRequest(id = item.id, sellprice = price, number = shares))
                }
            } else {
                primaryResp
            }
            if (resp.isSuccess()) {
                AppDialog.show(supportFragmentManager) {
                    title = "平仓成功"
                    content = "平仓成功"
                    done = "确定"
                    onDone = { IPOViewModel.loadBlockTradeHolding() }
                }
            } else if (isApiNotFound(resp.failed.msg)) {
                AppToast.show("卖出接口未开放，请联系后端开通")
            } else {
                AppToast.show(resp.failed.msg ?: "卖出失败，请重试")
            }
        }
    }

    private fun isApiNotFound(msg: String?): Boolean {
        val text = msg ?: return false
        return text.contains("api不存在") || text.contains("api not found", ignoreCase = true)
    }

    private fun observeViewModel() {
        IPOViewModel.blockTradeHoldingLiveData.observe(this) { data ->
            val list = (data?.list ?: emptyList()).toList()
            currentAdapter.submitList(list)
            if (isCurrentTab) updateEmpty(list.isEmpty())
        }
        IPOViewModel.blockTradeHistoryLiveData.observe(this) { data ->
            val list = (data?.list ?: emptyList()).toList()
            historyAdapter.submitList(list)
            if (!isCurrentTab) updateEmpty(list.isEmpty())
        }
    }

    private fun showLoading() {
        binding.rvList.visibility = View.GONE
        binding.tvEmpty.visibility = View.VISIBLE
        binding.tvEmpty.text = "加载中..."
    }

    private fun updateEmpty(empty: Boolean = true) {
        binding.tvEmpty.text = "暂无数据"
        binding.rvList.visibility = if (empty) View.GONE else View.VISIBLE
        binding.tvEmpty.visibility = if (empty) View.VISIBLE else View.GONE
    }
}
