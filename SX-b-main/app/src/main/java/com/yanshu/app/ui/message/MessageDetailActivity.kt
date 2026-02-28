package com.yanshu.app.ui.message

import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import android.webkit.WebView
import androidx.lifecycle.lifecycleScope
import com.yanshu.app.R
import com.yanshu.app.base.BasicActivity
import com.yanshu.app.databinding.ActivityMessageDetailBinding
import com.yanshu.app.repo.Remote
import ex.ss.lib.base.extension.viewBinding
import kotlinx.coroutines.launch

/**
 * 消息详情页面（接口拉取 HTML 内容，WebView 展示）
 */
class MessageDetailActivity : BasicActivity<ActivityMessageDetailBinding>() {

    override val binding: ActivityMessageDetailBinding by viewBinding()

    private val messageId: Int by lazy { intent.getIntExtra(EXTRA_MESSAGE_ID, -1) }
    private val messageTitle: String by lazy { intent.getStringExtra(EXTRA_MESSAGE_TITLE) ?: getString(R.string.msg_detail_title) }
    private val messageTime: String by lazy { intent.getStringExtra(EXTRA_MESSAGE_TIME) ?: "" }

    override fun initView() {
        setupTitleBar()
        binding.tvMessageTitle.text = messageTitle
        binding.tvMessageTime.text = if (messageTime.isNotEmpty()) messageTime else ""
        loadMessageDetail()
    }

    private fun setupTitleBar() {
        binding.titleBar.tvTitle.text = getString(R.string.msg_detail_title)
        binding.titleBar.tvTitle.setTextColor(getColor(R.color.black))
        binding.titleBar.tvBack.compoundDrawableTintList = ColorStateList.valueOf(getColor(R.color.black))
        binding.titleBar.tvBack.setOnClickListener { finish() }
        binding.titleBar.tvMenu.visibility = android.view.View.GONE
    }

    private fun loadMessageDetail() {
        if (messageId < 0) {
            // 兼容：无 id 时使用 Intent 传入的 content
            val content = intent.getStringExtra(EXTRA_MESSAGE_CONTENT) ?: ""
            loadHtmlIntoWebView(binding.webMessageContent, content)
            return
        }
        lifecycleScope.launch {
            val response = Remote.callApi { getMessageDetail(messageId) }
            if (response.isSuccess()) {
                val html = response.data?.detail ?: ""
                loadHtmlIntoWebView(binding.webMessageContent, html)
            } else {
                val content = intent.getStringExtra(EXTRA_MESSAGE_CONTENT) ?: ""
                loadHtmlIntoWebView(binding.webMessageContent, content)
            }
        }
    }

    private fun loadHtmlIntoWebView(webView: WebView, html: String) {
        if (html.isBlank()) {
            webView.loadDataWithBaseURL(
                null,
                "<p style='color:#999;'>暂无内容</p>",
                "text/html",
                "UTF-8",
                null
            )
            return
        }
        webView.settings.apply {
            javaScriptEnabled = false
        }
        webView.loadDataWithBaseURL(
            null,
            html,
            "text/html",
            "UTF-8",
            null
        )
    }

    override fun initData() {
    }

    companion object {
        private const val EXTRA_MESSAGE_ID = "message_id"
        private const val EXTRA_MESSAGE_TITLE = "message_title"
        private const val EXTRA_MESSAGE_TIME = "message_time"
        private const val EXTRA_MESSAGE_CONTENT = "message_content"

        fun start(context: Context, messageId: Int, title: String, createtime: String = "") {
            context.startActivity(Intent(context, MessageDetailActivity::class.java).apply {
                putExtra(EXTRA_MESSAGE_ID, messageId)
                putExtra(EXTRA_MESSAGE_TITLE, title)
                putExtra(EXTRA_MESSAGE_TIME, createtime)
            })
        }
    }
}
