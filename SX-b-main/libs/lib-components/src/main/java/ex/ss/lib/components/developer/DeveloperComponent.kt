package ex.ss.lib.components.developer

import android.content.Context
import android.widget.EditText
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import java.util.concurrent.atomic.AtomicReference

object DeveloperComponent {

    private val actionMapper = mutableMapOf<String, () -> Unit>()
    private val openPassword = AtomicReference("")

    fun register(name: String, block: () -> Unit) {
        actionMapper[name] = block
    }

    fun openPasswordCheck(password: String) {
        openPassword.set(password)
    }

    fun show(context: Context) {
        val checkPassword = openPassword.get()
        if (checkPassword.isNullOrEmpty()) {
            showDevelopActionDialog(context)
        } else {
            showDevelopPasswordDialog(context) {
                showDevelopActionDialog(context)
            }
        }
    }

    private fun showDevelopActionDialog(context: Context) {
        AlertDialog.Builder(context)
            .setTitle("DevelopAction")
            .apply {
                val items = actionMapper.map { it.key }.toTypedArray()
                setItems(items) { dialog, which ->
                    dialog.dismiss()
                    val name = items[which]
                    actionMapper[name]?.invoke()
                }
            }.show()
    }

    private fun showDevelopPasswordDialog(context: Context, onSuccess: () -> Unit) {
        val checkPassword = openPassword.get()
        AlertDialog.Builder(context)
            .setTitle("Password")
            .apply {
                val editText = EditText(context)
                setView(editText)
                setPositiveButton("Done") { dialog, _ ->
                    dialog.dismiss()
                    val inputPassword = editText.text.toString()
                    if (checkPassword == inputPassword) {
                        onSuccess.invoke()
                    } else {
                        Toast.makeText(context, "wrong password", Toast.LENGTH_SHORT).show()
                    }
                }
                setNegativeButton("Cancel") { dialog, _ ->
                    dialog.dismiss()
                }
            }.show()
    }

}