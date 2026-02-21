//
//  Contract.swift
//  zhengqaun
//
//  Created by admin on 2026/1/6.
//

import Foundation

/// 合同状态
enum ContractStatus {
    case signed      // 已签
    case unsigned    // 未签（签订）
}

/// 合同模型
struct Contract {
    let id: String
    let name: String
    let status: ContractStatus
    let content: String
    let partyA: String
    let partyAAddress: String
    let partyB: String
    let partyBAddress: String
    let partyBIdCard: String
    let signDate: Date?
    
    static func mockContracts() -> [Contract] {
        return [
            Contract(
                id: "1",
                name: "证券投资顾问咨询服务协议",
                status: .signed,
                content: getContractContent(),
                partyA: "华泰证券股份有限公司",
                partyAAddress: "江苏省南京市江东中路228号",
                partyB: "测试",
                partyBAddress: "包宝宝",
                partyBIdCard: "420521198402154410",
                signDate: Date()
            ),
            Contract(
                id: "2",
                name: "证券投资顾问咨询服务协议",
                status: .unsigned,
                content: getContractContent(),
                partyA: "华泰证券股份有限公司",
                partyAAddress: "江苏省南京市江东中路228号",
                partyB: "测试",
                partyBAddress: "包宝宝",
                partyBIdCard: "420521198402154410",
                signDate: nil
            )
        ]
    }
    
    private static func getContractContent() -> String {
        return """
        甲方:华泰证券股份有限公司
        地址:江苏省南京市江东中路228号
        
        乙方:测试
        地址:包宝宝
        身份证号:420521198402154410
        
        根据《中华人民共和国证券法》、《证券投资顾问业务暂行规定》等有关法律、法规、规章的规定,甲、乙双方本着平等、自愿,诚实信用的原则,就甲方向乙方提供证券投资咨询服务事项,签订本协议。
        
        第一章:双方申明
        
        第一条、甲方系中国证监会核准的证券投资咨询专业机构,具备提供分成制证券投资咨询服务的必要条件和专业能力。
        
        第二条、甲、乙双方共同遵守有关的法律、法规,不得利用本协议的关系从事任何违法、违规行为。
        
        第二章:服务内容及方式
        
        第三条、甲方根据乙方的需求,为乙方提供证券投资咨询服务,包括但不限于:
        (一)提供投资建议和策略;
        (二)提供市场分析和研究报告;
        (三)提供投资组合管理建议;
        (四)其他双方约定的服务内容。
        
        第四条、甲方通过以下方式向乙方提供服务:
        (一)线上平台提供咨询服务;
        (二)电话、邮件等方式进行沟通;
        (三)其他双方约定的服务方式。
        
        第三章:服务费用
        
        第五条、乙方应按照本协议约定向甲方支付服务费用。具体费用标准和支付方式由双方另行约定。
        
        第四章:双方权利义务
        
        第六条、甲方的权利和义务:
        (一)按照本协议约定向乙方提供咨询服务;
        (二)保证提供的信息和建议的真实性、准确性;
        (三)保守乙方的商业秘密;
        (四)其他约定的权利义务。
        
        第七条、乙方的权利和义务:
        (一)按照本协议约定支付服务费用;
        (二)提供真实、准确的信息;
        (三)按照甲方的建议进行投资决策;
        (四)其他约定的权利义务。
        
        第五章:违约责任
        
        第八条、任何一方违反本协议约定的,应承担相应的违约责任。
        
        第六章:其他
        
        第九条、本协议自双方签字盖章之日起生效。
        
        第十条、本协议未尽事宜,由双方协商解决。
        """
    }

}


