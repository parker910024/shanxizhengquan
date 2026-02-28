package com.yanshu.app.ui.dialog

import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import com.yanshu.app.R
import com.yanshu.app.data.VersionInfo

object DialogManager {
}

fun FragmentActivity.showNewVersionDialog(versionInfo: VersionInfo, onDone: () -> Unit) {
    AppDialog.Companion.show(supportFragmentManager) {
        title = getString(R.string.new_version_title)
        content = versionInfo.describe
        done = getString(R.string.new_version_done)
        cancel = if (!versionInfo.isForce()) getString(R.string.new_version_cancel) else ""
        alwaysShow = versionInfo.isForce()
        this.onDone = onDone
    }
}

fun Fragment.showNewVersionDialog(versionInfo: VersionInfo, onDone: () -> Unit) {
    AppDialog.Companion.show(childFragmentManager) {
        title = getString(R.string.new_version_title)
        content = versionInfo.describe
        done = getString(R.string.new_version_done)
        cancel = if (!versionInfo.isForce()) getString(R.string.new_version_cancel) else ""
        alwaysShow = versionInfo.isForce()
        this.onDone = onDone
    }
}

