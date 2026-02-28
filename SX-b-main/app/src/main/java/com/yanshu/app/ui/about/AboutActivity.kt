package com.yanshu.app.ui.about

import android.content.res.ColorStateList
import com.yanshu.app.BuildConfig
import com.yanshu.app.R
import com.yanshu.app.base.BasicActivity
import com.yanshu.app.databinding.ActivityAboutBinding
import ex.ss.lib.base.extension.viewBinding

/**
 * 2024/7/24
 */
class AboutActivity : BasicActivity<ActivityAboutBinding>() {

    override val binding: ActivityAboutBinding by viewBinding()

    override fun initView() {
        setupTitleBar()
        setupContent()
    }
    
    private fun setupTitleBar() {
        binding.titleBar.tvTitle.text = getString(R.string.about_title)
        binding.titleBar.tvTitle.setTextColor(getColor(R.color.black))
        binding.titleBar.tvBack.compoundDrawableTintList = ColorStateList.valueOf(getColor(R.color.black))
        binding.titleBar.tvBack.setOnClickListener {
            finish()
        }
        binding.titleBar.tvMenu.visibility = android.view.View.GONE
    }
    
    private fun setupContent() {
        binding.tvVersion.text = getString(R.string.about_version, BuildConfig.VERSION_NAME)
    }

    override fun initData() {
    }
}
