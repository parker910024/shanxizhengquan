package com.yanshu.app.ui.position

import android.content.Context
import android.content.Intent
import android.view.View
import androidx.core.content.ContextCompat
import androidx.lifecycle.lifecycleScope
import com.yanshu.app.R
import com.yanshu.app.base.BasicActivity
import com.yanshu.app.data.HoldingItem
import com.yanshu.app.databinding.ActivityHoldingDetailBinding
import com.yanshu.app.repo.contract.ContractRemote
import com.yanshu.app.ui.deal.BuyActivity
import com.yanshu.app.ui.dialog.AppToast
import ex.ss.lib.base.extension.viewBinding
import kotlinx.coroutines.launch

class HoldingDetailActivity : BasicActivity<ActivityHoldingDetailBinding>() {

    override val binding: ActivityHoldingDetailBinding by viewBinding()

    private var holdingItem: HoldingItem? = null
    private var isHistory = false
    private var readOnly = false

    companion object {
        private const val EXTRA_HOLDING = "extra_holding"
        private const val EXTRA_IS_HISTORY = "extra_is_history"
        private const val EXTRA_READ_ONLY = "extra_read_only"

        fun start(context: Context, item: HoldingItem, isHistory: Boolean = false) {
            context.startActivity(Intent(context, HoldingDetailActivity::class.java).apply {
                putExtra(EXTRA_HOLDING, item)
                putExtra(EXTRA_IS_HISTORY, isHistory)
            })
        }

        fun startReadOnly(context: Context, item: HoldingItem, isHistory: Boolean = false) {
            context.startActivity(Intent(context, HoldingDetailActivity::class.java).apply {
                putExtra(EXTRA_HOLDING, item)
                putExtra(EXTRA_IS_HISTORY, isHistory)
                putExtra(EXTRA_READ_ONLY, true)
            })
        }
    }

    @Suppress("DEPRECATION")
    override fun initView() {
        holdingItem = intent.getSerializableExtra(EXTRA_HOLDING) as? HoldingItem
        isHistory = intent.getBooleanExtra(EXTRA_IS_HISTORY, false)
        readOnly = intent.getBooleanExtra(EXTRA_READ_ONLY, false)

        binding.ivBack.setOnClickListener { finish() }

        if (isHistory) {
            binding.tvTitle.text = "历史持仓详情"
            binding.btnAction.text = "返回"
            binding.btnAction.setOnClickListener { finish() }
            binding.rowSellPrice.visibility = View.VISIBLE
            binding.rowStampTax.visibility = View.VISIBLE
            binding.rowSellTime.visibility = View.VISIBLE
        } else if (readOnly) {
            binding.tvTitle.text = "持仓详情"
            binding.btnAction.text = "返回"
            binding.btnAction.setOnClickListener { finish() }
        } else {
            binding.tvTitle.text = "持仓详情"
            binding.btnAction.text = "平仓"
            binding.btnAction.setOnClickListener {
                holdingItem?.let { item -> verifySellAndNavigate(item) }
            }
        }

        bindData()
    }

    override fun initData() {}

    private fun verifySellAndNavigate(item: HoldingItem) {
        lifecycleScope.launch {
            val resp = ContractRemote.callApiSilent { getMrSellList(item.code) }
            val sellList = resp.data ?: emptyList()
            val match = sellList.find { it.allcode.equals(item.allcode, ignoreCase = true) }
            val sellableLots = match?.canBuy?.toIntOrNull() ?: 0
            if (match == null || sellableLots <= 0) {
                AppToast.show("该股票暂不可卖出（T+N限制未到期）")
                return@launch
            }
            BuyActivity.startForSell(this@HoldingDetailActivity, item)
        }
    }

    private fun bindData() {
        val item = holdingItem ?: return

        binding.tvMarket.text = marketLabel(item.type)
        binding.tvStockCode.text = item.code
        binding.tvStockName.text = item.title
        binding.tvQuantity.text = item.number
        binding.tvBuyPrice.text = formatPrice(item.buyprice)
        binding.tvMarketValue.text = item.money.ifEmpty { formatPrice(item.citycc) }
        binding.tvFee.text = item.allMoney
        binding.tvProfit.text = formatPrice(item.profitLose)
        binding.tvProfitRate.text = item.profitLose_rate
        binding.tvBuyTime.text = item.createtime_name

        if (isHistory) {
            binding.tvSellPrice.text = item.cai_buy.toString()
            binding.tvStampTax.text = item.yhfee
            binding.tvSellTime.text = item.outtime_name
        }

        val profitColor = if (item.profitLose >= 0) {
            ContextCompat.getColor(this, R.color.hq_rise_color)
        } else {
            ContextCompat.getColor(this, R.color.hq_fall_color)
        }
        binding.tvProfit.setTextColor(profitColor)
        binding.tvProfitRate.setTextColor(profitColor)
    }

    private fun marketLabel(type: Int): String = when (type) {
        1 -> "沪"; 2 -> "深"; 3 -> "创"; 4 -> "北"; 5 -> "科"; 6 -> "基"; else -> ""
    }

    private fun formatPrice(value: Double): String = String.format("%.2f", value)
}
