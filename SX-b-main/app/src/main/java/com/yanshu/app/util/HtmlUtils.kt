package com.yanshu.app.util

import com.yanshu.app.data.ContractInfo

object HtmlUtils {

    fun buildContractHtml(
        contractTitle: String,
        companyName: String,
        companyAddress: String,
        logoUrl: String,
        contentHtml: String,
        info: ContractInfo?,
    ): String {
        val yName = info?.name.orEmpty()
        val yAddress = info?.address.orEmpty()
        val yIdNo = info?.idnumber.orEmpty()

        val logoBlock = if (logoUrl.isNotBlank()) {
            """
            <div class="logo-wrap">
              <img class="logo" src="$logoUrl" alt="logo" />
            </div>
            """.trimIndent()
        } else {
            ""
        }

        val baseInfo = """
            <h2 class="company-title">$companyName</h2>
            <h3 class="contract-title">$contractTitle</h3>
            <div class="base-info">
              <p><strong>甲方：</strong>${companyName.ifBlank { "-" }}</p>
              <p><strong>地址：</strong>${companyAddress.ifBlank { "-" }}</p>
              <p><strong>乙方：</strong>${yName.ifBlank { "-" }}</p>
              <p><strong>地址：</strong>${yAddress.ifBlank { "-" }}</p>
              <p><strong>身份证号：</strong>${yIdNo.ifBlank { "-" }}</p>
            </div>
        """.trimIndent()

        return """
            <!DOCTYPE html>
            <html>
            <head>
              <meta charset="UTF-8" />
              <meta name="viewport" content="width=device-width, initial-scale=1.0" />
              <style>
                body {
                  margin: 0;
                  padding: 12px 16px 24px;
                  color: #2f2f2f;
                  font-size: 17px;
                  line-height: 1.7;
                  background: #f7f7f7;
                  word-break: break-word;
                  font-family: "Noto Sans SC", sans-serif;
                }
                .logo-wrap {
                  text-align: center;
                  background: #ffffff;
                  margin: -12px -16px 8px;
                  padding: 12px 0 8px;
                  border-bottom: 1px solid #ececec;
                }
                .logo {
                  max-width: 72%;
                  height: auto;
                }
                .company-title {
                  margin: 6px 0 2px;
                  text-align: center;
                  color: #333333;
                  font-size: 22px;
                  font-weight: 700;
                }
                .contract-title {
                  margin: 0 0 16px;
                  text-align: center;
                  color: #e85a4f;
                  font-size: 18px;
                  font-weight: 600;
                }
                .base-info p {
                  margin: 2px 0;
                  color: #3a3a3a;
                }
                img {
                  max-width: 100%;
                  height: auto;
                }
              </style>
            </head>
            <body>
              $logoBlock
              $baseInfo
              <div class="content">$contentHtml</div>
            </body>
            </html>
        """.trimIndent()
    }
}
