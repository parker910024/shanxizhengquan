package com.yanshu.app.ui.transfer

import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import android.os.Build
import android.text.Html
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.yanshu.app.R
import com.yanshu.app.base.BasicActivity
import com.yanshu.app.data.CapitalLogBank
import com.yanshu.app.databinding.ActivityTransferInBinding
import com.yanshu.app.databinding.ItemTransferInChannelBinding
import com.yanshu.app.repo.contract.ContractRemote
import com.yanshu.app.util.CustomerServiceNavigator
import ex.ss.lib.base.extension.viewBinding
import kotlinx.coroutines.launch

class TransferInActivity : BasicActivity<ActivityTransferInBinding>() {

    companion object {
        fun start(context: Context) {
            context.startActivity(Intent(context, TransferInActivity::class.java))
        }
    }

    override val binding: ActivityTransferInBinding by viewBinding()

    private lateinit var adapter: ChannelAdapter

    override fun initView() {
        binding.titleBar.tvTitle.text = "银证转入"
        binding.titleBar.tvTitle.setTextColor(getColor(R.color.black))
        binding.titleBar.tvBack.compoundDrawableTintList = ColorStateList.valueOf(getColor(R.color.black))
        binding.titleBar.tvBack.setOnClickListener { finish() }
        binding.titleBar.tvMenu.visibility = View.GONE

        binding.rvChannels.layoutManager = LinearLayoutManager(this)
        adapter = ChannelAdapter { channel ->
            TransferInDetailActivity.start(
                context = this,
                channelId = channel.id,
                minlow = channel.minlow,
                maxhigh = channel.maxhigh,
                tdname = channel.tdname,
                urlType = channel.url_type,
            )
        }
        binding.rvChannels.adapter = adapter

        // 无支付通道时，可联系在线客服
        binding.btnContactService.setOnClickListener {
            CustomerServiceNavigator.open(this, lifecycleScope)
        }
    }

    override fun initData() {
        lifecycleScope.launch {
            val chargeConfigRes = ContractRemote.callApiSilent { getChargeConfigNew() }
            val chargeConfigData = chargeConfigRes.data

            var list = chargeConfigData.sysbank_list
                .orEmpty()
                .map {
                    CapitalLogBank(
                        id = it.id,
                        bankinfo = it.bankinfo,
                        tdname = it.tdname,
                        yzmima = it.yzmima,
                        minlow = it.minlow,
                        maxhigh = it.maxhigh,
                        url_type = it.url_type,
                    )
                }
            var htmlDesc = chargeConfigData.contentmsg_gb.orEmpty().trim()

            if (list.isEmpty()) {
                binding.rvChannels.visibility = View.GONE
                binding.tvEmpty.visibility = View.VISIBLE
                binding.btnContactService.visibility = View.VISIBLE
            } else {
                binding.rvChannels.visibility = View.VISIBLE
                binding.tvEmpty.visibility = View.GONE
                binding.btnContactService.visibility = View.GONE
                adapter.submitList(list)
            }

            // 渲染底部简介说明
            if (htmlDesc.isNotEmpty()) {
                val spanned = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    Html.fromHtml(htmlDesc, Html.FROM_HTML_MODE_LEGACY)
                } else {
                    @Suppress("DEPRECATION")
                    Html.fromHtml(htmlDesc)
                }
                binding.tvYhxy.text = spanned
                binding.tvYhxy.visibility = View.VISIBLE
                binding.dividerYhxy.visibility = View.VISIBLE
            } else {
                binding.tvYhxy.visibility = View.GONE
                binding.dividerYhxy.visibility = View.GONE
            }
        }
    }
}

private class ChannelAdapter(
    private val onItemClick: (CapitalLogBank) -> Unit,
) : RecyclerView.Adapter<ChannelAdapter.Holder>() {

    private val items = mutableListOf<CapitalLogBank>()

    fun submitList(list: List<CapitalLogBank>) {
        items.clear()
        items.addAll(list)
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): Holder {
        val b = ItemTransferInChannelBinding.inflate(LayoutInflater.from(parent.context), parent, false)
        return Holder(b)
    }

    override fun onBindViewHolder(holder: Holder, position: Int) {
        holder.bind(items[position], onItemClick)
    }

    override fun getItemCount() = items.size

    class Holder(private val b: ItemTransferInChannelBinding) : RecyclerView.ViewHolder(b.root) {
        fun bind(channel: CapitalLogBank, onItemClick: (CapitalLogBank) -> Unit) {
            b.tvChannelName.text = channel.tdname.ifEmpty { "银证转入" }
            b.tvAmountRange.text = when {
                channel.minlow > 0 || channel.maxhigh > 0 -> "${channel.minlow}-${channel.maxhigh}元"
                else -> ""
            }
            b.root.setOnClickListener { onItemClick(channel) }
        }
    }
}
