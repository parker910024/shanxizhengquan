package com.yanshu.app.ui.dialog

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.fragment.app.FragmentManager
import com.google.android.material.bottomsheet.BottomSheetBehavior
import com.google.android.material.bottomsheet.BottomSheetDialogFragment
import com.yanshu.app.databinding.DialogPayKeyboardBinding

/**
 * 支付密码底部弹窗数字键盘，输入满6位后自动回调并关闭。
 * 对应转出接口 /api/user/applyWithdraw 的 pass 参数。
 */
class PayPasswordBottomDialog : BottomSheetDialogFragment() {

    companion object {
        private const val TAG = "PayPasswordBottomDialog"

        fun show(fm: FragmentManager, onComplete: (String) -> Unit) {
            PayPasswordBottomDialog().apply {
                this.onComplete = onComplete
            }.show(fm, TAG)
        }
    }

    private var onComplete: ((String) -> Unit)? = null
    private lateinit var binding: DialogPayKeyboardBinding
    private val password = StringBuilder()

    private val pwdBoxes: List<TextView> by lazy {
        listOf(binding.pwd1, binding.pwd2, binding.pwd3, binding.pwd4, binding.pwd5, binding.pwd6)
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?,
    ): View {
        binding = DialogPayKeyboardBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        setupKeyboard()
        updateDots()
    }

    override fun onStart() {
        super.onStart()
        val bottomSheet = dialog?.findViewById<View>(com.google.android.material.R.id.design_bottom_sheet)
        bottomSheet?.let {
            val behavior = BottomSheetBehavior.from(it)
            behavior.state = BottomSheetBehavior.STATE_EXPANDED
            behavior.skipCollapsed = true
        }
    }

    private fun setupKeyboard() {
        val digitKeys = listOf(
            binding.key1 to "1",
            binding.key2 to "2",
            binding.key3 to "3",
            binding.key4 to "4",
            binding.key5 to "5",
            binding.key6 to "6",
            binding.key7 to "7",
            binding.key8 to "8",
            binding.key9 to "9",
            binding.key0 to "0",
        )
        for ((keyView, digit) in digitKeys) {
            keyView.setOnClickListener { appendDigit(digit) }
        }
        binding.keyCancel.setOnClickListener { dismiss() }
        binding.keyDelete.setOnClickListener { deleteDigit() }
    }

    private fun appendDigit(digit: String) {
        if (password.length >= 6) return
        password.append(digit)
        updateDots()
        if (password.length == 6) {
            val pwd = password.toString()
            dismissAllowingStateLoss()
            onComplete?.invoke(pwd)
        }
    }

    private fun deleteDigit() {
        if (password.isNotEmpty()) {
            password.deleteCharAt(password.length - 1)
            updateDots()
        }
    }

    private fun updateDots() {
        pwdBoxes.forEachIndexed { index, tv ->
            tv.text = if (index < password.length) "●" else ""
        }
    }
}
