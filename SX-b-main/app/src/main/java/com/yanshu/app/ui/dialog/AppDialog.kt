package com.yanshu.app.ui.dialog

import android.graphics.Bitmap
import androidx.core.view.isVisible
import androidx.fragment.app.FragmentManager
import coil.load
import com.yanshu.app.databinding.DialogAppBinding
import ex.ss.lib.base.dialog.BaseDialog
import ex.ss.lib.base.extension.dp
import ex.ss.lib.base.extension.viewBinding
import java.util.regex.Pattern

class AppDialog(private val builder: AppDialogBuilder) : BaseDialog<DialogAppBinding>() {

    companion object {
        fun show(fragmentManager: FragmentManager, block: AppDialogBuilder.() -> Unit) {
            AppDialogBuilder().apply(block).show(fragmentManager)
        }
    }

    override val binding: DialogAppBinding by viewBinding()

    override fun initView() {
        binding.tvTitle.isVisible = builder.title.isNotEmpty()
        binding.tvTitle.text = builder.title
        binding.tvContent.isVisible = builder.content.isNotEmpty()
        binding.tvContent.text = formatContentWithUrlBreaks(builder.content.toString())
        binding.tvCancel.isVisible = builder.cancel.isNotEmpty()
        binding.tvCancel.text = builder.cancel
        binding.tvDone.isVisible = builder.done.isNotEmpty()
        binding.tvDone.text = builder.done
        binding.ivConnect.isVisible = builder.imgContent != null
        builder.imgContent?.also {
            binding.ivConnect.load(it)
        }

        binding.ivClose.isVisible = !builder.alwaysShow
        binding.ivClose.setOnClickListener {
            if (!builder.alwaysShow) dismiss()
            builder.onAction?.invoke()
            builder.onCancel?.invoke()
        }

        binding.tvCancel.setOnClickListener {
            if (!builder.alwaysShow) dismiss()
            builder.onAction?.invoke()
            builder.onCancel?.invoke()
        }
        binding.tvDone.setOnClickListener {
            dismiss()
            builder.onAction?.invoke()
            builder.onDone?.invoke()
        }
        setOnDismissCallback {
            builder.onClose?.invoke()
        }
    }

    override fun initData() {

    }

    override fun isFullWidth(): Boolean = true
    override fun outsideCancel(): Boolean = builder.cancelOutside
    override fun widthMargin(): Int = 50.dp
    
    private fun formatContentWithUrlBreaks(content: String): String {
        val urlPattern = Pattern.compile(
            "\\s*(https?://[\\w\\-._~:/?#\\[\\]@!$&'()*+,;=%]+)\\s*",
            Pattern.CASE_INSENSITIVE
        )
        val matcher = urlPattern.matcher(content)
        val result = StringBuffer()
        
        while (matcher.find()) {
            val url = matcher.group(1)
            
            val beforeMatch = if (matcher.start() > 0) {
                content.substring(matcher.start() - 1, matcher.start())
            } else {
                ""
            }
            
            val afterMatch = if (matcher.end() < content.length) {
                content.substring(matcher.end(), matcher.end() + 1)
            } else {
                ""
            }
            
            val replacement = buildString {
                if (beforeMatch != "\n" && matcher.start() > 0) append("\n")
                append(url)
                if (afterMatch != "\n" && matcher.end() < content.length) append("\n")
            }
            
            matcher.appendReplacement(result, replacement)
        }
        matcher.appendTail(result)
        
        return result.toString()
    }
}

class AppDialogBuilder internal constructor() {

    var onCancel: (() -> Unit)? = null
    var onDone: (() -> Unit)? = null
    var onAction: (() -> Unit)? = null
    var onClose: (() -> Unit)? = null

    var title: CharSequence = ""
    var content: CharSequence = ""
    var cancel: CharSequence = ""
    var done: CharSequence = ""
    var imgContent: Bitmap? = null
    var cancelOutside: Boolean = false
    var alwaysShow: Boolean = false
    fun show(manager: FragmentManager) {
        AppDialog(this).show(manager, "AppDialog")
    }
}

