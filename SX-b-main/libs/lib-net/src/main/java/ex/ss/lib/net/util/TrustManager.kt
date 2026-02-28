package ex.ss.lib.net.util

import android.annotation.SuppressLint
import okhttp3.OkHttpClient
import java.security.SecureRandom
import java.security.cert.X509Certificate
import javax.net.ssl.SSLContext
import javax.net.ssl.X509TrustManager

internal object TrustManager {

    /*信任所有HTTPS的证书*/
    fun trustAllHttpsCertificates(builder: OkHttpClient.Builder) {
        builder.hostnameVerifier { _, _ -> true }
        val sslContext = SSLContext.getInstance("TLS")
        val trustAllManager = trustAllManager()
        val trustAllManagers = arrayOf(trustAllManager())
        sslContext.init(null, trustAllManagers, SecureRandom())
        builder.sslSocketFactory(sslContext.socketFactory, trustAllManager)
    }

    @SuppressLint("CustomX509TrustManager")
    private fun trustAllManager(): X509TrustManager {
        return object : X509TrustManager {
            override fun checkClientTrusted(chain: Array<out X509Certificate>?, authType: String?) {

            }

            override fun checkServerTrusted(chain: Array<out X509Certificate>?, authType: String?) {

            }

            override fun getAcceptedIssuers(): Array<X509Certificate> {
                return arrayOf()
            }
        }
    }

}