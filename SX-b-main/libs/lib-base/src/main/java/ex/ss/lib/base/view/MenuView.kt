package ex.ss.lib.base.view

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import ex.ss.lib.base.adapter.BaseItemAdapter
import ex.ss.lib.base.adapter.data.BaseItem
import ex.ss.lib.base.databinding.ItemBaseMenuViewBinding

/**
 * 2024/9/20
 */
class MenuView {

    fun bind(recyclerView: RecyclerView, list: List<MenuItem>, onMenuClick: (MenuItem) -> Unit) {
        recyclerView.apply {
            layoutManager = LinearLayoutManager(context)
            adapter = MenuItemAdapter().apply {
                setOnItemClick { data, _ ->
                    onMenuClick.invoke(data)
                }
                submitList(list)
            }
        }
    }
}

data class MenuItem(val title: String, val icon: Int) : BaseItem

class MenuItemAdapter : BaseItemAdapter<MenuItem, ItemBaseMenuViewBinding>() {
    override fun onBindViewHolder(binding: ItemBaseMenuViewBinding, position: Int) {
        val item = getItem(position)
        binding.tvTitle.text = item.title
        binding.ivIcon.setImageResource(item.icon)
    }

    override fun viewBinding(inflater: LayoutInflater, parent: ViewGroup): ItemBaseMenuViewBinding {
        return ItemBaseMenuViewBinding.inflate(inflater, parent, false)
    }


}