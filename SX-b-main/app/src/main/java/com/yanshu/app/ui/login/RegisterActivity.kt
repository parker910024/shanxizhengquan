package com.yanshu.app.ui.login

import android.content.Intent
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
import com.yanshu.app.databinding.ActivityRegisterBinding
import com.yanshu.app.model.UserViewModel
import com.yanshu.app.ui.dialog.AppToast
import com.yanshu.app.ui.main.MainActivity
import ex.ss.lib.base.extension.viewBinding
import java.util.regex.Pattern

class RegisterActivity : BasicActivity<ActivityRegisterBinding>() {

    override val binding: ActivityRegisterBinding by viewBinding()

    private var isPasswordVisible = false
    private var isConfirmPasswordVisible = false
    private var isPaymentCodeVisible = false

    companion object {
        private const val PASSWORD_MIN_LENGTH = 6
        private const val USERNAME_MAX_LENGTH = 9
        private const val PHONE_MAX_LENGTH = 11
    }

    override fun initView() {
        setupBackButton()
        setupInputMode()
        setupPasswordToggles()
        setupAgreementText()
        setupClickListeners()
        observeViewModel()
    }

    private fun setupBackButton() {
        binding.ivBack.setOnClickListener {
            finish()
        }
    }

    private fun setupInputMode() {
        if (AppConfigCenter.isPhoneRegisterMode) {
            binding.etPhone.hint = "请输入手机号码"
            binding.etPhone.inputType = InputType.TYPE_CLASS_PHONE
            binding.etPhone.filters = arrayOf(InputFilter.LengthFilter(PHONE_MAX_LENGTH))
        } else {
            binding.etPhone.hint = "请输入用户名（9位字母+数字）"
            binding.etPhone.inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD
            binding.etPhone.filters = arrayOf(InputFilter.LengthFilter(USERNAME_MAX_LENGTH))
        }
    }

    private fun setupPasswordToggles() {
        binding.ivPasswordToggle.setOnClickListener {
            togglePasswordVisibility(binding.etPassword, binding.ivPasswordToggle, ::isPasswordVisible) { isPasswordVisible = it }
        }

        binding.ivConfirmPasswordToggle.setOnClickListener {
            togglePasswordVisibility(binding.etConfirmPassword, binding.ivConfirmPasswordToggle, ::isConfirmPasswordVisible) { isConfirmPasswordVisible = it }
        }

        binding.ivPaymentCodeToggle.setOnClickListener {
            togglePasswordVisibility(binding.etPaymentCode, binding.ivPaymentCodeToggle, ::isPaymentCodeVisible) { isPaymentCodeVisible = it }
        }
    }

    private fun togglePasswordVisibility(
        editText: android.widget.EditText,
        imageView: android.widget.ImageView,
        getVisibility: () -> Boolean,
        setVisibility: (Boolean) -> Unit
    ) {
        val isVisible = !getVisibility()
        setVisibility(isVisible)

        val inputType = if (isVisible) {
            InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD
        } else {
            InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_PASSWORD
        }
        editText.inputType = inputType
        editText.setSelection(editText.text?.length ?: 0)

        val iconRes = if (isVisible) {
            R.drawable.ic_eye_open_small
        } else {
            R.drawable.ic_user_eye_close
        }
        imageView.setImageResource(iconRes)
    }

    private fun setupAgreementText() {
        val fullText = "我同意签署《用户协议》《隐私政策》"
        val spannableString = SpannableString(fullText)

        val userAgreementStart = fullText.indexOf("《用户协议》")
        val userAgreementEnd = userAgreementStart + "《用户协议》".length
        spannableString.setSpan(
            object : ClickableSpan() {
                override fun onClick(widget: View) {
                    AppToast.show("用户协议")
                }
            },
            userAgreementStart,
            userAgreementEnd,
            Spanned.SPAN_EXCLUSIVE_EXCLUSIVE
        )
        spannableString.setSpan(
            ForegroundColorSpan(ContextCompat.getColor(this, R.color.register_agreement_link)),
            userAgreementStart,
            userAgreementEnd,
            Spanned.SPAN_EXCLUSIVE_EXCLUSIVE
        )

        val privacyStart = fullText.indexOf("《隐私政策》")
        val privacyEnd = privacyStart + "《隐私政策》".length
        spannableString.setSpan(
            object : ClickableSpan() {
                override fun onClick(widget: View) {
                    AppToast.show("隐私政策")
                }
            },
            privacyStart,
            privacyEnd,
            Spanned.SPAN_EXCLUSIVE_EXCLUSIVE
        )
        spannableString.setSpan(
            ForegroundColorSpan(ContextCompat.getColor(this, R.color.register_agreement_link)),
            privacyStart,
            privacyEnd,
            Spanned.SPAN_EXCLUSIVE_EXCLUSIVE
        )

        binding.tvAgreement.text = spannableString
        binding.tvAgreement.movementMethod = LinkMovementMethod.getInstance()
    }

    private fun setupClickListeners() {
        binding.btnRegister.setOnClickListener {
            performRegister()
        }
    }

    private fun performRegister() {
        val account = binding.etPhone.text?.toString()?.trim() ?: ""
        val password = binding.etPassword.text?.toString() ?: ""
        val confirmPassword = binding.etConfirmPassword.text?.toString() ?: ""
        val paymentCode = binding.etPaymentCode.text?.toString() ?: ""
        val institutionNumber = binding.etInviteCode.text?.toString()?.trim() ?: ""

        if (!validateInput(account, password, confirmPassword, paymentCode)) {
            return
        }

        if (!binding.cbAgreement.isChecked) {
            AppToast.show("请先同意用户协议和隐私政策")
            return
        }

        UserViewModel.register(account, password, paymentCode, institutionNumber)
    }

    private fun validateInput(account: String, password: String, confirmPassword: String, paymentCode: String): Boolean {
        if (AppConfigCenter.isPhoneRegisterMode) {
            if (!validatePhone(account)) return false
        } else {
            if (!validateUsername(account)) return false
        }

        if (password.isEmpty()) {
            AppToast.show("请输入密码")
            return false
        }

        if (password.length < PASSWORD_MIN_LENGTH) {
            AppToast.show("密码长度至少${PASSWORD_MIN_LENGTH}位")
            return false
        }

        if (confirmPassword.isEmpty()) {
            AppToast.show("请再次输入密码")
            return false
        }

        if (password != confirmPassword) {
            AppToast.show("两次输入的密码不一致")
            return false
        }

        if (paymentCode.isEmpty()) {
            AppToast.show("请输入支付密码")
            return false
        }

        if (paymentCode.length < PASSWORD_MIN_LENGTH) {
            AppToast.show("支付密码长度至少${PASSWORD_MIN_LENGTH}位")
            return false
        }

        return true
    }

    private fun validatePhone(phone: String): Boolean {
        if (phone.isEmpty()) {
            AppToast.show("请输入手机号码")
            return false
        }
        if (phone.length < 10) {
            AppToast.show("请输入正确的手机号码")
            return false
        }
        return true
    }

    private fun validateUsername(username: String): Boolean {
        if (username.isEmpty()) {
            AppToast.show("请输入用户名")
            return false
        }
        // 必须为字母和数字组合，且长度固定为 USERNAME_MAX_LENGTH 位，禁止纯数字或纯字母
        // 与 LoginActivity 中的校验规则保持一致
        val regex = Pattern.compile("^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z0-9]{${USERNAME_MAX_LENGTH}}$")
        if (!regex.matcher(username).matches()) {
            AppToast.show("用户名须为${USERNAME_MAX_LENGTH}位，且同时包含字母和数字")
            return false
        }
        return true
    }

    private fun observeViewModel() {
        UserViewModel.registerResultLiveData.observe(this) { success ->
            if (success && UserConfig.isLogin()) {
                AppToast.show("注册成功")
                startActivity(MainActivity::class.java) {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
                }
                finish()
            }
        }

        UserViewModel.registerErrorLiveData.observe(this, object : Observer<String?> {
            override fun onChanged(value: String?) {
                value?.let { AppToast.show(it) }
            }
        })
    }

    override fun initData() {
    }

    override fun listenerExpire(): Boolean = false
}

