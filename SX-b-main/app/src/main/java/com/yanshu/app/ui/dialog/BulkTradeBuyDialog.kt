package com.yanshu.app.ui.dialog

import androidx.fragment.app.FragmentManager
import com.yanshu.app.data.BlockTradeItem
import com.yanshu.app.databinding.DialogBulkTradeBuyBinding
import com.yanshu.app.model.IPOViewModel
import ex.ss.lib.base.dialog.BaseDialog
import ex.ss.lib.base.extension.dp
import ex.ss.lib.base.extension.viewBinding

/**
 * 大宗交易买入弹窗
 */
class BulkTradeBuyDialog : BaseDialog<DialogBulkTradeBuyBinding>() {

    companion object {
        private const val TAG = "BulkTradeBuyDialog"

        fun show(fm: FragmentManager, item: BlockTradeItem, balance: Double) {
            BulkTradeBuyDialog().apply {
                this.stockItem = item
                this.balance = balance
            }.show(fm, TAG)
        }
    }

    override val binding: DialogBulkTradeBuyBinding by viewBinding()

    private var stockItem: BlockTradeItem? = null
    private var balance: Double = 0.0
    private var quantity = 0
    private var maxQuantity = 0
    private var price = 0.0

    override fun initView() {
        val item = stockItem ?: return

        price = item.cai_buy.toDoubleOrNull() ?: 0.0
        maxQuantity = item.max_num

        binding.tvStockName.text = item.title
        binding.tvStockCode.text = item.code
        binding.tvCurrentPrice.text = "%.2f".format(price)
        binding.tvBalance.text = "%.2f".format(balance)
        binding.tvMaxBuy.text = maxQuantity.toString()
        updateDisplay()

        binding.tvMinus.setOnClickListener {
            if (quantity > 0) { quantity--; updateDisplay() }
        }
        binding.tvPlus.setOnClickListener {
            if (quantity < maxQuantity) { quantity++; updateDisplay() }
        }
        binding.tvCancel.setOnClickListener { dismiss() }
        binding.tvDone.setOnClickListener {
            if (quantity > 0) {
                dismiss()
                IPOViewModel.buyBlockTrade(item.allcode, quantity, "")
            }
        }
    }

    private fun updateDisplay() {
        binding.tvQuantity.text = quantity.toString()
        binding.tvPayAmount.text = "%.2f".format(quantity * price * 100)
    }

    override fun initData() {}
    override fun isFullWidth(): Boolean = true
    override fun outsideCancel(): Boolean = true
    override fun widthMargin(): Int = 40.dp
    override fun dimAmount(): Float = 0.5f
}
