package com.yanshu.app.ui.dialog

import androidx.fragment.app.FragmentManager
import com.yanshu.app.databinding.DialogPlacementKeyBinding
import ex.ss.lib.base.dialog.BaseDialog
import ex.ss.lib.base.extension.dp
import ex.ss.lib.base.extension.viewBinding

/**
 * 战略配售申购秘钥输入弹窗
 * 主题色已使用 #FB443C（bg_btn_primary）
 */
class PlacementKeyDialog : BaseDialog<DialogPlacementKeyBinding>() {

    companion object {
        private const val TAG = "PlacementKeyDialog"

        fun show(fm: FragmentManager, onSubmit: (String) -> Unit) {
            PlacementKeyDialog().apply {
                onSubmitCallback = onSubmit
            }.show(fm, TAG)
        }
    }

    override val binding: DialogPlacementKeyBinding by viewBinding()

    private var onSubmitCallback: ((String) -> Unit)? = null

    override fun initView() {
        binding.btnSubmit.setOnClickListener {
            val key = binding.etKey.text?.toString()?.trim() ?: ""
            dismiss()
            onSubmitCallback?.invoke(key)
            onSubmitCallback = null
        }
    }

    override fun initData() {}
    override fun isFullWidth(): Boolean = true
    override fun outsideCancel(): Boolean = true
    override fun widthMargin(): Int = 40.dp
    override fun dimAmount(): Float = 0.5f
}
