package com.yanshu.app.ui.contract

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import android.graphics.BitmapFactory
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.view.isVisible
import androidx.lifecycle.lifecycleScope
import com.yanshu.app.R
import com.yanshu.app.base.BasicActivity
import com.yanshu.app.config.AppConfigCenter
import com.yanshu.app.data.AuthenticationDetailItem
import com.yanshu.app.data.ContractInfo
import com.yanshu.app.data.ContractTemplateOne
import com.yanshu.app.data.ContractTemplateTwo
import com.yanshu.app.data.CreateContractRequest
import com.yanshu.app.data.SignContractRequest
import com.yanshu.app.databinding.ActivityContractDetailBinding
import com.yanshu.app.repo.contract.ContractRemote
import com.yanshu.app.repo.contract.UploadService
import com.yanshu.app.ui.dialog.AppToast
import com.yanshu.app.util.ImageUrlUtils
import com.yanshu.app.util.loadRawHtml
import com.yanshu.app.util.setupForHtmlContent
import ex.ss.lib.base.extension.viewBinding
import kotlinx.coroutines.launch
import java.io.File

class ContractDetailActivity : BasicActivity<ActivityContractDetailBinding>() {

    companion object {
        private const val EXTRA_CONTRACT_ID = "contract_id"
        private const val EXTRA_CONTRACT_TYPE = "contract_type"
        private const val EXTRA_CONTRACT_NAME = "contract_name"
        const val EXTRA_CONTRACT_ADDRESS = "contract_address"

        fun createIntent(
            context: Context,
            contractId: Int,
            contractType: Int,
            contractName: String,
        ): Intent {
            return Intent(context, ContractDetailActivity::class.java).apply {
                putExtra(EXTRA_CONTRACT_ID, contractId)
                putExtra(EXTRA_CONTRACT_TYPE, contractType)
                putExtra(EXTRA_CONTRACT_NAME, contractName)
            }
        }
    }

    override val binding: ActivityContractDetailBinding by viewBinding()

    private var contractId: Int = 0
    private var contractType: Int = 1
    private var contractName: String = ""
    private var extraAddress: String = ""

    private var contractInfo: ContractInfo? = null
    private var templateOne: ContractTemplateOne? = null
    private var templateTwo: ContractTemplateTwo? = null
    private var authInfo: AuthenticationDetailItem? = null

    private var signatureImagePath: String? = null

    private val signatureLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        if (result.resultCode != Activity.RESULT_OK) return@registerForActivityResult
        val signaturePath = result.data?.getStringExtra(SignatureActivity.EXTRA_SIGNATURE_PATH)
        if (signaturePath.isNullOrBlank()) {
            AppToast.show(getString(R.string.signature_get_failed))
            return@registerForActivityResult
        }
        signatureImagePath = signaturePath
        val bitmap = BitmapFactory.decodeFile(signaturePath)
        if (bitmap == null) {
            AppToast.show(getString(R.string.signature_get_failed))
            return@registerForActivityResult
        }
        binding.tvSignatureHint.isVisible = false
        binding.ivPreviewSignature.isVisible = true
        binding.ivPreviewSignature.setImageBitmap(bitmap)
    }

    override fun initView() {
        setupTitleBar()
        binding.webView.setupForHtmlContent()
        binding.layoutSignatureArea.setOnClickListener {
            signatureLauncher.launch(Intent(this, SignatureActivity::class.java))
        }
        binding.btnResign.setOnClickListener { clearSignature() }
        binding.btnSubmit.setOnClickListener { submitContract() }
    }

    override fun initData() {
        contractId = intent.getIntExtra(EXTRA_CONTRACT_ID, 0)
        contractType = normalizeContractType(intent.getIntExtra(EXTRA_CONTRACT_TYPE, 1))
        contractName = intent.getStringExtra(EXTRA_CONTRACT_NAME).orEmpty()
        extraAddress = intent.getStringExtra(EXTRA_CONTRACT_ADDRESS).orEmpty()
        if (contractName.isNotBlank()) {
            binding.titleBar.tvTitle.text = contractName
        }
        loadContractData()
    }

    private fun setupTitleBar() {
        binding.titleBar.tvTitle.text = getString(R.string.contract_detail_title)
        binding.titleBar.tvTitle.setTextColor(getColor(R.color.black))
        binding.titleBar.tvBack.compoundDrawableTintList = ColorStateList.valueOf(getColor(R.color.black))
        binding.titleBar.tvBack.setOnClickListener { finish() }
        binding.titleBar.tvMenu.visibility = android.view.View.GONE
    }

    private fun loadContractData() {
        lifecycleScope.launch {
            binding.progressBar.isVisible = true

            loadContractDetail()
            loadContractTemplate()
            loadAuthInfo()

            binding.progressBar.isVisible = false
            updateUi()
        }
    }

    private suspend fun loadContractDetail() {
        if (contractId <= 0) {
            contractInfo = null
            return
        }

        val detailResponse = ContractRemote.callApiSilent { getContractDetail(contractId) }
        if (detailResponse.isSuccess()) {
            contractInfo = detailResponse.data.info
        } else {
            contractInfo = null
        }
    }

    private suspend fun loadContractTemplate() {
        if (contractType == 1) {
            val response = ContractRemote.callApiSilent { getContractTemplateOne() }
            if (response.isSuccess()) {
                templateOne = response.data.info
                templateTwo = null
            }
        } else {
            val response = ContractRemote.callApiSilent { getContractTemplateTwo() }
            if (response.isSuccess()) {
                templateTwo = response.data.info
                templateOne = null
            }
        }
    }

    private suspend fun loadAuthInfo() {
        val response = ContractRemote.callApiSilent { getAuthenticationDetail() }
        authInfo = if (response.isSuccess()) response.data?.detail else null
    }

    private fun updateUi() {
        val info = contractInfo
        val isSigned = info?.isSigned == true

        loadContractHtml(info, isSigned)

        if (isSigned) {
            binding.layoutUnsigned.isVisible = false
            binding.layoutSigned.isVisible = false
        } else {
            binding.layoutUnsigned.isVisible = true
            binding.layoutSigned.isVisible = false
        }
    }

    private fun loadContractHtml(info: ContractInfo?, isSigned: Boolean) {
        val html = buildContractHtml(info, isSigned)
        binding.webView.loadRawHtml(html, AppConfigCenter.baseDomain)
    }

    private fun buildContractHtml(
        info: ContractInfo?,
        isSigned: Boolean,
    ): String {
        val template1 = if (contractType == 1) templateOne else null
        val template2 = if (contractType == 2) templateTwo else null

        val logo = template1?.logo ?: template2?.logo ?: ""
        val rawJiaName = template1?.jiaName ?: template2?.jiaName ?: ""
        val companyTitle = template1?.companyTitle ?: template2?.companyTitle ?: ""
        val companyShortName = template1?.companyShortName ?: template2?.companyShortName ?: ""
        val jiaName = when {
            rawJiaName.isNotBlank() -> rawJiaName
            companyTitle.isNotBlank() -> companyTitle
            companyShortName.isNotBlank() -> companyShortName
            else -> ""
        }
        val jiaAddress = template1?.jiaAddress ?: template2?.jiaAddress ?: ""
        val jiaSign = template1?.jiaSign ?: template2?.jiaSign ?: ""
        val jiaZhang = template1?.jiaZhang ?: template2?.jiaZhang ?: ""
        val content = template1?.content ?: template2?.content ?: ""
        val title = template1?.title ?: template2?.title ?: contractName

        fun resolveTemplateImageUrl(path: String): String {
            val raw = path.trim()
            if (raw.isBlank()) return ""
            if (raw.startsWith("http://") || raw.startsWith("https://")) return raw
            val normalized = raw.trimStart('/')
            return if (normalized.startsWith("upload/")) {
                AppConfigCenter.baseDomain.trimEnd('/') + "/" + normalized
            } else {
                ImageUrlUtils.oss(raw)
            }
        }

        val logoUrl = resolveTemplateImageUrl(logo)
        val jiaZhangUrl = resolveTemplateImageUrl(jiaZhang)
        val jiaSignUrl = resolveTemplateImageUrl(jiaSign)
        val yiSignUrl = if (info != null) resolveTemplateImageUrl(info.signimage) else ""
        val signDate = info?.signDate.orEmpty()
        val authName = authInfo?.name.orEmpty()
        val authIdNumber = authInfo?.id_card.orEmpty()
        val yiName = when {
            info?.name?.isNotBlank() == true -> info.name
            authName.isNotBlank() -> authName
            else -> ""
        }
        val yiAddress = when {
            info?.address?.isNotBlank() == true -> info.address
            extraAddress.isNotBlank() -> extraAddress
            else -> ""
        }
        val yiIdNumber = when {
            info?.idnumber?.isNotBlank() == true -> info.idnumber
            authIdNumber.isNotBlank() -> authIdNumber
            else -> ""
        }

        fun buildImageTag(url: String, style: String): String {
            if (url.isBlank()) return ""
            return "<img src=\"$url\" style=\"$style\" onerror=\"this.style.display='none'\" />"
        }

        val logoHtml = if (logoUrl.isNotEmpty()) {
            """<div style="text-align:center;margin-bottom:16px;">${
                buildImageTag(
                    url = logoUrl,
                    style = "max-width:200px;height:auto;"
                )
            }</div>"""
        } else {
            ""
        }

        val baseInfoHtml = if (contractType == 2) "" else """
            <div class="base-info">
                <div><span class="label">甲方：</span>${if (jiaName.isNotBlank()) jiaName else "--"}</div>
                <div><span class="label">甲方地址：</span>${if (jiaAddress.isNotBlank()) jiaAddress else "--"}</div>
                <div><span class="label">乙方：</span>${if (yiName.isNotBlank()) yiName else "--"}</div>
                <div><span class="label">乙方地址：</span>${if (yiAddress.isNotBlank()) yiAddress else "--"}</div>
                <div><span class="label">身份证号：</span>${if (yiIdNumber.isNotBlank()) yiIdNumber else "--"}</div>
            </div>
        """.trimIndent()

        val signDateText = signDate.ifBlank { "--" }
        val signatureHtml = """
            <div class="sign-area">
                <div class="sign-row">
                    <div class="sign-col sign-col-left">
                        ${buildImageTag(
            url = jiaZhangUrl,
            style = "position:absolute;left:-6px;top:-8px;width:110px;height:110px;object-fit:contain;z-index:1;"
        )}
                        ${buildImageTag(
            url = jiaSignUrl,
            style = "position:absolute;left:70px;top:44px;width:140px;height:40px;object-fit:contain;z-index:2;"
        )}
                        <div class="sign-line">甲方：${if (jiaName.isNotBlank()) jiaName else "--"}</div>
                        <div class="sign-line">甲方代表(签字)</div>
                        <div class="sign-line">$signDateText</div>
                    </div>
                    <div class="sign-col sign-col-right">
                        <div class="sign-line">乙方：${if (yiName.isNotBlank()) yiName else "--"}</div>
                        <div class="sign-line">乙方代表(签字)</div>
                        ${if (isSigned && yiSignUrl.isNotEmpty()) "<img src=\"$yiSignUrl\" class=\"sign-user\" onerror=\"this.style.display='none'\" />" else ""}
                        <div class="sign-line">$signDateText</div>
                    </div>
                </div>
            </div>
        """.trimIndent()

        return """
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <style>
                    body {
                        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
                        font-size: 14px;
                        line-height: 1.8;
                        color: #333333;
                        padding: 16px;
                        margin: 0;
                        background: #FFFFFF;
                    }
                    h2 {
                        text-align: center;
                        margin: 0 0 20px 0;
                        color: #333333;
                    }
                    .base-info {
                        margin: 12px 0 18px;
                        padding: 10px 12px;
                        border: 1px solid #EEEEEE;
                        border-radius: 8px;
                        background: #FAFAFA;
                        color: #333333;
                        word-break: break-all;
                    }
                    .base-info div {
                        margin: 4px 0;
                    }
                    .base-info .label {
                        color: #666666;
                    }
                    .sign-area {
                        margin-top: 28px;
                    }
                    .sign-row {
                        display: flex;
                        gap: 48px;
                    }
                    .sign-col {
                        position: relative;
                        flex: 1;
                        min-height: 120px;
                        color: #000000;
                        font-size: 14px;
                    }
                    .sign-col-right {
                        padding-left: 8px;
                    }
                    .sign-line {
                        line-height: 24px;
                        height: 24px;
                        margin: 10px 0;
                        white-space: nowrap;
                    }
                    .sign-user {
                        position: absolute;
                        left: 70px;
                        top: 44px;
                        width: 140px;
                        height: 40px;
                        object-fit: contain;
                        z-index: 2;
                    }
                    img { max-width: 100%; }
                </style>
            </head>
            <body>
                $logoHtml
                <h2>${if (title.isNotBlank()) title else contractName}</h2>
                $baseInfoHtml
                <div>$content</div>
                $signatureHtml
            </body>
            </html>
        """.trimIndent()
    }

    private fun clearSignature() {
        signatureImagePath = null
        binding.tvSignatureHint.isVisible = true
        binding.ivPreviewSignature.isVisible = false
        binding.ivPreviewSignature.setImageBitmap(null)
    }

    private fun submitContract() {
        val localPath = signatureImagePath
        if (localPath.isNullOrBlank()) {
            AppToast.show(getString(R.string.signature_please_first))
            return
        }

        lifecycleScope.launch {
            binding.progressBar.isVisible = true

            val uploadedPath = UploadService.uploadFile(File(localPath))
            if (uploadedPath.isNullOrBlank()) {
                binding.progressBar.isVisible = false
                AppToast.show(getString(R.string.contract_upload_sign_failed))
                return@launch
            }

            val finalContractId = ensureContractId()
            if (finalContractId.isNullOrBlank()) {
                binding.progressBar.isVisible = false
                return@launch
            }

            val signResponse = ContractRemote.callApiSilent {
                signContract(SignContractRequest(id = finalContractId, img = uploadedPath))
            }

            binding.progressBar.isVisible = false
            if (signResponse.isSuccess()) {
                AppToast.show(getString(R.string.contract_sign_success))
                runCatching { File(localPath).delete() }
                setResult(Activity.RESULT_OK)
                finish()
            } else {
                AppToast.show(signResponse.failed.msg ?: getString(R.string.contract_sign_failed))
            }
        }
    }

    private suspend fun ensureContractId(): String? {
        val info = contractInfo
        if (info != null && info.id > 0) {
            return info.id.toString()
        }

        val finalAddress = when {
            extraAddress.isNotBlank() -> extraAddress
            !info?.address.isNullOrBlank() -> info?.address.orEmpty()
            else -> ""
        }

        val createResponse = ContractRemote.callApiSilent {
            createContract(
                CreateContractRequest(
                    type = normalizeContractType(contractType),
                    address = finalAddress,
                    name = info?.name.orEmpty(),
                    idnumber = info?.idnumber.orEmpty(),
                )
            )
        }
        if (!createResponse.isSuccess()) {
            AppToast.show(createResponse.failed.msg ?: getString(R.string.contract_create_failed))
            return null
        }
        val createdId = createResponse.data.contract_id.ifBlank { createResponse.data.id }
        if (createdId.isBlank()) {
            AppToast.show(getString(R.string.contract_invalid_id))
            return null
        }
        return createdId
    }

    private fun normalizeContractType(type: Int): Int {
        return if (type == 1 || type == 2) type else 1
    }
}
