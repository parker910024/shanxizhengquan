package ex.ss.lib.tools.common

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Rect
import com.google.zxing.BarcodeFormat
import com.google.zxing.EncodeHintType
import com.google.zxing.MultiFormatWriter
import com.google.zxing.qrcode.QRCodeWriter
import com.google.zxing.qrcode.decoder.ErrorCorrectionLevel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

object ZXingTools {

    suspend fun createQRCode(
        context: Context, content: String, width: Int, height: Int, icon: Int,
    ): Bitmap? {
        return withContext(Dispatchers.IO) {
            runCatching {
                val writer = QRCodeWriter()
                val hints = mutableMapOf<EncodeHintType, Any>()
                hints[EncodeHintType.CHARACTER_SET] = "utf-8"
                hints[EncodeHintType.ERROR_CORRECTION] = ErrorCorrectionLevel.H
                hints[EncodeHintType.MARGIN] = 1
                MultiFormatWriter()
                val encode = writer.encode(content, BarcodeFormat.QR_CODE, width, height, hints)
                val colors = IntArray(width * height)
                for (w in 0 until width) {
                    for (h in 0 until height) {
                        if (encode.get(w, h)) {
                            colors[w * width + h] = Color.BLACK
                        } else {
                            colors[w * width + h] = Color.WHITE
                        }
                    }
                }
                Bitmap.createBitmap(colors, width, height, Bitmap.Config.RGB_565).let { qr ->
                    val iconBitmap = BitmapFactory.decodeResource(context.resources, icon)
                    val bg = qr.copy(Bitmap.Config.RGB_565, true)
                    val canvas = Canvas(bg)
                    val size = qr.width / 4
                    val dest = Rect(
                        qr.width / 2 - size / 2,
                        qr.height / 2 - size / 2,
                        qr.width / 2 + size / 2,
                        qr.height / 2 + size / 2
                    )
                    canvas.drawBitmap(iconBitmap, null, dest, null)
                    if (iconBitmap.isRecycled) iconBitmap.recycle()
                    if (qr.isRecycled) qr.recycle()
                    bg
                }
            }.getOrElse {
                null
            }
        }
    }

}