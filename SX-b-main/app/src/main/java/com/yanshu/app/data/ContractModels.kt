package com.yanshu.app.data

import com.google.gson.annotations.SerializedName

data class ContractItem(
    val id: Int = 0,
    val link: String = "",
    val name: String = "",
    val status: Int = 0,
    val type: Int = 0,
) {
    // Align with H5 contracts page: status == 1 means signed.
    val isSigned: Boolean
        get() = status == 1
}

data class ContractDetailData(
    val info: ContractInfo = ContractInfo(),
)

data class ContractInfo(
    val id: Int = 0,
    val user_id: Int = 0,
    val name: String = "",
    val idnumber: String = "",
    val address: String = "",
    val tgdata: String = "1",
    val typedata: String = "1",
    val signimage: String = "",
    val signDate: String = "",
    val signtime: Long = 0,
    val createtime: Long = 0,
    val currenttime: Long = 0,
) {
    val isSigned: Boolean
        get() = tgdata == "2"
}

data class CreateContractData(
    val contract_id: String = "",
    val id: String = "",
)

data class ContractTemplateOneData(
    val info: ContractTemplateOne = ContractTemplateOne(),
)

data class ContractTemplateTwoData(
    val info: ContractTemplateTwo = ContractTemplateTwo(),
)

data class ContractTemplateOne(
    @SerializedName("Content")
    val content: String = "",
    @SerializedName("SubTitle")
    val title: String = "",
    @SerializedName("Bottom")
    val bottom: String = "",
    @SerializedName("Title")
    val companyTitle: String = "",
    @SerializedName("name")
    val companyShortName: String = "",
    @SerializedName("JiaName")
    val jiaName: String = "",
    @SerializedName("JiaAddress")
    val jiaAddress: String = "",
    @SerializedName("JiaSign")
    val jiaSign: String = "",
    @SerializedName("Pic")
    val jiaZhang: String = "",
    @SerializedName("logo")
    val logo: String = "",
)

data class ContractTemplateTwo(
    @SerializedName("Content")
    val content: String = "",
    @SerializedName("SubTitle")
    val title: String = "",
    @SerializedName("Bottom")
    val bottom: String = "",
    @SerializedName("Title")
    val companyTitle: String = "",
    @SerializedName("name")
    val companyShortName: String = "",
    @SerializedName("JiaName")
    val jiaName: String = "",
    @SerializedName("JiaAddress")
    val jiaAddress: String = "",
    @SerializedName("JiaSign")
    val jiaSign: String = "",
    @SerializedName("Pic")
    val jiaZhang: String = "",
    @SerializedName("logo")
    val logo: String = "",
)

data class UploadFileData(
    val path: String = "",
)
