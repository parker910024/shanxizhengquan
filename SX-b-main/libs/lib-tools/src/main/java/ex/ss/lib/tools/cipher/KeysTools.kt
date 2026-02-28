package ex.ss.lib.tools.cipher

import java.security.KeyFactory
import java.security.PublicKey
import java.security.spec.X509EncodedKeySpec

object KeysTools {

    fun reductionPublicKey(key: ByteArray): PublicKey {
        val keyFactory = KeyFactory.getInstance("RSA")
        return keyFactory.generatePublic(X509EncodedKeySpec(key))
    }

}