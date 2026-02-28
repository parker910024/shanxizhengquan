package com.yanshu.app.ui.profile

import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import com.yanshu.app.config.UserConfig
import com.yanshu.app.ui.dialog.AppDialog
import com.yanshu.app.ui.dialog.AppToast
import com.yanshu.app.BuildConfig
import com.yanshu.app.R
import com.yanshu.app.base.BasicActivity
import com.yanshu.app.databinding.ActivityProfileBinding
import com.yanshu.app.ui.password.ChangeLoginPwdActivity
import com.yanshu.app.ui.password.ChangeTradePwdActivity
import ex.ss.lib.base.extension.viewBinding

class ProfileActivity : BasicActivity<ActivityProfileBinding>() {

    companion object {
        fun start(context: Context) {
            context.startActivity(Intent(context, ProfileActivity::class.java))
        }
    }

    override val binding: ActivityProfileBinding by viewBinding()

    override fun initView() {
        setupTitleBar()
        setupContent()
        setupClickListeners()
    }

    private fun setupTitleBar() {
        binding.titleBar.tvTitle.text = getString(R.string.profile_title)
        binding.titleBar.tvTitle.setTextColor(getColor(R.color.black))
        binding.titleBar.tvBack.compoundDrawableTintList = ColorStateList.valueOf(getColor(R.color.black))
        binding.titleBar.tvBack.setOnClickListener {
            finish()
        }
        binding.titleBar.tvMenu.visibility = android.view.View.GONE
    }

    private fun setupContent() {
        binding.tvVersion.text = "V${BuildConfig.VERSION_NAME}"
        val user = UserConfig.getUser()
        if (user != null) {
            binding.tvAccount.text = user.username.ifEmpty { user.id.toString() }
        } else {
            binding.tvAccount.text = "--"
        }
    }

    private fun setupClickListeners() {
        // Login password
        binding.llLoginPwd.setOnClickListener {
            ChangeLoginPwdActivity.start(this)
        }

        // Trade password
        binding.llTradePwd.setOnClickListener {
            ChangeTradePwdActivity.start(this)
        }
        
        // Version
        binding.llVersion.setOnClickListener {
            showToast("检查更新")
        }
        
        // Logout
        binding.tvLogout.setOnClickListener {
            showLogoutConfirmDialog()
        }
    }

    private fun showLogoutConfirmDialog() {
        AppDialog.show(supportFragmentManager) {
            title = getString(R.string.common_dialog_title)
            content = getString(R.string.logout_confirm_message)
            cancel = getString(R.string.common_cancel)
            done = getString(R.string.common_confirm)
            alwaysShow = true
            onDone = { UserConfig.performLogout(this@ProfileActivity) }
        }
    }

    private fun showToast(message: String) {
        AppToast.show(message)
    }

    override fun initData() {}

    override fun onResume() {
        super.onResume()
        setupContent()
    }
}
