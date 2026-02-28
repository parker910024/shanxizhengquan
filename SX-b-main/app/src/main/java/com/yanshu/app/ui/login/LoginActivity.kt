package com.yanshu.app.ui.login

import android.text.InputFilter
import android.text.InputType
import android.text.SpannableString
import android.text.Spanned
import android.text.method.LinkMovementMethod
import android.text.style.ClickableSpan
import android.text.style.ForegroundColorSpan
import android.view.View
import androidx.core.content.ContextCompat
import androidx.lifecycle.Observer
import com.yanshu.app.R
import com.yanshu.app.base.BasicActivity
import com.yanshu.app.config.AppConfigCenter
import com.yanshu.app.config.UserConfig
import com.yanshu.app.databinding.ActivityLoginBinding
import com.yanshu.app.model.UserViewModel
import com.yanshu.app.ui.dialog.AppToast
import com.yanshu.app.ui.main.MainActivity
import ex.ss.lib.base.extension.viewBinding
import java.util.regex.Pattern

class LoginActivity : BasicActivity<ActivityLoginBinding>() {

    override val binding: ActivityLoginBinding by viewBinding()
    
    private var isPasswordVisible = false

    companion object {
        private const val USERNAME_MAX_LENGTH = 9
        private const val PHONE_MAX_LENGTH = 11
    }
    
    override fun initView() {
        setupInputMode()
        setupPasswordToggle()
        setupAgreementText()
        setupClickListeners()
        observeViewModel()
    }

    private fun setupInputMode() {
        if (AppConfigCenter.isPhoneRegisterMode) {
            binding.tvPhoneLabel.text = "手机号码"
            binding.etPhone.hint = "请输入手机号码"
            binding.etPhone.inputType = InputType.TYPE_CLASS_PHONE
            binding.etPhone.filters = arrayOf(InputFilter.LengthFilter(PHONE_MAX_LENGTH))
        } else {
            binding.tvPhoneLabel.text = "用户名"
            binding.etPhone.hint = "请输入用户名"
            binding.etPhone.inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD
            binding.etPhone.filters = arrayOf(InputFilter.LengthFilter(USERNAME_MAX_LENGTH))
        }
    }
    
    private fun setupPasswordToggle() {
        binding.ivPasswordToggle.setOnClickListener {
            togglePasswordVisibility()
        }
    }
    
    private fun togglePasswordVisibility() {
        isPasswordVisible = !isPasswordVisible
        val inputType = if (isPasswordVisible) {
            InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD
        } else {
            InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_PASSWORD
        }
        binding.etPassword.inputType = inputType
        binding.etPassword.setSelection(binding.etPassword.text?.length ?: 0)
        
        // 更新图标
        val iconRes = if (isPasswordVisible) {
            R.drawable.ic_eye_open
        } else {
            R.drawable.ic_user_eye_close
        }
        binding.ivPasswordToggle.setImageResource(iconRes)
    }
    
    private fun setupAgreementText() {
        val fullText = "阅读并同意《用户协议》《隐私政策》"
        val spannableString = SpannableString(fullText)

        val prefixEnd = fullText.indexOf("《用户协议》")
        spannableString.setSpan(
            ForegroundColorSpan(ContextCompat.getColor(this, R.color.login_agreement_text)),
            0,
            prefixEnd,
            Spanned.SPAN_EXCLUSIVE_EXCLUSIVE
        )

        // 用户协议链接
        val userAgreementStart = fullText.indexOf("《用户协议》")
        val userAgreementEnd = userAgreementStart + "《用户协议》".length
        spannableString.setSpan(
            object : ClickableSpan() {
                override fun onClick(widget: View) {
                    // TODO: 跳转到用户协议页面
                    AppToast.show("用户协议")
                }
            },
            userAgreementStart,
            userAgreementEnd,
            Spanned.SPAN_EXCLUSIVE_EXCLUSIVE
        )
        spannableString.setSpan(
            ForegroundColorSpan(ContextCompat.getColor(this, R.color.login_agreement_link)),
            userAgreementStart,
            userAgreementEnd,
            Spanned.SPAN_EXCLUSIVE_EXCLUSIVE
        )
        
        // 隐私政策链接
        val privacyStart = fullText.indexOf("《隐私政策》")
        val privacyEnd = privacyStart + "《隐私政策》".length
        spannableString.setSpan(
            object : ClickableSpan() {
                override fun onClick(widget: View) {
                    // TODO: 跳转到隐私政策页面
                    AppToast.show("隐私政策")
                }
            },
            privacyStart,
            privacyEnd,
            Spanned.SPAN_EXCLUSIVE_EXCLUSIVE
        )
        spannableString.setSpan(
            ForegroundColorSpan(ContextCompat.getColor(this, R.color.login_agreement_link)),
            privacyStart,
            privacyEnd,
            Spanned.SPAN_EXCLUSIVE_EXCLUSIVE
        )
        
        binding.tvAgreement.text = spannableString
        binding.tvAgreement.movementMethod = LinkMovementMethod.getInstance()
    }
    
    private fun setupClickListeners() {
        // 登录按钮
        binding.btnLogin.setOnClickListener {
            performLogin()
        }
        
        // 马上开户按钮
        binding.btnRegister.setOnClickListener {
            startActivity(RegisterActivity::class.java)
        }
    }
    
    private fun performLogin() {
        val username = binding.etPhone.text?.toString()?.trim() ?: ""
        val password = binding.etPassword.text?.toString() ?: ""
        
        if (!validateInput(username, password)) {
            return
        }
        
        if (!binding.cbAgreement.isChecked) {
            AppToast.show("请先阅读并同意用户协议和隐私政策")
            return
        }
        
        UserViewModel.login(username, password)
    }
    
    private fun validateInput(account: String, password: String): Boolean {
        if (account.isEmpty()) {
            val hint = if (AppConfigCenter.isPhoneRegisterMode) "请输入手机号码" else "请输入用户名"
            AppToast.show(hint)
            return false
        }

        if (AppConfigCenter.isPhoneRegisterMode) {
            if (account.length < 10) {
                AppToast.show("请输入正确的手机号码")
                return false
            }
        } else {
            if (account.length != USERNAME_MAX_LENGTH) {
                AppToast.show("用户名须为${USERNAME_MAX_LENGTH}位")
                return false
            }
            val usernamePattern = Pattern.compile("^(?=.*[a-zA-Z])(?=.*\\d)[a-zA-Z\\d]{${USERNAME_MAX_LENGTH}}$")
            if (!usernamePattern.matcher(account).matches()) {
                AppToast.show("用户名须同时包含字母和数字")
                return false
            }
        }
        
        if (password.isEmpty()) {
            AppToast.show("请输入登录密码")
            return false
        }
        
        if (password.length < 6) {
            AppToast.show("密码长度至少6位")
            return false
        }
        
        return true
    }
    
    private fun observeViewModel() {
        UserViewModel.loginResultLiveData.observe(this) { success ->
            if (success && UserConfig.isLogin()) {
                AppToast.show("登录成功")
                window.decorView.post {
                    if (!isFinishing) {
                        startActivity(MainActivity::class.java)
                        finish()
                    }
                }
            }
        }

        UserViewModel.loginErrorLiveData.observe(this, object : Observer<String?> {
            override fun onChanged(value: String?) {
                value?.let { AppToast.show(it) }
            }
        })
    }

    override fun initData() {
    }

    override fun listenerExpire(): Boolean = false
}

