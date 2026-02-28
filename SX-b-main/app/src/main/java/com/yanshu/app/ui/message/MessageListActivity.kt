package com.yanshu.app.ui.message

import android.content.Intent
import android.content.res.ColorStateList
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.core.view.isVisible
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.yanshu.app.R
import com.yanshu.app.base.BasicActivity
import com.yanshu.app.data.MessageListRequest
import com.yanshu.app.data.MessageListItem
import com.yanshu.app.databinding.ActivityMessageListBinding
import com.yanshu.app.databinding.ItemMessageBinding
import com.yanshu.app.repo.Remote
import ex.ss.lib.base.extension.viewBinding
import kotlinx.coroutines.launch

/**
 * 站内消息列表页面（接口 + 已读/未读参考 SX）
 */
class MessageListActivity : BasicActivity<ActivityMessageListBinding>() {

    override val binding: ActivityMessageListBinding by viewBinding()

    private val messageAdapter = MessageAdapter()
    private var currentPage = 1
    private var lastPage = 1
    private var isLoading = false

    override fun initView() {
        setupTitleBar()
        setupRecyclerView()
    }

    private fun setupTitleBar() {
        binding.titleBar.tvTitle.text = getString(R.string.msg_list_title)
        binding.titleBar.tvTitle.setTextColor(getColor(R.color.black))
        binding.titleBar.tvBack.compoundDrawableTintList = ColorStateList.valueOf(getColor(R.color.black))
        binding.titleBar.tvBack.setOnClickListener { finish() }
        binding.titleBar.tvMenu.text = getString(R.string.msg_read_all)
        binding.titleBar.tvMenu.setTextColor(getColor(R.color.black))
        binding.titleBar.tvMenu.setOnClickListener {
            messageAdapter.markAllAsRead()
        }
    }

    private fun setupRecyclerView() {
        binding.rvMessages.layoutManager = LinearLayoutManager(this)
        binding.rvMessages.adapter = messageAdapter

        messageAdapter.onItemClick = { item ->
            messageAdapter.markAsRead(item.id)
            MessageDetailActivity.start(this, item.id, item.title, item.createtime)
        }

        binding.rvMessages.addOnScrollListener(object : RecyclerView.OnScrollListener() {
            override fun onScrolled(recyclerView: RecyclerView, dx: Int, dy: Int) {
                super.onScrolled(recyclerView, dx, dy)
                if (dy > 0) {
                    val lm = recyclerView.layoutManager as? LinearLayoutManager ?: return
                    val visible = lm.childCount
                    val total = lm.itemCount
                    val first = lm.findFirstVisibleItemPosition()
                    if (!isLoading && currentPage < lastPage &&
                        (visible + first) >= total - 2
                    ) {
                        loadMore()
                    }
                }
            }
        })
    }

    override fun initData() {
        loadData()
    }

    private fun loadData() {
        currentPage = 1
        isLoading = true
        lifecycleScope.launch {
            val response = Remote.callApi { getMessageList(MessageListRequest(currentPage)) }
            isLoading = false
            if (response.isSuccess()) {
                val pageData = response.data?.list ?: return@launch
                lastPage = pageData.last_page
                messageAdapter.submitList(pageData.data)
                binding.tvEmpty.isVisible = pageData.data.isEmpty()
                binding.rvMessages.isVisible = pageData.data.isNotEmpty()
            } else {
                binding.tvEmpty.isVisible = true
                binding.rvMessages.isVisible = false
            }
        }
    }

    private fun loadMore() {
        if (isLoading || currentPage >= lastPage) return
        isLoading = true
        currentPage++
        lifecycleScope.launch {
            val response = Remote.callApi { getMessageList(MessageListRequest(currentPage)) }
            isLoading = false
            if (response.isSuccess()) {
                val pageData = response.data?.list ?: return@launch
                val newList = messageAdapter.currentList().toMutableList()
                newList.addAll(pageData.data)
                messageAdapter.submitList(newList)
            } else {
                currentPage--
            }
        }
    }

    /**
     * 消息列表 Adapter，支持已读/未读展示与本地标记（参考 SX）
     */
    class MessageAdapter : RecyclerView.Adapter<MessageAdapter.ViewHolder>() {

        private val items = mutableListOf<MessageListItem>()
        var onItemClick: ((MessageListItem) -> Unit)? = null

        fun submitList(list: List<MessageListItem>) {
            items.clear()
            items.addAll(list)
            notifyDataSetChanged()
        }

        fun currentList(): List<MessageListItem> = items.toList()

        fun markAsRead(id: Int) {
            val updated = items.map { if (it.id == id) it.copy(is_read = "1") else it }
            items.clear()
            items.addAll(updated)
            notifyDataSetChanged()
        }

        fun markAllAsRead() {
            val updated = items.map { it.copy(is_read = "1") }
            items.clear()
            items.addAll(updated)
            notifyDataSetChanged()
        }

        class ViewHolder(val binding: ItemMessageBinding) : RecyclerView.ViewHolder(binding.root)

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
            val binding = ItemMessageBinding.inflate(
                LayoutInflater.from(parent.context), parent, false
            )
            return ViewHolder(binding)
        }

        override fun onBindViewHolder(holder: ViewHolder, position: Int) {
            val item = items[position]
            holder.binding.tvTag.text = item.title
            holder.binding.tvTime.text = item.createtime
            holder.binding.tvContent.text = "" // 列表不返回内容，详情页再拉
            holder.binding.tvContent.visibility = View.GONE

            val isRead = item.is_read == "1"
            holder.binding.tvReadStatus.isVisible = true
            if (isRead) {
                holder.binding.tvReadStatus.text = holder.binding.root.context.getString(R.string.msg_read)
                holder.binding.tvReadStatus.setTextColor(
                    androidx.core.content.ContextCompat.getColor(holder.binding.root.context, R.color.message_read)
                )
            } else {
                holder.binding.tvReadStatus.text = holder.binding.root.context.getString(R.string.msg_unread)
                holder.binding.tvReadStatus.setTextColor(
                    androidx.core.content.ContextCompat.getColor(holder.binding.root.context, R.color.message_unread)
                )
            }

            holder.itemView.setOnClickListener { onItemClick?.invoke(item) }
        }

        override fun getItemCount() = items.size
    }
}
