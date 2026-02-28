package com.yanshu.app.ui.dialog

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.fragment.app.FragmentManager
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.yanshu.app.data.IPOItem
import com.yanshu.app.databinding.DialogIpoReminderBinding
import com.yanshu.app.databinding.ItemIpoReminderBinding
import ex.ss.lib.base.dialog.BaseDialog
import ex.ss.lib.base.extension.dp
import ex.ss.lib.base.extension.viewBinding

class IpoReminderDialog(private val builder: IpoReminderBuilder) : BaseDialog<DialogIpoReminderBinding>() {

    companion object {
        fun show(fragmentManager: FragmentManager, block: IpoReminderBuilder.() -> Unit) {
            IpoReminderBuilder().apply(block).show(fragmentManager)
        }
    }

    override val binding: DialogIpoReminderBinding by viewBinding()

    override fun initView() {
        binding.rvIpoList.layoutManager = LinearLayoutManager(requireContext())
        binding.rvIpoList.adapter = IpoReminderAdapter(builder.items)

        binding.btnGoSubscribe.setOnClickListener {
            dismiss()
            builder.onGoSubscribe?.invoke()
        }

        binding.ivClose.setOnClickListener {
            dismiss()
        }
    }

    override fun initData() {}

    override fun isFullWidth(): Boolean = true

    override fun widthMargin(): Int = 100.dp

    override fun outsideCancel(): Boolean = true

    override fun dimAmount(): Float = 0.6F

    private class IpoReminderAdapter(
        private val items: List<IPOItem>,
    ) : RecyclerView.Adapter<IpoReminderAdapter.VH>() {

        class VH(val binding: ItemIpoReminderBinding) : RecyclerView.ViewHolder(binding.root)

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): VH {
            val b = ItemIpoReminderBinding.inflate(LayoutInflater.from(parent.context), parent, false)
            return VH(b)
        }

        override fun onBindViewHolder(holder: VH, position: Int) {
            val item = items[position]
            holder.binding.tvMarketTag.text = item.getMarketTag()
            holder.binding.tvStockCode.text = item.code
            holder.binding.tvStockName.text = item.name
            holder.binding.tvPrice.text = "${item.fx_price}/股"
        }

        override fun getItemCount(): Int = items.size
    }
}

class IpoReminderBuilder internal constructor() {
    var items: List<IPOItem> = emptyList()
    var onGoSubscribe: (() -> Unit)? = null

    fun show(manager: FragmentManager) {
        if (items.isEmpty()) return
        IpoReminderDialog(this).show(manager, "IpoReminderDialog")
    }
}
