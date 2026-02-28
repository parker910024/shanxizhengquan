package com.yanshu.app.ui.dialog

import android.content.DialogInterface
import androidx.fragment.app.FragmentManager
import com.yanshu.app.databinding.DialogWinningLotBinding
import ex.ss.lib.base.dialog.BaseDialog
import ex.ss.lib.base.extension.viewBinding

class WinningLotDialog(private val builder: WinningLotBuilder) : BaseDialog<DialogWinningLotBinding>() {

    override val binding: DialogWinningLotBinding by viewBinding()

    override fun onDismiss(dialog: DialogInterface) {
        super.onDismiss(dialog)
        builder.onDismiss?.invoke()
    }

    override fun initView() {
        binding.tvSubtitle.text = "今日中签${builder.winningCount}只新股"
        binding.tvStockName.text = builder.stockName
        binding.tvStockCode.text = builder.stockCode
        binding.tvQuantity.text = builder.quantity
        binding.tvAmount.text = builder.amount

        binding.btnGoPay.setOnClickListener {
            dismiss()
            builder.onGoPay?.invoke()
        }
    }

    override fun initData() {}

    override fun isFullWidth() = true

    override fun widthMargin(): Int {
        return (resources.displayMetrics.widthPixels * 0.2).toInt()
    }

    override fun outsideCancel() = true

    companion object {
        private const val TAG = "WinningLotDialog"

        fun show(fragmentManager: FragmentManager, block: WinningLotBuilder.() -> Unit) {
            WinningLotBuilder().apply(block).show(fragmentManager)
        }
    }
}

class WinningLotBuilder internal constructor() {
    var stockName: String = ""
    var stockCode: String = ""
    var quantity: String = ""
    var amount: String = ""
    var winningCount: Int = 1
    var onGoPay: (() -> Unit)? = null
    /** 弹窗关闭时回调（点“前往认缴”或点击外部关闭都会触发） */
    var onDismiss: (() -> Unit)? = null

    fun show(manager: FragmentManager) {
        WinningLotDialog(this).show(manager, "WinningLotDialog")
    }
}
