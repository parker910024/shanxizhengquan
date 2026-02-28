package ex.ss.lib.http.exception

import ex.ss.lib.http.request.SSHttpRequest

class SSHttpException(
    val request: SSHttpRequest<*>,
    val code: Int = -1,
    val msg: String? = null,
    ex: Throwable? = null
) : Throwable(ex)