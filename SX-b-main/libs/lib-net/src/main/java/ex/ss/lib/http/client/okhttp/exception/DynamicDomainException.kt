package ex.ss.lib.http.client.okhttp.exception

import okhttp3.Request
import java.io.IOException

class DynamicDomainException(val request: Request, cause: Throwable?) : IOException(cause)