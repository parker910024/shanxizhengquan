package ex.ss.lib.http.client

import ex.ss.lib.http.exception.SSHttpException
import ex.ss.lib.http.request.SSHttpRequest
import kotlin.jvm.Throws

interface ISSHttpClient {

    @Throws(SSHttpException::class)
    suspend fun <Response> request(request: SSHttpRequest<Response>): Response

}