package ex.ss.lib.tools.extension

import android.text.method.HideReturnsTransformationMethod
import android.text.method.PasswordTransformationMethod
import android.view.View
import android.view.inputmethod.EditorInfo
import android.widget.EditText
import java.util.concurrent.atomic.AtomicBoolean

fun EditText.passwordStyle(toggleView: View, defShow: Boolean = false) {
    inputType = EditorInfo.TYPE_TEXT_VARIATION_PASSWORD
    val showPwd = AtomicBoolean(defShow)
    transformationMethod = if (showPwd.get()) {
        HideReturnsTransformationMethod.getInstance()
    } else {
        PasswordTransformationMethod.getInstance()
    }
    toggleView.setOnClickListener {
        transformationMethod = if (showPwd.get()) {
            PasswordTransformationMethod.getInstance()
        } else {
            HideReturnsTransformationMethod.getInstance()
        }
        showPwd.set(!showPwd.get())
        toggleView.isSelected = showPwd.get()
        setSelection(this.length())
    }
}