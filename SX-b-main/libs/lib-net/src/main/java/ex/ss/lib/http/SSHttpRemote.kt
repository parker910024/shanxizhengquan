package ex.ss.lib.http

import ex.ss.lib.http.bean.ResponseData
import ex.ss.lib.http.client.ISSHttpClient
import ex.ss.lib.http.client.okhttp.dynamic.EmptyDynamicDomainClient
import ex.ss.lib.http.client.okhttp.dynamic.IDynamicDomainClient
import ex.ss.lib.http.exception.SSHttpException
import ex.ss.lib.http.request.SSHttpRequest
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.withContext

abstract class SSHttpRemote<T> {

    private val client: ISSHttpClient by lazy { SSHttp.requireHttpClient() }

    abstract val api: T

    open val dynamicDomainClient: IDynamicDomainClient = EmptyDynamicDomainClient

    open fun <Response> processException(exception: SSHttpException): ResponseData<Response> {
        return ResponseData.failed(exception.code, exception.msg ?: exception.message)
    }

    fun <Response> callFlow(block: T.() -> SSHttpRequest<Response>): Flow<ResponseData<Response>> =
        flow { emit(call(block)) }

    suspend fun <Response> call(block: T.() -> SSHttpRequest<Response>): ResponseData<Response> =
        withContext(Dispatchers.IO) {
            return@withContext runCatching {
                val response = request(block(api))
                ResponseData.success(response)
            }.getOrElse {
                val exception = getSSHttpException(it)
                if (exception != null) {
                    processException(exception)
                } else {
                    ResponseData.failed(it)
                }
            }
        }

    private suspend fun <Response> request(request: SSHttpRequest<Response>): Response {
        val dynamicRequest = dynamicDomainClient.buildRequest(request)
        return runCatching {
            client.request(dynamicRequest)
        }.getOrElse {
            if (dynamicDomainClient.canRetryDynamicDomain(dynamicRequest)) {
                request(dynamicRequest)
            } else {
                throw it
            }
        }
    }

    protected fun getSSHttpException(ex: Throwable): SSHttpException? {
        if (ex is SSHttpException) return ex
        val cause = ex.cause
        if (cause != null) return getSSHttpException(cause)
        return null
    }

}