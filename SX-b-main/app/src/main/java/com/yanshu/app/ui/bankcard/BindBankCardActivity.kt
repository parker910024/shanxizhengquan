package com.yanshu.app.ui.bankcard

import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import android.view.View
import androidx.lifecycle.lifecycleScope
import com.yanshu.app.R
import com.yanshu.app.base.BasicActivity
import com.yanshu.app.data.BindBankCardRequest
import com.yanshu.app.databinding.ActivityBindBankCardBinding
import com.yanshu.app.repo.contract.ContractRemote
import com.yanshu.app.ui.dialog.AppToast
import com.yanshu.app.util.CustomerServiceNavigator
import ex.ss.lib.base.extension.viewBinding
import kotlinx.coroutines.launch

class BindBankCardActivity : BasicActivity<ActivityBindBankCardBinding>() {

    companion object {
        const val EXTRA_ID = "id"
        const val EXTRA_NAME = "name"
        const val EXTRA_DEPOSIT_BANK = "deposit_bank"
        const val EXTRA_ACCOUNT = "account"
        const val EXTRA_KHZHIHANG = "khzhihang"

        fun start(context: Context, editId: Int? = null, name: String? = null, depositBank: String? = null, account: String? = null, khzhihang: String? = null) {
            context.startActivity(Intent(context, BindBankCardActivity::class.java).apply {
                editId?.let { putExtra(EXTRA_ID, it) }
                name?.let { putExtra(EXTRA_NAME, it) }
                depositBank?.let { putExtra(EXTRA_DEPOSIT_BANK, it) }
                account?.let { putExtra(EXTRA_ACCOUNT, it) }
                khzhihang?.let { putExtra(EXTRA_KHZHIHANG, it) }
            })
        }
    }

    override val binding: ActivityBindBankCardBinding by viewBinding()

    private var editId: Int? = null

    override fun initView() {
        setupTitleBar()
        prefillFromIntent()
        setupSubmit()
    }

    private fun setupTitleBar() {
        binding.titleBar.tvTitle.setTextColor(getColor(R.color.black))
        binding.titleBar.tvBack.compoundDrawableTintList = ColorStateList.valueOf(getColor(R.color.black))
        binding.titleBar.tvBack.setOnClickListener { finish() }
        binding.titleBar.tvMenu.visibility = View.VISIBLE
        binding.titleBar.tvMenu.text = ""
        binding.titleBar.tvMenu.setCompoundDrawablesWithIntrinsicBounds(0, 0, R.drawable.ic_trade_record_service, 0)
        binding.titleBar.tvMenu.setOnClickListener {
            CustomerServiceNavigator.open(this, lifecycleScope)
        }
    }

    private fun prefillFromIntent() {
        editId = intent.getIntExtra(EXTRA_ID, 0).takeIf { it != 0 }
        if (editId != null) {
            binding.titleBar.tvTitle.text = "修改银行卡"
            intent.getStringExtra(EXTRA_NAME)?.let { binding.etName.setText(it) }
            intent.getStringExtra(EXTRA_DEPOSIT_BANK)?.let { binding.etBankName.setText(it) }
            intent.getStringExtra(EXTRA_ACCOUNT)?.let { binding.etAccount.setText(it) }
            intent.getStringExtra(EXTRA_KHZHIHANG)?.let { binding.etBranch.setText(it) }
        } else {
            binding.titleBar.tvTitle.text = "添加储蓄卡"
        }
    }

    private fun setupSubmit() {
        binding.btnSubmit.setOnClickListener { submit() }
    }

    private fun submit() {
        val name = binding.etName.text.toString().trim()
        val depositBank = binding.etBankName.text.toString().trim()
        val account = binding.etAccount.text.toString().trim().replace(" ", "")
        val khzhihang = binding.etBranch.text.toString().trim()

        when {
            name.isEmpty() -> {
                AppToast.show("请输入姓名")
                return
            }
            depositBank.isEmpty() -> {
                AppToast.show("请输入银行名称")
                return
            }
            account.isEmpty() -> {
                AppToast.show("请输入银行卡号")
                return
            }
            !isValidCardNumber(account) -> {
                AppToast.show("请输入正确的银行卡号")
                return
            }
            khzhihang.isEmpty() -> {
                AppToast.show("请输入开户支行")
                return
            }
        }

        binding.btnSubmit.isEnabled = false
        lifecycleScope.launch {
            val request = BindBankCardRequest(
                name = name,
                deposit_bank = depositBank,
                account = account,
                khzhihang = khzhihang,
                id = editId
            )
            val response = ContractRemote.callApi { bindBankCard(request) }
            binding.btnSubmit.isEnabled = true
            if (response.isSuccess()) {
                AppToast.show("保存成功")
                setResult(RESULT_OK)
                finish()
            }
        }
    }

    private fun isValidCardNumber(s: String): Boolean {
        if (s.length !in 16..19) return false
        return s.all { it.isDigit() }
    }

    override fun initData() {}
}
