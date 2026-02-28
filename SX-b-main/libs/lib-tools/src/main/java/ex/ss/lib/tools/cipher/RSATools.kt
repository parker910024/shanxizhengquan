package ex.ss.lib.tools.cipher

import java.security.KeyPairGenerator
import java.security.PrivateKey
import java.security.PublicKey
import javax.crypto.Cipher

data class RSAKeys(val publicKey: PublicKey, val privateKey: PrivateKey)

object RSATools {

    fun initKeys(): RSAKeys {
        val generator = KeyPairGenerator.getInstance("RSA")
        val genKeyPair = generator.genKeyPair()
        return RSAKeys(genKeyPair.public, genKeyPair.private)
    }

    fun encryptByPublicKey(input: ByteArray, publicKey: PublicKey): ByteArray {
        val cipher = Cipher.getInstance("RSA/ECB/PKCS1Padding")
        cipher.init(Cipher.ENCRYPT_MODE, publicKey)
        cipher.update(input)
        return cipher.doFinal()
    }

    fun decryptByPrivateKey(input: ByteArray, privateKey: PrivateKey): ByteArray {
        val cipher = Cipher.getInstance("RSA/ECB/PKCS1Padding")
        cipher.init(Cipher.DECRYPT_MODE, privateKey)
        cipher.update(input)
        return cipher.doFinal()
    }

}
