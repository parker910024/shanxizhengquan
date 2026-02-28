package ex.ss.lib.components.permission

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import ex.ss.lib.components.result.launchForResult


val FILE_PERMISSIONS = arrayOf(
    Manifest.permission.READ_EXTERNAL_STORAGE,
    Manifest.permission.WRITE_EXTERNAL_STORAGE
)

suspend fun FragmentActivity.requestFilePermissions(openSetting: Boolean = false): Boolean {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
        return if (Environment.isExternalStorageManager()) {
            true
        } else {
            if (openSetting) {
                val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION)
                intent.data = Uri.parse("package:${this.packageName}")
                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                startActivity(intent)
            }
            false
        }
    } else {
        val permissionResult = launchRequestPermissions(FILE_PERMISSIONS)
        return if (permissionResult.any { !it.value }) {
            if (openSetting) {
                val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                intent.data = Uri.parse("package:${this.packageName}")
                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                startActivity(intent)
            }
            false
        } else {
            true
        }
    }
}


suspend fun Fragment.launchRequestPermissions(permissions: Array<String>): Map<String, Boolean> {
    return requireActivity().launchRequestPermissions(permissions)
}

suspend fun FragmentActivity.launchRequestPermissions(permissions: Array<String>): Map<String, Boolean> {
    return if (permissions.any {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }) {
        launchForResult(
            ActivityResultContracts.RequestMultiplePermissions(), permissions
        )
    } else {
        mutableMapOf<String, Boolean>().apply {
            permissions.onEach { put(it, true) }
        }
    }

}