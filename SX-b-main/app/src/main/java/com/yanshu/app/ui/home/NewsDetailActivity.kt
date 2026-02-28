package com.yanshu.app.ui.home

import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import androidx.lifecycle.lifecycleScope
import com.yanshu.app.R
import com.yanshu.app.base.BasicActivity
import com.yanshu.app.databinding.ActivityNewsDetailBinding
import com.yanshu.app.repo.Remote
import com.yanshu.app.util.loadHtmlContent
import com.yanshu.app.util.setupForHtmlContent
import ex.ss.lib.base.extension.viewBinding
import kotlinx.coroutines.launch

/**
 * 新闻详情页（首页信息点击进入），按 news_id 拉取详情并用 WebView 展示。
 */
class NewsDetailActivity : BasicActivity<ActivityNewsDetailBinding>() {

    override val binding: ActivityNewsDetailBinding by viewBinding()

    private val newsId: String by lazy { intent.getStringExtra(EXTRA_NEWS_ID) ?: "" }

    override fun initView() {
        setupTitleBar()
        binding.webNewsContent.setupForHtmlContent()
    }

    private fun setupTitleBar() {
        binding.titleBar.tvTitle.text = getString(R.string.news_detail_title)
        binding.titleBar.tvTitle.setTextColor(getColor(R.color.black))
        binding.titleBar.tvBack.compoundDrawableTintList = ColorStateList.valueOf(getColor(R.color.black))
        binding.titleBar.tvBack.setOnClickListener { finish() }
        binding.titleBar.tvMenu.visibility = android.view.View.GONE
    }

    override fun initData() {
        if (newsId.isEmpty()) {
            showEmptyContent()
            return
        }
        loadNewsDetail(newsId)
    }

    private fun loadNewsDetail(id: String) {
        lifecycleScope.launch {
            val response = Remote.callApi { getNewsssDetail(id) }
            if (response.isSuccess() && response.data != null) {
                val d = response.data!!
                binding.webNewsContent.loadHtmlContent(d.news_title, d.news_content, d.news_time)
            } else {
                showEmptyContent()
            }
        }
    }

    private fun showEmptyContent() {
        binding.webNewsContent.loadHtmlContent("", "<p style='color:#999;'>暂无内容</p>")
    }

    companion object {
        private const val EXTRA_NEWS_ID = "news_id"

        fun start(context: Context, newsId: String) {
            context.startActivity(Intent(context, NewsDetailActivity::class.java).apply {
                putExtra(EXTRA_NEWS_ID, newsId)
            })
        }
    }
}
