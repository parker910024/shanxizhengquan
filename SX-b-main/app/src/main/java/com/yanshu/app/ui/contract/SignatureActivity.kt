package com.yanshu.app.ui.contract

import android.app.Activity
import android.content.Intent
import android.content.res.ColorStateList
import android.graphics.Bitmap
import android.view.MotionEvent
import androidx.core.view.isVisible
import com.yanshu.app.R
import com.yanshu.app.base.BasicActivity
import com.yanshu.app.databinding.ActivitySignatureBinding
import com.yanshu.app.ui.dialog.AppToast
import ex.ss.lib.base.extension.viewBinding
import java.io.File
import java.io.FileOutputStream

class SignatureActivity : BasicActivity<ActivitySignatureBinding>() {

    companion object {
        const val EXTRA_SIGNATURE_PATH = "signature_path"

        fun start(activity: Activity, requestCode: Int) {
            activity.startActivityForResult(Intent(activity, SignatureActivity::class.java), requestCode)
        }
    }

    override val binding: ActivitySignatureBinding by viewBinding()

    override fun initView() {
        setupTitleBar()
        setupView()
    }

    override fun initData() = Unit

    override fun listenerExpire(): Boolean = false

    private fun setupTitleBar() {
        binding.titleBar.tvTitle.text = getString(R.string.signature_title)
        binding.titleBar.tvTitle.setTextColor(getColor(R.color.black))
        binding.titleBar.tvBack.compoundDrawableTintList = ColorStateList.valueOf(getColor(R.color.black))
        binding.titleBar.tvBack.setOnClickListener { finish() }
        binding.titleBar.tvMenu.visibility = android.view.View.GONE
    }

    private fun setupView() {
        binding.signatureView.setOnTouchListener { _, event ->
            if (event.action == MotionEvent.ACTION_DOWN) {
                binding.tvHint.isVisible = false
            }
            false
        }

        binding.btnClear.setOnClickListener {
            binding.signatureView.clear()
            binding.tvHint.isVisible = true
        }

        binding.btnConfirm.setOnClickListener {
            confirmSignature()
        }
    }

    private fun confirmSignature() {
        if (!binding.signatureView.hasSignature()) {
            AppToast.show(getString(R.string.signature_please_first))
            return
        }

        val bitmap = binding.signatureView.getCroppedSignatureBitmap()
        if (bitmap == null) {
            AppToast.show(getString(R.string.signature_get_failed))
            return
        }

        val signaturePath = saveSignatureToFile(bitmap)
        if (signaturePath.isNullOrBlank()) {
            AppToast.show(getString(R.string.signature_save_failed))
            return
        }

        setResult(Activity.RESULT_OK, Intent().apply {
            putExtra(EXTRA_SIGNATURE_PATH, signaturePath)
        })
        finish()
    }

    private fun saveSignatureToFile(bitmap: Bitmap): String? {
        return runCatching {
            val dir = File(cacheDir, "signatures").apply { mkdirs() }
            val file = File(dir, "signature_${System.currentTimeMillis()}.png")
            FileOutputStream(file).use { out ->
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
            }
            file.absolutePath
        }.getOrNull()
    }
}
