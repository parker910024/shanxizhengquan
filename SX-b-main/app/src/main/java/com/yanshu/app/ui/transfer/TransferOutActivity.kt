package com.yanshu.app.ui.transfer

import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import android.graphics.Color
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.yanshu.app.R
import com.yanshu.app.base.BasicActivity
import com.yanshu.app.data.CapitalLogItem
import com.yanshu.app.databinding.ActivityTransferOutBinding
import com.yanshu.app.databinding.ItemTransferOutRecordBinding
import com.yanshu.app.repo.contract.ContractRemote
import com.yanshu.app.ui.dialog.AppToast
import com.yanshu.app.ui.dialog.PayPasswordBottomDialog
import ex.ss.lib.base.extension.viewBinding
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class TransferOutActivity : BasicActivity<ActivityTransferOutBinding>() {

    companion object {
        private const val DEFAULT_MIN_TRANSFER = 100.0

        fun start(context: Context) {
            context.startActivity(Intent(context, TransferOutActivity::class.java))
        }
    }

    override val binding: ActivityTransferOutBinding by viewBinding()

    private var transferableAmount = 0.0
    private var minTransferAmount = DEFAULT_MIN_TRANSFER
    private var defaultAccountId: String = ""

    private lateinit var recordAdapter: TransferOutRecordAdapter

    override fun initView() {
        binding.titleBar.tvTitle.text = "转出"
        binding.titleBar.tvTitle.setTextColor(getColor(R.color.black))
        binding.titleBar.tvBack.compoundDrawableTintList = ColorStateList.valueOf(getColor(R.color.black))
        binding.titleBar.tvBack.setOnClickListener { finish() }
        binding.titleBar.tvMenu.visibility = View.GONE

        binding.tvWithdrawAll.setOnClickListener { setAmountToAll() }
        binding.btnTransferOut.setOnClickListener { submitTransferOut() }

        recordAdapter = TransferOutRecordAdapter()
        binding.rvRecords.layoutManager = LinearLayoutManager(this)
        binding.rvRecords.adapter = recordAdapter
    }

    private fun setAmountToAll() {
        binding.etAmount.setText(formatAmount(transferableAmount))
    }

    private fun formatAmount(value: Double): String {
        return if (value == value.toLong().toDouble()) "${value.toLong()}" else "%.2f".format(value)
    }

    private fun submitTransferOut() {
        val input = binding.etAmount.text.toString().trim()
        val amount = input.toDoubleOrNull() ?: 0.0

        when {
            input.isEmpty() -> {
                AppToast.show("请输入转出金额")
                return
            }

            amount < minTransferAmount -> {
                AppToast.show("最小转出金额为${minTransferAmount.toInt()}元")
                return
            }

            amount > transferableAmount -> {
                AppToast.show("转出金额不能超过可转出金额")
                return
            }

            defaultAccountId.isEmpty() -> {
                AppToast.show("请先绑定银行卡")
                return
            }
        }

        PayPasswordBottomDialog.show(supportFragmentManager) { pass ->
            doTransferOut(amount, pass)
        }
    }

    private fun doTransferOut(amount: Double, pass: String) {
        binding.btnTransferOut.isEnabled = false
        lifecycleScope.launch {
            val response = ContractRemote.callApiSilent {
                applyWithdraw(accountId = defaultAccountId, money = amount, pass = pass)
            }

            binding.btnTransferOut.isEnabled = true
            if (response.isSuccess()) {
                val msg = response.success.msg
                AppToast.show(if (msg.isNotEmpty()) msg else "转出申请已提交")
                binding.etAmount.text?.clear()
                loadData()
            } else {
                AppToast.show(response.failed.msg ?: "转出失败，请重试")
            }
        }
    }

    override fun initData() {
        loadData()
    }

    private fun loadData() {
        lifecycleScope.launch {
            val chargeConfigRes = ContractRemote.callApiSilent { getChargeConfigNew() }
            minTransferAmount = chargeConfigRes.data?.min_tx_money
                ?.toDoubleOrNull()
                ?.takeIf { it > 0.0 }
                ?: DEFAULT_MIN_TRANSFER

            val logRes = ContractRemote.callApiSilent { getCapitalLog(1) }
            logRes.data?.let { data ->
                data.userInfo?.let { info ->
                    transferableAmount = info.balance
                    binding.tvTransferableAmount.text = formatAmount(transferableAmount)
                }

                val list = data.list.orEmpty()
                if (list.isNotEmpty()) {
                    binding.rvRecords.visibility = View.VISIBLE
                    binding.tvRecordsEmpty.visibility = View.GONE
                    recordAdapter.submitList(list)
                } else {
                    binding.rvRecords.visibility = View.GONE
                    binding.tvRecordsEmpty.visibility = View.VISIBLE
                }
            }

            val cardRes = ContractRemote.callApiSilent { getBankCardList() }
            val firstCard = cardRes.data?.list?.data?.firstOrNull()
            defaultAccountId = firstCard?.id?.toString() ?: ""
        }
    }
}

private class TransferOutRecordAdapter : RecyclerView.Adapter<TransferOutRecordAdapter.Holder>() {

    private val items = mutableListOf<CapitalLogItem>()
    private val dateFormat = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault())

    fun submitList(list: List<CapitalLogItem>) {
        items.clear()
        items.addAll(list)
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): Holder {
        val b = ItemTransferOutRecordBinding.inflate(LayoutInflater.from(parent.context), parent, false)
        return Holder(b)
    }

    override fun onBindViewHolder(holder: Holder, position: Int) = holder.bind(items[position])
    override fun getItemCount() = items.size

    inner class Holder(private val b: ItemTransferOutRecordBinding) : RecyclerView.ViewHolder(b.root) {
        fun bind(item: CapitalLogItem) {
            b.tvType.text = item.pay_type_name.ifEmpty { "银证转出" }
            b.tvAmount.text = "-${item.money.toLong()}"

            val statusText = if (item.reject.isNotEmpty()) "${item.is_pay_name} ${item.reject}" else item.is_pay_name
            b.tvStatus.text = statusText
            b.tvStatus.setTextColor(
                when (item.txtcolor) {
                    "blue" -> Color.parseColor("#2196F3")
                    "green" -> Color.parseColor("#4CAF50")
                    "red" -> Color.parseColor("#E1202E")
                    else -> Color.parseColor("#666666")
                }
            )

            b.tvTime.text = if (item.createtime > 0) dateFormat.format(Date(item.createtime * 1000)) else ""
        }
    }
}

