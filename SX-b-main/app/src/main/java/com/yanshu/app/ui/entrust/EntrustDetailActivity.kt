package com.yanshu.app.ui.entrust

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.view.View
import androidx.lifecycle.lifecycleScope
import com.yanshu.app.base.BasicActivity
import com.yanshu.app.data.HoldingItem
import com.yanshu.app.databinding.ActivityEntrustDetailBinding
import com.yanshu.app.repo.contract.ContractRemote
import com.yanshu.app.ui.dialog.AppToast
import ex.ss.lib.base.extension.viewBinding
import kotlinx.coroutines.launch

class EntrustDetailActivity : BasicActivity<ActivityEntrustDetailBinding>() {

    override val binding: ActivityEntrustDetailBinding by viewBinding()
    private var canceling = false
    private var blockTradeName = "大宗"

    companion object {
        private const val EXTRA_ITEM = "item"

        fun createIntent(context: Context, item: HoldingItem): Intent {
            return Intent(context, EntrustDetailActivity::class.java).apply {
                putExtra(EXTRA_ITEM, item)
            }
        }

        fun start(context: Context, item: HoldingItem) {
            context.startActivity(createIntent(context, item))
        }
    }

    override fun initView() {
        binding.ivBack.setOnClickListener { finish() }
        val item = intent.getSerializableExtra(EXTRA_ITEM) as? HoldingItem ?: return
        bind(item)
    }

    override fun initData() {
        lifecycleScope.launch {
            val response = ContractRemote.callApiSilent { getConfig() }
            val name = response.data?.dz_syname?.trim()
            if (!name.isNullOrEmpty()) {
                blockTradeName = name
                val item = intent.getSerializableExtra(EXTRA_ITEM) as? HoldingItem ?: return@launch
                if (item.buytype == "7") {
                    binding.tvBuyType.text = "证券买入($blockTradeName)"
                }
            }
        }
    }

    private fun bind(item: HoldingItem) {
        val nameText = buildString {
            if (item.title.isNotEmpty()) append(item.title)
            if (item.code.isNotEmpty()) append("(${item.code})")
            if (isEmpty()) append("-")
        }
        binding.tvStockName.text = nameText

        binding.tvBuyType.text = when (item.buytype) {
            "7" -> "证券买入($blockTradeName)"
            "1" -> "证券买入"
            else -> item.buytype.ifEmpty { "--" }
        }

        binding.tvCjlx.text = item.cjlx.ifEmpty { "--" }
        binding.tvCanBuy.text = item.canBuy.ifEmpty { "--" }
        binding.tvNumber.text = item.number.ifEmpty { "--" }
        binding.tvBuyPrice.text = if (item.buyprice > 0) fmt2(item.buyprice) else "--"
        binding.tvMultiplying.text = item.multiplying.ifEmpty { "--" }

        val cityVal = when {
            item.citycc > 0 -> fmt2(item.citycc)
            item.creditMoney > 0 -> fmt2(item.creditMoney)
            else -> "--"
        }
        binding.tvCityValue.text = cityVal
        binding.tvCreateTime.text = item.createtime_name.ifEmpty { "--" }

        if (item.status == 2 && item.id > 0) {
            binding.llCancelBar.visibility = View.VISIBLE
            binding.btnCancelOrder.setOnClickListener { cancelOrder(item) }
        } else {
            binding.llCancelBar.visibility = View.GONE
        }
    }

    private fun cancelOrder(item: HoldingItem) {
        if (canceling || item.status != 2 || item.id <= 0) return
        canceling = true
        binding.btnCancelOrder.isEnabled = false
        binding.btnCancelOrder.alpha = 0.7f
        lifecycleScope.launch {
            try {
                val response = ContractRemote.callApi { cancelOrder(item.id) }
                if (response.isSuccess()) {
                    AppToast.show("\u64a4\u5355\u6210\u529f")
                    setResult(Activity.RESULT_OK)
                    finish()
                }
            } finally {
                canceling = false
                binding.btnCancelOrder.isEnabled = true
                binding.btnCancelOrder.alpha = 1f
            }
        }
    }

    private fun fmt2(value: Double) = String.format("%.2f", value)
}
