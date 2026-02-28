package com.yanshu.app.ui.deal

import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import android.view.View
import androidx.lifecycle.lifecycleScope
import com.yanshu.app.R
import com.yanshu.app.base.BasicActivity
import com.yanshu.app.databinding.ActivityCancelOrderBinding
import com.yanshu.app.repo.contract.ContractRemote
import com.yanshu.app.ui.dialog.AppToast
import ex.ss.lib.base.extension.viewBinding
import kotlinx.coroutines.launch

/**
 * 撤单页（文档 3.26）GET api/deal/cheAll，参数 id 为委托编号。
 */
class CancelOrderActivity : BasicActivity<ActivityCancelOrderBinding>() {

    override val binding: ActivityCancelOrderBinding by viewBinding()

    companion object {
        fun start(context: Context) {
            context.startActivity(Intent(context, CancelOrderActivity::class.java))
        }
    }

    override fun initView() {
        setupTitleBar()
        binding.root.setClickToHideKeyboard()
        binding.btnCancelOrder.setOnClickListener { submit() }
    }

    override fun initData() {}

    private fun setupTitleBar() {
        binding.titleBar.tvTitle.text = "撤单"
        binding.titleBar.tvTitle.setTextColor(getColor(R.color.black))
        binding.titleBar.tvBack.compoundDrawableTintList = ColorStateList.valueOf(getColor(R.color.black))
        binding.titleBar.tvBack.setOnClickListener { finish() }
        binding.titleBar.tvMenu.visibility = View.GONE
    }

    private fun submit() {
        val idStr = binding.etOrderId.text.toString().trim()
        if (idStr.isEmpty()) {
            AppToast.show("请输入委托编号")
            return
        }
        val id = idStr.toIntOrNull()
        if (id == null || id <= 0) {
            AppToast.show("请输入有效委托编号")
            return
        }
        binding.btnCancelOrder.isEnabled = false
        lifecycleScope.launch {
            try {
                val response = ContractRemote.callApi { cancelOrder(id) }
                if (response.isSuccess()) {
                    AppToast.show("撤单成功")
                    finish()
                }
            } finally {
                binding.btnCancelOrder.isEnabled = true
            }
        }
    }
}
