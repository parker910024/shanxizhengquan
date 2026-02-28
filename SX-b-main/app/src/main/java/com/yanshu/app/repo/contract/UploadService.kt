package com.yanshu.app.repo.contract

import android.util.Log
import com.google.gson.Gson
import com.google.gson.annotations.SerializedName
import com.yanshu.app.config.AppConfigCenter
import com.yanshu.app.config.UserConfig
import com.yanshu.app.data.BaseResponse
import com.yanshu.app.repo.Remote
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.MultipartBody
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.asRequestBody
import java.io.File
import java.util.concurrent.TimeUnit

object UploadService {

    private const val TAG = "ContractUploadService"
    private val gson by lazy { Gson() }

    private val client by lazy {
        OkHttpClient.Builder()
            .connectTimeout(60, TimeUnit.SECONDS)
            .writeTimeout(60, TimeUnit.SECONDS)
            .readTimeout(60, TimeUnit.SECONDS)
            .build()
    }

    suspend fun uploadFile(file: File, mimeType: String = "image/png"): String? = withContext(Dispatchers.IO) {
        try {
            if (!file.exists()) {
                Log.e(TAG, "File not exists: ${file.absolutePath}")
                return@withContext null
            }

            val url = AppConfigCenter.baseDomain.trimEnd('/') + "/api/upload/file"
            val requestBody = file.asRequestBody(mimeType.toMediaTypeOrNull())
            val multipartBody = MultipartBody.Builder()
                .setType(MultipartBody.FORM)
                .addFormDataPart("file", file.name, requestBody)
                .build()

            val request = Request.Builder()
                .url(url)
                .post(multipartBody)
                .addHeader("token", UserConfig.token)
                .build()

            val response = client.newCall(request).execute()
            val responseBody = response.body?.string()
            if (response.code == BaseResponse.EXPIRE && UserConfig.isLogin()) {
                Remote.notifyLoginExpireOnce()
                return@withContext null
            }
            if (!response.isSuccessful || responseBody.isNullOrEmpty()) return@withContext null

            val uploadResponse = gson.fromJson(responseBody, UploadResponse::class.java)
            if (uploadResponse.code == BaseResponse.EXPIRE && UserConfig.isLogin()) {
                Remote.notifyLoginExpireOnce()
                return@withContext null
            }
            if (uploadResponse.code == 0 || uploadResponse.code == 1) {
                return@withContext uploadResponse.data?.path
            }
            null
        } catch (e: Exception) {
            Log.e(TAG, "uploadFile error", e)
            null
        }
    }

    private data class UploadResponse(
        @SerializedName("code") val code: Int = -1,
        @SerializedName("msg") val msg: String = "",
        @SerializedName("data") val data: UploadData? = null,
    )

    private data class UploadData(
        @SerializedName("path") val path: String = "",
    )
}
