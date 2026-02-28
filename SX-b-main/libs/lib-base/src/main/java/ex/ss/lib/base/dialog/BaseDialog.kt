package ex.ss.lib.base.dialog

import android.app.Dialog
import android.content.DialogInterface
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import androidx.fragment.app.DialogFragment
import androidx.viewbinding.ViewBinding

typealias OnDialogCallback = () -> Unit

abstract class BaseDialog<VB : ViewBinding> : DialogFragment() {

    protected abstract val binding: VB

    private var onDialogDismissCallback: OnDialogCallback? = null

    fun setOnDismissCallback(onDialogCallback: OnDialogCallback) {
        onDialogDismissCallback = onDialogCallback
    }

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?,
    ): View? {
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        updateDimAmount(dialog)
        initView()
        initData()
    }

    abstract fun initView()

    abstract fun initData()

    override fun onCreateDialog(savedInstanceState: Bundle?): Dialog {
        return super.onCreateDialog(savedInstanceState).apply {
            updateDimAmount(this)
        }
    }

    override fun onStart() {
        super.onStart()
        dialog?.apply {
            setCanceledOnTouchOutside(outsideCancel())
            setCancelable(outsideCancel())
            window?.apply {
                val width = if (isFullWidth()) {
                    resources.displayMetrics.widthPixels - widthMargin()
                } else {
                    WindowManager.LayoutParams.WRAP_CONTENT
                }
                val height = if (isFullHeight()) {
                    resources.displayMetrics.heightPixels - heightMargin()
                } else {
                    WindowManager.LayoutParams.WRAP_CONTENT
                }
                setLayout(width, height)
                setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
            }
        }
    }

    private fun updateDimAmount(dialog: Dialog?) {
        dialog?.window?.also {
            val params = it.attributes
            params.dimAmount = dimAmount()
            it.attributes = params
        }
    }

    override fun onDismiss(dialog: DialogInterface) {
        super.onDismiss(dialog)
        onDialogDismissCallback?.invoke()
    }

    open fun isFullWidth() = false

    open fun isFullHeight() = false

    open fun widthMargin() = 0

    open fun heightMargin() = 0

    open fun outsideCancel() = true

    open fun dimAmount() = 0.5F

}