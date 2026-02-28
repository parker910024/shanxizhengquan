package ex.ss.lib.http.client.okhttp.dynamic

import ex.ss.lib.http.request.SSHttpRequest

interface IDynamicDomainClient {

    suspend fun initialize(loader: IDynamicDomainsLoader)

    suspend fun <Response> buildRequest(request: SSHttpRequest<Response>): SSHttpRequest<Response>

    suspend fun <Response> canRetryDynamicDomain(request: SSHttpRequest<Response>): Boolean

    fun isInitialized(): Boolean

}

object EmptyDynamicDomainClient : IDynamicDomainClient {

    override suspend fun initialize(loader: IDynamicDomainsLoader) {}

    override suspend fun <Response> buildRequest(request: SSHttpRequest<Response>): SSHttpRequest<Response> {
        return request
    }

    override suspend fun <Response> canRetryDynamicDomain(request: SSHttpRequest<Response>): Boolean {
        return false
    }

    override fun isInitialized(): Boolean = true

}