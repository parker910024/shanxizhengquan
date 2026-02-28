package com.yanshu.app.ui.password

import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import androidx.lifecycle.lifecycleScope
import com.yanshu.app.data.CheckPayPasswordRequest
import com.yanshu.app.data.EditPayPasswordRequest
import com.yanshu.app.repo.contract.ContractRemote
import com.yanshu.app.ui.dialog.AppDialog
import com.yanshu.app.ui.dialog.AppToast
import com.yanshu.app.R
import com.yanshu.app.base.BasicActivity
import com.yanshu.app.databinding.ActivityChangeTradePwdBinding
import ex.ss.lib.base.extension.viewBinding
import kotlinx.coroutines.launch

/**
 * 设置/修改交易密码页面。流程：验证原支付密码(checkOldpay) → 新密码与确认一致后修改(editPass)。
 */
class ChangeTradePwdActivity : BasicActivity<ActivityChangeTradePwdBinding>() {

    override val binding: ActivityChangeTradePwdBinding by viewBinding()

    companion object {
        fun start(context: Context) {
            context.startActivity(Intent(context, ChangeTradePwdActivity::class.java))
        }
    }

    override fun initView() {
        setupTitleBar()
        setupSubmitButton()
        binding.root.setClickToHideKeyboard()
    }

    private fun setupTitleBar() {
        binding.titleBar.tvTitle.text = getString(R.string.pwd_trade_title)
        binding.titleBar.tvTitle.setTextColor(getColor(R.color.black))
        binding.titleBar.tvBack.compoundDrawableTintList = ColorStateList.valueOf(getColor(R.color.black))
        binding.titleBar.tvBack.setOnClickListener { finish() }
        binding.titleBar.tvMenu.visibility = android.view.View.GONE
    }

    private fun setupSubmitButton() {
        binding.btnSubmit.setOnClickListener {
            val oldPay = binding.etOldPay.text.toString().trim()
            val newPay = binding.etNewPay.text.toString().trim()
            val confirmPay = binding.etConfirmPay.text.toString().trim()

            if (oldPay.isEmpty()) {
                AppToast.show(getString(R.string.pwd_input_trade_hint))
                return@setOnClickListener
            }
            if (oldPay.length != 6) {
                AppToast.show(getString(R.string.pwd_pay_need_six))
                return@setOnClickListener
            }
            if (newPay.isEmpty() || confirmPay.isEmpty()) {
                AppToast.show(getString(R.string.pwd_new_pay))
                return@setOnClickListener
            }
            if (newPay.length != 6) {
                AppToast.show(getString(R.string.pwd_pay_new_six))
                return@setOnClickListener
            }
            if (newPay != confirmPay) {
                AppToast.show(getString(R.string.pwd_pay_mismatch))
                return@setOnClickListener
            }

            binding.btnSubmit.isEnabled = false
            lifecycleScope.launch {
                val checkRes = ContractRemote.callApiSilent { checkOldpay(CheckPayPasswordRequest(oldPay)) }
                if (!checkRes.isSuccess()) {
                    AppToast.show(getString(R.string.pwd_pay_wrong))
                    binding.etOldPay.text?.clear()
                    binding.btnSubmit.isEnabled = true
                    return@launch
                }
                val editRes = ContractRemote.callApi { editPass(EditPayPasswordRequest(newPay)) }
                binding.btnSubmit.isEnabled = true
                if (editRes.isSuccess()) {
                    AppDialog.show(supportFragmentManager) {
                        title = "提示"
                        content = "修改成功"
                        done = "确定"
                        onDone = { finish() }
                        onClose = { finish() }
                    }
                }
            }
        }
    }

    override fun initData() {
    }
}
