package com.yanshu.app.util

import android.os.Build
import android.webkit.WebChromeClient
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient

fun WebView.setupForHtmlContent() {
    settings.apply {
        javaScriptEnabled = false
        domStorageEnabled = true
        databaseEnabled = true
        loadWithOverviewMode = true
        useWideViewPort = true
        builtInZoomControls = false
        displayZoomControls = false
        textZoom = 100
        defaultTextEncodingName = "utf-8"
        cacheMode = WebSettings.LOAD_DEFAULT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            mixedContentMode = WebSettings.MIXED_CONTENT_ALWAYS_ALLOW
        }
    }
    webViewClient = WebViewClient()
    webChromeClient = WebChromeClient()
}

fun WebView.loadRawHtml(html: String, baseUrl: String? = null) {
    loadDataWithBaseURL(baseUrl, html, "text/html", "utf-8", null)
}

/** 加载标题 + 正文 HTML（用于新闻详情等），与 SX 一致 */
fun WebView.loadHtmlContent(title: String, content: String, publishTime: String = "", baseUrl: String? = null) {
    val titleHtml = if (title.isNotEmpty()) "<h1 style='font-size:20px;font-weight:bold;margin:12px 0;'>${title.replace("<", "&lt;").replace(">", "&gt;")}</h1>" else ""
    val timeHtml = if (publishTime.isNotEmpty()) "<p style='color:#999;font-size:12px;margin-bottom:12px;'>$publishTime</p>" else ""
    val html = """<!DOCTYPE html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"/><meta charset="utf-8"/></head><body style='margin:16px;'>$titleHtml$timeHtml$content</body></html>"""
    loadRawHtml(html, baseUrl)
}
