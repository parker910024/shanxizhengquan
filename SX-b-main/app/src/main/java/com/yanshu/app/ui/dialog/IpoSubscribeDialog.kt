package com.yanshu.app.ui.dialog

import androidx.fragment.app.FragmentManager
import com.yanshu.app.databinding.DialogIpoSubscribeBinding
import ex.ss.lib.base.dialog.BaseDialog
import ex.ss.lib.base.extension.dp
import ex.ss.lib.base.extension.viewBinding

/**
 * IPO 申购确认弹窗
 */
class IpoSubscribeDialog(private val builder: IpoSubscribeDialogBuilder) : BaseDialog<DialogIpoSubscribeBinding>() {

    companion object {
        fun show(fragmentManager: FragmentManager, block: IpoSubscribeDialogBuilder.() -> Unit) {
            IpoSubscribeDialogBuilder().apply(block).show(fragmentManager)
        }
    }

    override val binding: DialogIpoSubscribeBinding by viewBinding()

    override fun initView() {
        binding.tvCancel.setOnClickListener {
            dismiss()
            builder.onCancel?.invoke()
        }

        binding.tvConfirm.setOnClickListener {
            dismiss()
            builder.onConfirm?.invoke()
        }
    }

    override fun initData() {
    }

    override fun isFullWidth(): Boolean = true
    
    override fun widthMargin(): Int = 100.dp
    
    override fun outsideCancel(): Boolean = true
}

class IpoSubscribeDialogBuilder internal constructor() {
    var onCancel: (() -> Unit)? = null
    var onConfirm: (() -> Unit)? = null

    fun show(manager: FragmentManager) {
        IpoSubscribeDialog(this).show(manager, "IpoSubscribeDialog")
    }
}
