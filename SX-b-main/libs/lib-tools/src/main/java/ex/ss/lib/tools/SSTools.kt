package ex.ss.lib.tools

import ex.ss.lib.tools.cipher.AESTools
import ex.ss.lib.tools.cipher.RSATools
import ex.ss.lib.tools.cipher.ThreeDESTools
import ex.ss.lib.tools.common.APKTools
import ex.ss.lib.tools.common.BrowserTools
import ex.ss.lib.tools.common.CopyTools
import ex.ss.lib.tools.common.DevicesTools
import ex.ss.lib.tools.common.HashTools
import ex.ss.lib.tools.common.ProcessTools
import ex.ss.lib.tools.common.RandomTools
import ex.ss.lib.tools.common.SpannableTools
import ex.ss.lib.tools.common.VPNTools
import ex.ss.lib.tools.common.ZXingTools
import ex.ss.lib.tools.share.ShareTools

object SSTools {

    val Spannable: SpannableTools.Builder
        get() = SpannableTools.Builder()

    val VPN = VPNTools

    val Random = RandomTools

    val Hash = HashTools

    val Share = ShareTools

    val APK = APKTools

    val Browser = BrowserTools

    val Copy = CopyTools

    val Devices = DevicesTools

    val AES = AESTools

    val RSA = RSATools

    val ThreeDES = ThreeDESTools

    val Process = ProcessTools

    val ZXing = ZXingTools

}