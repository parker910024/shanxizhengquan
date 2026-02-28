package com.yanshu.app.ui.password

import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import androidx.lifecycle.lifecycleScope
import com.yanshu.app.R
import com.yanshu.app.base.BasicActivity
import com.yanshu.app.data.EditLoginPasswordRequest
import com.yanshu.app.databinding.ActivityChangeLoginPwdBinding
import com.yanshu.app.repo.contract.ContractRemote
import com.yanshu.app.ui.dialog.AppDialog
import com.yanshu.app.ui.dialog.AppToast
import ex.ss.lib.base.extension.viewBinding
import kotlinx.coroutines.launch

class ChangeLoginPwdActivity : BasicActivity<ActivityChangeLoginPwdBinding>() {

    override val binding: ActivityChangeLoginPwdBinding by viewBinding()

    companion object {
        fun start(context: Context) {
            context.startActivity(Intent(context, ChangeLoginPwdActivity::class.java))
        }
    }

    override fun initView() {
        setupTitleBar()
        setupSubmitButton()
        binding.root.setClickToHideKeyboard()
    }

    private fun setupTitleBar() {
        binding.titleBar.tvTitle.text = getString(R.string.pwd_login_title)
        binding.titleBar.tvTitle.setTextColor(getColor(R.color.black))
        binding.titleBar.tvBack.compoundDrawableTintList = ColorStateList.valueOf(getColor(R.color.black))
        binding.titleBar.tvBack.setOnClickListener { finish() }
        binding.titleBar.tvMenu.visibility = android.view.View.GONE
    }

    private fun setupSubmitButton() {
        binding.btnSubmit.setOnClickListener {
            val oldPassword = binding.etOldLogin.text.toString().trim()
            val newPassword = binding.etNewLogin.text.toString().trim()
            val confirmPassword = binding.etConfirmLogin.text.toString().trim()

            if (oldPassword.isEmpty() || newPassword.isEmpty() || confirmPassword.isEmpty()) {
                AppToast.show(getString(R.string.pwd_login_all_required))
                return@setOnClickListener
            }
            if (newPassword != confirmPassword) {
                AppToast.show(getString(R.string.pwd_pay_mismatch))
                return@setOnClickListener
            }

            binding.btnSubmit.isEnabled = false
            lifecycleScope.launch {
                val response = ContractRemote.callApi {
                    editPass1(
                        EditLoginPasswordRequest(
                            oldpass = oldPassword,
                            password = newPassword,
                            confimpassword = confirmPassword,
                        )
                    )
                }
                binding.btnSubmit.isEnabled = true
                if (response.isSuccess()) {
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
