package com.yanshu.app.ui.web

import android.view.KeyEvent
import android.view.ViewGroup
import android.webkit.WebView
import com.just.agentweb.AgentWeb
import com.just.agentweb.AgentWebSettingsImpl
import com.just.agentweb.AgentWebUIControllerImplBase
import com.just.agentweb.DefaultWebClient.OpenOtherPageWays
import com.just.agentweb.IAgentWebSettings
import com.just.agentweb.IWebLayout
import com.just.agentweb.MiddlewareWebChromeBase
import com.just.agentweb.MiddlewareWebClientBase
import com.just.agentweb.PermissionInterceptor
import com.just.agentweb.R
import com.just.agentweb.WebChromeClient
import com.just.agentweb.WebViewClient
import com.yanshu.app.base.BasicActivity
import com.yanshu.app.databinding.ActivityWebBinding

abstract class BaseWebActivity : BasicActivity<ActivityWebBinding>() {

    protected lateinit var mAgentWeb: AgentWeb
    private var mMiddleWareWebChrome: MiddlewareWebChromeBase? = null
    private var mMiddleWareWebClient: MiddlewareWebClientBase? = null

    override fun initView() {
        buildAgentWeb()
    }

    protected open fun buildAgentWeb() {
        mAgentWeb = AgentWeb.with(this).setAgentWebParent(
            binding.frameLayout, ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT
            )
        ).useDefaultIndicator(-1, -1).setWebChromeClient(getWebChromeClient())
            .setWebViewClient(getWebViewClient()).setWebView(getWebView())
            .setPermissionInterceptor(getPermissionInterceptor()).setWebLayout(getWebLayout())
            .setAgentWebUIController(getAgentWebUIController()).interceptUnkownUrl()
            .setOpenOtherPageWays(getOpenOtherAppWay())
            .useMiddlewareWebChrome(getMiddleWareWebChrome())
            .useMiddlewareWebClient(getMiddleWareWebClient())
            .setAgentWebWebSettings(getAgentWebSettings())
            .setMainFrameErrorView(R.layout.agentweb_error_page, 0)
            .setSecurityType(AgentWeb.SecurityType.STRICT_CHECK).createAgentWeb().ready()
            .go(getUrl())
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        return if (mAgentWeb.handleKeyEvent(keyCode, event)) {
            true
        } else super.onKeyDown(keyCode, event)
    }

    override fun onPause() {
        mAgentWeb.webLifeCycle.onPause()
        super.onPause()
    }

    override fun onResume() {
        mAgentWeb.webLifeCycle.onResume()
        super.onResume()
    }

    override fun onDestroy() {
        mAgentWeb.webLifeCycle.onDestroy()
        super.onDestroy()
    }

    abstract fun getUrl(): String

    open fun getAgentWebSettings(): IAgentWebSettings<*>? {
        return AgentWebSettingsImpl.getInstance()
    }

    protected open fun getWebChromeClient(): WebChromeClient? {
        return null
    }

    protected open fun getWebViewClient(): WebViewClient? {
        return null
    }

    protected open fun getWebView(): WebView? {
        return null
    }

    protected open fun getWebLayout(): IWebLayout<*, *>? {
        return null
    }

    protected open fun getPermissionInterceptor(): PermissionInterceptor? {
        return null
    }

    open fun getAgentWebUIController(): AgentWebUIControllerImplBase {
        return object : AgentWebUIControllerImplBase() {
            override fun onLoading(p0: String?) {
                // 可以在这里显示加载进度
            }

            override fun onCancelLoading() {
                // 可以在这里隐藏加载进度
            }
        }
    }

    open fun getOpenOtherAppWay(): OpenOtherPageWays? {
        return null
    }

    protected open fun getMiddleWareWebChrome(): MiddlewareWebChromeBase {
        return object : MiddlewareWebChromeBase() {
            override fun onReceivedTitle(view: WebView, title: String) {
                super.onReceivedTitle(view, title)
                setTitle(view, title)
            }
        }.also { mMiddleWareWebChrome = it }
    }

    protected open fun setTitle(view: WebView?, title: String?) {}

    protected open fun getMiddleWareWebClient(): MiddlewareWebClientBase {
        return object : MiddlewareWebClientBase() {}.also { mMiddleWareWebClient = it }
    }
}
