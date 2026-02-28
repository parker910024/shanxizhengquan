package com.yanshu.app.ui.realname

import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import android.net.Uri
import android.util.Log
import android.view.View
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AlertDialog
import androidx.core.content.FileProvider
import androidx.lifecycle.lifecycleScope
import com.yanshu.app.R
import com.yanshu.app.base.BasicActivity
import com.yanshu.app.data.AuthenticationRequest
import com.yanshu.app.databinding.ActivityRealnameBinding
import com.yanshu.app.repo.contract.ContractRemote
import com.yanshu.app.repo.contract.UploadService
import com.yanshu.app.ui.dialog.AppToast
import ex.ss.lib.base.extension.viewBinding
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File

class RealNameActivity : BasicActivity<ActivityRealnameBinding>() {

    companion object {
        private const val TAG = "RealNameActivity"
        private const val EXTRA_STATUS = "status"
        private const val RETRY_REALNAME_TEXT = "\u91CD\u65B0\u5B9E\u540D\u8BA4\u8BC1"
        private const val ID_NUMBER_LENGTH_15 = 15
        private const val ID_NUMBER_LENGTH_18 = 18

        // 璁よ瘉鐘舵€侊紙涓庢湇鍔″櫒 is_audit 瀵瑰簲锛?/绌?鏈璇?1=閫氳繃 2=椹冲洖 3=瀹℃牳涓級
        const val STATUS_NOT_VERIFIED = 0
        const val STATUS_PENDING = 1
        const val STATUS_VERIFIED = 2
        const val STATUS_REJECTED = 3

        fun start(context: Context, status: Int = STATUS_NOT_VERIFIED) {
            context.startActivity(Intent(context, RealNameActivity::class.java).apply {
                putExtra(EXTRA_STATUS, status)
            })
        }
    }

    override val binding: ActivityRealnameBinding by viewBinding()

    private var currentStatus = STATUS_NOT_VERIFIED
    private var rejectReason: String = ""
    private var isLoading = false

    private var frontImageUri: Uri? = null
    private var backImageUri: Uri? = null
    private var pendingCaptureUri: Uri? = null

    private val pickImage = registerForActivityResult(ActivityResultContracts.GetContent()) { uri: Uri? ->
        if (uri == null) return@registerForActivityResult
        applySelectedImage(uri)
    }

    private val takePicture = registerForActivityResult(ActivityResultContracts.TakePicture()) { success ->
        if (!success) {
            pendingCaptureUri = null
            return@registerForActivityResult
        }
        val uri = pendingCaptureUri ?: return@registerForActivityResult
        pendingCaptureUri = null
        applySelectedImage(uri)
    }

    private fun applySelectedImage(uri: Uri) {
        when (pendingImageSide) {
            0 -> {
                frontImageUri = uri
                binding.ivFront.setImageURI(uri)
                binding.ivFrontCamera.visibility = View.GONE
            }
            1 -> {
                backImageUri = uri
                binding.ivBack.setImageURI(uri)
                binding.ivBackCamera.visibility = View.GONE
            }
        }
    }

    private var pendingImageSide = 0 // 0=front 1=back

    override fun initView() {
        currentStatus = intent.getIntExtra(EXTRA_STATUS, STATUS_NOT_VERIFIED)
        setupTitleBar()
        setupClickListeners()
        updateUI()
    }

    private fun setupTitleBar() {
        binding.titleBar.tvTitle.text = getString(R.string.realname_title)
        binding.titleBar.tvTitle.setTextColor(getColor(R.color.black))
        binding.titleBar.tvBack.compoundDrawableTintList = ColorStateList.valueOf(getColor(R.color.black))
        binding.titleBar.tvBack.setOnClickListener { finish() }
        binding.titleBar.tvMenu.visibility = View.GONE
    }

    private fun setupClickListeners() {
        binding.flFront.setOnClickListener {
            if (isLoading) return@setOnClickListener
            pendingImageSide = 0
            showImageSourceDialog()
        }
        binding.flBack.setOnClickListener {
            if (isLoading) return@setOnClickListener
            pendingImageSide = 1
            showImageSourceDialog()
        }
        binding.btnSubmit.setOnClickListener {
            if (isLoading) return@setOnClickListener
            submitVerification()
        }
        binding.btnConfirm.setOnClickListener {
            if (isLoading) return@setOnClickListener
            handleResultAction()
        }
    }

    private fun showImageSourceDialog() {
        val options = arrayOf("\u62CD\u7167", "\u4ECE\u76F8\u518C\u9009\u62E9")
        AlertDialog.Builder(this)
            .setItems(options) { _, which ->
                if (which == 0) {
                    openCamera()
                } else {
                    pickImage.launch("image/*")
                }
            }
            .show()
    }

    private fun openCamera() {
        val captureUri = createImageCaptureUri()
        if (captureUri == null) {
            AppToast.show("\u65E0\u6CD5\u6253\u5F00\u76F8\u673A\uFF0C\u8BF7\u7A0D\u540E\u91CD\u8BD5")
            return
        }
        pendingCaptureUri = captureUri
        takePicture.launch(captureUri)
    }

    private fun createImageCaptureUri(): Uri? {
        return try {
            val folder = File(cacheDir, "realname_camera").apply { mkdirs() }
            val side = if (pendingImageSide == 0) "front" else "back"
            val file = File(folder, "id_${side}_${System.currentTimeMillis()}.jpg")
            if (!file.exists()) {
                file.createNewFile()
            }
            FileProvider.getUriForFile(
                this,
                "${applicationContext.packageName}.fileprovider",
                file
            )
        } catch (_: Exception) {
            null
        }
    }

    private fun handleResultAction() {
        if (isLoading) return
        if (currentStatus == STATUS_REJECTED) {
            currentStatus = STATUS_NOT_VERIFIED
            updateUI()
            return
        }
        finish()
    }

    private fun setLoading(loading: Boolean, text: String = "\u52A0\u8F7D\u4E2D...") {
        isLoading = loading
        binding.layoutLoading.visibility = if (loading) View.VISIBLE else View.GONE
        binding.tvLoading.text = text
        binding.btnSubmit.isEnabled = !loading
        binding.btnConfirm.isEnabled = !loading
        binding.flFront.isEnabled = !loading
        binding.flBack.isEnabled = !loading
    }

    private fun updateUI() {
        when (currentStatus) {
            STATUS_NOT_VERIFIED -> {
                binding.svForm.visibility = View.VISIBLE
                binding.llResult.visibility = View.GONE
            }
            STATUS_PENDING -> {
                binding.svForm.visibility = View.GONE
                binding.llResult.visibility = View.VISIBLE
                binding.tvResult.text = getString(R.string.realname_pending)
                binding.btnConfirm.text = getString(R.string.realname_confirm)
            }
            STATUS_VERIFIED -> {
                binding.svForm.visibility = View.GONE
                binding.llResult.visibility = View.VISIBLE
                binding.tvResult.text = getString(R.string.realname_success)
                binding.btnConfirm.text = getString(R.string.realname_confirm)
            }
            STATUS_REJECTED -> {
                binding.svForm.visibility = View.GONE
                binding.llResult.visibility = View.VISIBLE
                binding.tvResult.text = getString(R.string.realname_rejected).let { fmt ->
                    if (rejectReason.isNotEmpty()) "$fmt\n$rejectReason" else fmt
                }
                binding.btnConfirm.text = RETRY_REALNAME_TEXT
            }
        }
    }

    override fun initData() {
        loadAuthenticationDetail()
    }

    private fun loadAuthenticationDetail() {
        lifecycleScope.launch {
            val response = ContractRemote.callApiSilent { getAuthenticationDetail() }
            if (!response.isSuccess()) {
                updateUI()
                return@launch
            }
            val detail = response.data?.detail ?: run {
                currentStatus = STATUS_NOT_VERIFIED
                rejectReason = ""
                updateUI()
                return@launch
            }
            currentStatus = when {
                detail.isApproved -> STATUS_VERIFIED
                detail.isRejected -> {
                    rejectReason = detail.reject
                    STATUS_REJECTED
                }
                detail.isPending -> STATUS_PENDING
                else -> STATUS_NOT_VERIFIED
            }
            if (currentStatus != STATUS_REJECTED) {
                rejectReason = ""
            }
            if ((currentStatus == STATUS_NOT_VERIFIED || currentStatus == STATUS_REJECTED) && detail.hasSubmitted) {
                binding.etName.setText(detail.name)
                binding.etIdNumber.setText(detail.id_card)
            }
            updateUI()
        }
    }

    private fun submitVerification() {
        val name = binding.etName.text.toString().trim()
        val idNumber = binding.etIdNumber.text.toString().trim()

        if (name.isEmpty()) {
            AppToast.show("\u8BF7\u8F93\u5165\u771F\u5B9E\u59D3\u540D")
            return
        }
        if (idNumber.isEmpty()) {
            AppToast.show("\u8BF7\u8F93\u5165\u8EAB\u4EFD\u8BC1\u53F7\u7801")
            return
        }
        if (!isValidIdNumber(idNumber)) {
            AppToast.show("\u8BF7\u8F93\u5165\u6B63\u786E\u7684\u8EAB\u4EFD\u8BC1\u53F7\u7801")
            return
        }
        if (frontImageUri == null) {
            AppToast.show("\u8BF7\u4E0A\u4F20\u8EAB\u4EFD\u8BC1\u4EBA\u50CF\u9762")
            return
        }
        if (backImageUri == null) {
            AppToast.show("\u8BF7\u4E0A\u4F20\u8EAB\u4EFD\u8BC1\u56FD\u5FBD\u9762")
            return
        }

        lifecycleScope.launch {
            setLoading(true, "\u4E0A\u4F20\u7167\u7247\u4E2D...")
            try {
                val frontPath = uriToFileAndUpload(frontImageUri!!, "realname_front")
                val backPath = uriToFileAndUpload(backImageUri!!, "realname_back")
                if (frontPath.isNullOrBlank() || backPath.isNullOrBlank()) {
                    AppToast.show("\u56FE\u7247\u4E0A\u4F20\u5931\u8D25")
                    return@launch
                }

                setLoading(true, "\u63D0\u4EA4\u4E2D...")
                val response = ContractRemote.callApi {
                    submitAuthentication(
                        AuthenticationRequest(
                            name = name,
                            id_card = idNumber,
                            f = frontPath,
                            b = backPath,
                        )
                    )
                }
                if (response.isSuccess()) {
                    AppToast.show("\u63D0\u4EA4\u6210\u529F\uFF0C\u7B49\u5F85\u5BA1\u6838")
                    currentStatus = STATUS_PENDING
                    updateUI()
                }
            } catch (t: Throwable) {
                Log.e(TAG, "submitVerification failed", t)
                AppToast.show("\u63D0\u4EA4\u5931\u8D25\uFF0C\u8BF7\u7A0D\u540E\u91CD\u8BD5")
            } finally {
                setLoading(false)
            }
        }
    }

    private suspend fun uriToFileAndUpload(uri: Uri, prefix: String): String? = withContext(Dispatchers.IO) {
        try {
            val mimeType = contentResolver.getType(uri) ?: "image/jpeg"
            val ext = if (mimeType.contains("png")) ".png" else ".jpg"
            val file = File(cacheDir, "${prefix}_${System.currentTimeMillis()}$ext")
            contentResolver.openInputStream(uri)?.use { stream ->
                file.outputStream().use { out -> stream.copyTo(out) }
            } ?: return@withContext null
            UploadService.uploadFile(file, mimeType)
        } catch (t: Throwable) {
            Log.e(TAG, "uriToFileAndUpload failed, uri=$uri", t)
            null
        }
    }

    private fun isValidIdNumber(idNumber: String): Boolean {
        return idNumber.length == ID_NUMBER_LENGTH_15 || idNumber.length == ID_NUMBER_LENGTH_18
    }
}


