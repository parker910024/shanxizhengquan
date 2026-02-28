package com.yanshu.app.ui.ai

import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import android.view.View
import com.yanshu.app.R
import com.yanshu.app.base.BasicActivity
import com.yanshu.app.databinding.ActivityAiInvestBinding
import ex.ss.lib.base.extension.viewBinding

/**
 * AI智投页：展示可滑动的长图（设计稿见 Figma 山西证券新版 node-id=4-837）
 */
class AiInvestActivity : BasicActivity<ActivityAiInvestBinding>() {

    override val binding: ActivityAiInvestBinding by viewBinding()

    override fun initView() {
        setupTitleBar()
    }

    private fun setupTitleBar() {
        binding.titleBar.tvTitle.text = getString(R.string.home_ai)
        binding.titleBar.tvTitle.setTextColor(getColor(R.color.black))
        binding.titleBar.tvBack.compoundDrawableTintList = ColorStateList.valueOf(getColor(R.color.black))
        binding.titleBar.tvBack.setOnClickListener { finish() }
        binding.titleBar.tvMenu.visibility = View.GONE
    }

    override fun initData() {}

    companion object {
        fun start(context: Context) {
            context.startActivity(Intent(context, AiInvestActivity::class.java))
        }
    }
}
