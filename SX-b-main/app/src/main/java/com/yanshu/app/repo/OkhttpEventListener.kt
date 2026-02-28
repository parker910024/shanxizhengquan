package com.yanshu.app.repo

import ex.ss.lib.components.log.SSLog
import okhttp3.Call
import okhttp3.Connection
import okhttp3.EventListener
import okhttp3.EventListener.Factory
import okhttp3.Handshake
import okhttp3.HttpUrl
import okhttp3.Protocol
import okhttp3.Request
import okhttp3.Response
import java.io.IOException
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.Proxy

class OkhttpEventListener : EventListener() {

    private val log by lazy { SSLog.create("OkhttpEventListener") }

    companion object {
        fun get(): Factory {
            return Factory { OkhttpEventListener() }
        }
    }

    override fun cacheConditionalHit(call: Call, cachedResponse: Response) {
        super.cacheConditionalHit(call, cachedResponse)
        log.d("cacheConditionalHit", "${call.request().url}")
    }

    override fun cacheHit(call: Call, response: Response) {
        super.cacheHit(call, response)
        log.d("cacheHit", "${call.request().url}")
    }

    override fun cacheMiss(call: Call) {
        super.cacheMiss(call)
        log.d("cacheMiss", "${call.request().url}")
    }

    override fun callEnd(call: Call) {
        super.callEnd(call)
        log.d("callEnd", "${call.request().url}")
    }

    override fun callFailed(call: Call, ioe: IOException) {
        super.callFailed(call, ioe)
        log.d("callFailed", "${call.request().url} $ioe")
    }

    override fun callStart(call: Call) {
        super.callStart(call)
        log.d("callStart", "${call.request().url}")
    }

    override fun canceled(call: Call) {
        super.canceled(call)
        log.d("canceled", "${call.request().url}")
    }

    override fun connectEnd(
        call: Call,
        inetSocketAddress: InetSocketAddress,
        proxy: Proxy,
        protocol: Protocol?
    ) {
        super.connectEnd(call, inetSocketAddress, proxy, protocol)
        log.d("connectEnd", "${call.request().url}")
    }

    override fun connectFailed(
        call: Call,
        inetSocketAddress: InetSocketAddress,
        proxy: Proxy,
        protocol: Protocol?,
        ioe: IOException
    ) {
        super.connectFailed(call, inetSocketAddress, proxy, protocol, ioe)
        log.d("connectFailed", "${call.request().url}")
    }

    override fun connectStart(call: Call, inetSocketAddress: InetSocketAddress, proxy: Proxy) {
        super.connectStart(call, inetSocketAddress, proxy)
        log.d("connectStart", "${call.request().url}")
    }

    override fun connectionAcquired(call: Call, connection: Connection) {
        super.connectionAcquired(call, connection)
        log.d("connectionAcquired", "${call.request().url}")
    }

    override fun connectionReleased(call: Call, connection: Connection) {
        super.connectionReleased(call, connection)
        log.d("connectionReleased", "${call.request().url}")
    }

    override fun dnsEnd(call: Call, domainName: String, inetAddressList: List<InetAddress>) {
        super.dnsEnd(call, domainName, inetAddressList)
        log.d("dnsEnd", "${call.request().url}")
    }

    override fun dnsStart(call: Call, domainName: String) {
        super.dnsStart(call, domainName)
        log.d("dnsStart", "${call.request().url}")
    }

    override fun proxySelectEnd(call: Call, url: HttpUrl, proxies: List<Proxy>) {
        super.proxySelectEnd(call, url, proxies)
        log.d("proxySelectEnd", "${call.request().url}")
    }

    override fun proxySelectStart(call: Call, url: HttpUrl) {
        super.proxySelectStart(call, url)
        log.d("proxySelectStart", "${call.request().url}")
    }

    override fun requestBodyEnd(call: Call, byteCount: Long) {
        super.requestBodyEnd(call, byteCount)
        log.d("requestBodyEnd", "${call.request().url}")
    }

    override fun requestBodyStart(call: Call) {
        super.requestBodyStart(call)
        log.d("requestBodyStart", "${call.request().url}")
    }

    override fun requestFailed(call: Call, ioe: IOException) {
        super.requestFailed(call, ioe)
        log.d("requestFailed", "${call.request().url}")
    }

    override fun requestHeadersEnd(call: Call, request: Request) {
        super.requestHeadersEnd(call, request)
        log.d("requestHeadersEnd", "${call.request().url}")
    }

    override fun requestHeadersStart(call: Call) {
        super.requestHeadersStart(call)
        log.d("requestHeadersStart", "${call.request().url}")
    }

    override fun responseBodyEnd(call: Call, byteCount: Long) {
        super.responseBodyEnd(call, byteCount)
        log.d("responseBodyEnd", "${call.request().url}")
    }

    override fun responseBodyStart(call: Call) {
        super.responseBodyStart(call)
        log.d("responseBodyStart", "${call.request().url}")
    }

    override fun responseFailed(call: Call, ioe: IOException) {
        super.responseFailed(call, ioe)
        log.d("responseFailed", "${call.request().url}")
    }

    override fun responseHeadersEnd(call: Call, response: Response) {
        super.responseHeadersEnd(call, response)
        log.d("responseHeadersEnd", "${call.request().url}")
    }

    override fun responseHeadersStart(call: Call) {
        super.responseHeadersStart(call)
        log.d("responseHeadersStart", "${call.request().url}")
    }

    override fun satisfactionFailure(call: Call, response: Response) {
        super.satisfactionFailure(call, response)
        log.d("satisfactionFailure", "${call.request().url}")
    }

    override fun secureConnectEnd(call: Call, handshake: Handshake?) {
        super.secureConnectEnd(call, handshake)
        log.d("secureConnectEnd", "${call.request().url}")
    }

    override fun secureConnectStart(call: Call) {
        super.secureConnectStart(call)
        log.d("secureConnectStart", "${call.request().url}")
    }

}