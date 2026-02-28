//
//  ContractDetailViewController.swift
//  zhengqaun
//
//  合同详情 - 对齐安卓 ContractDetailActivity
//

import SVProgressHUD
import UIKit
import WebKit

class ContractDetailViewController: ZQViewController {
    var contract: Contract?
    var contractType: Int = 1  // 对齐安卓：1=服务协议 2=保密协议（type==2 时隐藏甲乙方信息）
    private var signatureImage: UIImage?
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // 使用 WKWebView 替代 UILabel 来渲染 HTML 内容（对齐安卓 WebView）
    private let webView = WKWebView()
    private var webViewHeightConstraint: NSLayoutConstraint!
    
    // 签名区域
    private let signatureContainer = UIView()
    private let signatureImageView = UIImageView()
    private let signaturePlaceholderLabel = UILabel()
    private let submitButton = UIButton(type: .system)
    private var scrollViewBottomConstraint: NSLayoutConstraint!
    
    // 模板数据（对齐安卓：从 getContractTemplateOne/Two 加载甲方信息）
    private var templateData: [String: Any] = [:]
    // 认证信息（对齐安卓：从 authenticationDetail 加载乙方信息）
    private var authData: [String: Any] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        loadAllData()
    }
    
    private func setupNavigationBar() {
        gk_navTitle = contract?.name ?? "合同详情"
        gk_navBackgroundColor = .white
        gk_navTitleColor = Constants.Color.textPrimary
        gk_statusBarStyle = .default
        gk_backStyle = .black
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // WebView 用于渲染合同 HTML 内容
        webView.navigationDelegate = self
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .white
        contentView.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webViewHeightConstraint = webView.heightAnchor.constraint(equalToConstant: 300)
        
        // 签名区域
        signatureContainer.backgroundColor = .white
        signatureContainer.layer.borderWidth = 1
        signatureContainer.layer.borderColor = Constants.Color.separator.cgColor
        signatureContainer.layer.cornerRadius = 4
        contentView.addSubview(signatureContainer)
        signatureContainer.translatesAutoresizingMaskIntoConstraints = false
        
        signatureImageView.contentMode = .scaleAspectFit
        signatureImageView.isHidden = true
        signatureContainer.addSubview(signatureImageView)
        signatureImageView.translatesAutoresizingMaskIntoConstraints = false
        
        signaturePlaceholderLabel.text = "点击进行横屏签字"
        signaturePlaceholderLabel.font = UIFont.systemFont(ofSize: 14)
        signaturePlaceholderLabel.textColor = Constants.Color.textSecondary
        signaturePlaceholderLabel.textAlignment = .center
        signatureContainer.addSubview(signaturePlaceholderLabel)
        signaturePlaceholderLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let signatureTap = UITapGestureRecognizer(target: self, action: #selector(signatureTapped))
        signatureContainer.addGestureRecognizer(signatureTap)
        signatureContainer.isUserInteractionEnabled = true
        
        // 确认提交按钮
        submitButton.setTitle("确认提交", for: .normal)
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        submitButton.backgroundColor = UIColor(red: 0.1, green: 0.47, blue: 0.82, alpha: 1.0)
        submitButton.layer.cornerRadius = 8
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        view.addSubview(submitButton)
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        
        scrollViewBottomConstraint = scrollView.bottomAnchor.constraint(equalTo: submitButton.topAnchor, constant: -20)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.Navigation.totalNavigationHeight),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollViewBottomConstraint,
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            webView.topAnchor.constraint(equalTo: contentView.topAnchor),
            webView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            webViewHeightConstraint,
            
            signatureContainer.topAnchor.constraint(equalTo: webView.bottomAnchor, constant: 16),
            signatureContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            signatureContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            signatureContainer.heightAnchor.constraint(equalToConstant: 200),
            signatureContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            signatureImageView.topAnchor.constraint(equalTo: signatureContainer.topAnchor, constant: 8),
            signatureImageView.leadingAnchor.constraint(equalTo: signatureContainer.leadingAnchor, constant: 8),
            signatureImageView.trailingAnchor.constraint(equalTo: signatureContainer.trailingAnchor, constant: -8),
            signatureImageView.bottomAnchor.constraint(equalTo: signatureContainer.bottomAnchor, constant: -8),
            
            signaturePlaceholderLabel.centerXAnchor.constraint(equalTo: signatureContainer.centerXAnchor),
            signaturePlaceholderLabel.centerYAnchor.constraint(equalTo: signatureContainer.centerYAnchor),
            
            submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            submitButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            submitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            submitButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            submitButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // MARK: - 加载所有数据（对齐安卓：loadContractDetail + loadContractTemplate + loadAuthInfo）
    
    private func loadAllData() {
        guard let contract = contract else { return }
        
        SVProgressHUD.show()
        let group = DispatchGroup()
        
        // 1. 加载合同模板（甲方信息）
        let contractType = contract.id  // 用 contract 中传入的 type
        group.enter()
        loadTemplate(type: 1) { [weak self] in
            self?.loadTemplate(type: 2) {
                group.leave()
            }
        }
        
        // 2. 加载认证信息（乙方信息）
        group.enter()
        SecureNetworkManager.shared.request(
            api: Api.authenticationDetail_api,
            method: .get,
            params: ["page": 1, "size": 10]
        ) { [weak self] result in
            if case .success(let res) = result,
               let dict = res.decrypted,
               let data = dict["data"] as? [String: Any],
               let detail = data["detail"] as? [String: Any] {
                self?.authData = detail
            }
            group.leave()
        }
        
        group.notify(queue: .main) { [weak self] in
            SVProgressHUD.dismiss()
            self?.renderContract()
        }
    }
    
    private func loadTemplate(type: Int, completion: @escaping () -> Void) {
        let api = type == 1 ? "/api/stock/one" : "/api/stock/two"
        SecureNetworkManager.shared.request(
            api: api,
            method: .get,
            params: [:]
        ) { [weak self] result in
            if case .success(let res) = result,
               let dict = res.decrypted,
               let data = dict["data"] as? [String: Any],
               let info = data["info"] as? [String: Any] {
                // 只有当模板数据为空时才赋值（优先用 type 1）
                if self?.templateData.isEmpty == true {
                    self?.templateData = info
                }
            }
            completion()
        }
    }
    
    // MARK: - 渲染合同（对齐安卓 buildContractHtml）
    
    private func renderContract() {
        guard let contract = contract else { return }
        
        let isSigned = contract.status == .signed
        
        // 对齐安卓：已签订隐藏签名面板和提交按钮
        if isSigned {
            signatureContainer.isHidden = true
            submitButton.isHidden = true
            signatureContainer.heightAnchor.constraint(equalToConstant: 0).isActive = true
            
            // 调整 scrollView 底部到安全区
            scrollViewBottomConstraint.isActive = false
            scrollViewBottomConstraint = scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            scrollViewBottomConstraint.isActive = true
        } else {
            signatureContainer.isHidden = false
            submitButton.isHidden = false
            signaturePlaceholderLabel.isHidden = false
            signatureImageView.isHidden = true
            signatureContainer.isUserInteractionEnabled = true
        }
        
        // 构建 HTML（对齐安卓 buildContractHtml）
        let html = buildContractHtml(contract: contract, isSigned: isSigned)
        webView.loadHTMLString(html, baseURL: nil)
    }
    
    private func buildContractHtml(contract: Contract, isSigned: Bool) -> String {
        // 甲方信息（来自模板）
        let jiaName = templateData["jia_name"] as? String
            ?? templateData["company_title"] as? String
            ?? templateData["company_short_name"] as? String
            ?? contract.partyA
        let jiaAddress = templateData["jia_address"] as? String ?? contract.partyAAddress
        let jiaSign = templateData["jia_sign"] as? String ?? ""
        let jiaZhang = templateData["jia_zhang"] as? String ?? ""
        let logo = templateData["logo"] as? String ?? ""
        let templateTitle = templateData["title"] as? String ?? contract.name
        let templateContent = templateData["content"] as? String ?? contract.content
        
        // 解析图片 URL
        func resolveTemplateImageUrl(_ path: String) -> String {
            let raw = path.trimmingCharacters(in: .whitespacesAndNewlines)
            if raw.isEmpty { return "" }
            if raw.hasPrefix("http://") || raw.hasPrefix("https://") { return raw }
            var normalized = raw
            if normalized.hasPrefix("/") { normalized.removeFirst() }
            var base = vpnDataModel.shared.selectAddress ?? ""
            if base.hasSuffix("/") { base.removeLast() }
            return base + "/" + normalized
        }
        
        let logoUrl = resolveTemplateImageUrl(logo)
        let jiaZhangUrl = resolveTemplateImageUrl(jiaZhang)
        let jiaSignUrl = resolveTemplateImageUrl(jiaSign)
        
        let logoHtml = logoUrl.isEmpty ? "" : "<div style=\"text-align:center;margin-bottom:16px;\"><img src=\"\(logoUrl)\" style=\"max-width:200px;height:auto;\" onerror=\"this.style.display='none'\" /></div>"
        
        // 乙方信息（来自合同详情或认证信息）
        let yiName = contract.partyB.isEmpty
            ? (authData["name"] as? String ?? "")
            : contract.partyB
        let yiAddress = contract.partyBAddress.isEmpty
            ? ""
            : contract.partyBAddress
        let yiIdNumber = contract.partyBIdCard.isEmpty
            ? (authData["id_card"] as? String ?? "")
            : contract.partyBIdCard
        
        let signDate = contract.signDate != nil
            ? DateFormatter.localizedString(from: contract.signDate!, dateStyle: .medium, timeStyle: .none)
            : "--"
        
        // 签名图 URL
        let yiSignUrl = isSigned ? contract.signImage : ""
        let processedYiSignUrl = yiSignUrl.isEmpty ? "" : resolveTemplateImageUrl(yiSignUrl)
        
        // 构建甲乙方信息 HTML（对齐安卓 baseInfoHtml）
        // 对齐安卓：contractType == 2（保密协议书）时不显示甲乙方信息
        let baseInfoHtml: String
        if contractType == 2 {
            baseInfoHtml = ""
        } else {
            baseInfoHtml = """
            <div class="base-info">
                <div><span class="label">甲方：</span>\(jiaName.isEmpty ? "--" : jiaName)</div>
                <div><span class="label">甲方地址：</span>\(jiaAddress.isEmpty ? "--" : jiaAddress)</div>
                <div><span class="label">乙方：</span>\(yiName.isEmpty ? "--" : yiName)</div>
                <div><span class="label">乙方地址：</span>\(yiAddress.isEmpty ? "--" : yiAddress)</div>
                <div><span class="label">身份证号：</span>\(yiIdNumber.isEmpty ? "--" : yiIdNumber)</div>
            </div>
            """
        }
        
        // 构建签名区 HTML（对齐安卓 signatureHtml，添加甲方章和签名）
        let jiaZhangImg = jiaZhangUrl.isEmpty ? "" : "<img src=\"\(jiaZhangUrl)\" style=\"position:absolute;left:-6px;top:-8px;width:110px;height:110px;object-fit:contain;z-index:1;\" onerror=\"this.style.display='none'\" />"
        let jiaSignImg = jiaSignUrl.isEmpty ? "" : "<img src=\"\(jiaSignUrl)\" style=\"position:absolute;left:70px;top:44px;width:140px;height:40px;object-fit:contain;z-index:2;\" onerror=\"this.style.display='none'\" />"
        
        let signatureHtml = """
        <div class="sign-area">
            <div class="sign-row">
                <div class="sign-col sign-col-left">
                    \(jiaZhangImg)
                    \(jiaSignImg)
                    <div class="sign-line">甲方：\(jiaName.isEmpty ? "--" : jiaName)</div>
                    <div class="sign-line">甲方代表(签字)</div>
                    <div class="sign-line">\(signDate)</div>
                </div>
                <div class="sign-col sign-col-right">
                    <div class="sign-line">乙方：\(yiName.isEmpty ? "--" : yiName)</div>
                    <div class="sign-line">乙方代表(签字)</div>
                    \(isSigned && !processedYiSignUrl.isEmpty ? "<img src=\"\(processedYiSignUrl)\" class=\"sign-user\" onerror=\"this.style.display='none'\" />" : "")
                    <div class="sign-line">\(signDate)</div>
                </div>
            </div>
        </div>
        """
        
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
                .base-info div { margin: 4px 0; }
                .base-info .label { color: #666666; }
                .sign-area { margin-top: 28px; }
                .sign-row { display: flex; gap: 48px; }
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
            \(logoHtml)
            <h2>\(templateTitle)</h2>
            \(baseInfoHtml)
            <div>\(templateContent)</div>
            \(signatureHtml)
        </body>
        </html>
        """
    }
    
    // MARK: - 签名交互
    
    @objc private func signatureTapped() {
        guard let contract = contract, contract.status != .signed else { return }
        
        let vc = SignatureViewController()
        vc.modalPresentationStyle = .fullScreen
        vc.existingSignature = nil
        
        signatureImage = nil
        signatureImageView.image = nil
        
        UserDefaults.standard.removeObject(forKey: "contract_signature_\(contract.id)")
        
        vc.onSignatureComplete = { [weak self] image in
            guard let self = self else { return }
            self.signatureImage = image
            self.signatureImageView.image = image
            self.signatureImageView.isHidden = false
            self.signaturePlaceholderLabel.isHidden = true
            self.submitButton.isHidden = false
        }
        present(vc, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        restorePortraitIfNeeded()
    }
    
    private func restorePortraitIfNeeded() {
        let currentOrientation = UIApplication.shared.statusBarOrientation
        if currentOrientation != .portrait, currentOrientation != .unknown {
            if #available(iOS 16.0, *) {
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
                let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .portrait)
                windowScene.requestGeometryUpdate(geometryPreferences) { _ in
                    DispatchQueue.main.async {
                        UIViewController.attemptRotationToDeviceOrientation()
                    }
                }
            } else {
                UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    UIViewController.attemptRotationToDeviceOrientation()
                }
            }
        }
    }
    
    @objc private func submitTapped() {
        guard let signatureImage = signatureImage, let contract = contract else {
            Toast.show("请先进行签名")
            return
        }
        
        let alert = UIAlertController(title: "确认提交", message: "确定要提交合同吗？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak self] _ in
            self?.performSubmit(signatureImage: signatureImage, contract: contract)
        })
        present(alert, animated: true)
    }
    
    private func performSubmit(signatureImage: UIImage, contract: Contract) {
        if let imageData = signatureImage.pngData() {
            UserDefaults.standard.set(imageData, forKey: "contract_signature_\(contract.id)")
        }
        
        Task {
            do {
                SVProgressHUD.show()
                if let path = await SecureNetworkManager.shared.upload(image: signatureImage) {
                    let result = try await SecureNetworkManager.shared.request(api: Api.dosignContract_api, method: .post, params: ["id": "\(contract.id)", "img": path])
                    await SVProgressHUD.dismiss()
                    let dict = result.decrypted
                    if dict?["code"] as? NSNumber != 1 {
                        DispatchQueue.main.async {
                            Toast.showInfo(dict?["msg"] as? String ?? "")
                        }
                        return
                    }
                    Toast.show("合同提交成功")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                        self?.navigationController?.popViewController(animated: true)
                    }
                } else {
                    await SVProgressHUD.dismiss()
                }
            } catch {
                await SVProgressHUD.dismiss()
                debugPrint("error =", error.localizedDescription, #function)
                Toast.showError(error.localizedDescription)
            }
        }
    }
}

// MARK: - WKNavigationDelegate（自动调整 WebView 高度）
extension ContractDetailViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("document.body.scrollHeight") { [weak self] result, _ in
            guard let self = self, let height = result as? CGFloat else { return }
            self.webViewHeightConstraint.constant = height + 20
            self.view.layoutIfNeeded()
        }
    }
}
