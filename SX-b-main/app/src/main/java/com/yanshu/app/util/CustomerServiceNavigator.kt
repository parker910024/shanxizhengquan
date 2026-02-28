package com.yanshu.app.util

import androidx.fragment.app.FragmentActivity
import com.yanshu.app.repo.contract.ContractRemote
import com.yanshu.app.ui.dialog.AppToast
import com.yanshu.app.ui.web.SimpleWebActivity
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

object CustomerServiceNavigator {

    private const val UNAVAILABLE_MESSAGE = "客服暂不可用"

    fun open(activity: FragmentActivity, scope: CoroutineScope) {
        scope.launch {
            val response = ContractRemote.callApiSilent { getConfig() }
            val rawUrl = response.data.kf_url.trim()
            if (rawUrl.isEmpty()) {
                AppToast.show(UNAVAILABLE_MESSAGE)
                return@launch
            }
            val fullUrl = if (rawUrl.startsWith("http://") || rawUrl.startsWith("https://")) {
                rawUrl
            } else {
                "https://$rawUrl"
            }
            runCatching { SimpleWebActivity.start(activity, "客服", fullUrl) }.onFailure {
                AppToast.show(UNAVAILABLE_MESSAGE)
            }
        }
    }
}
