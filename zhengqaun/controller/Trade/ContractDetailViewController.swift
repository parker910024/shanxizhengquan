//
//  ContractDetailViewController.swift
//  zhengqaun
//
//  Created by admin on 2026/1/6.
//

import SVProgressHUD
import UIKit

class ContractDetailViewController: ZQViewController {
    var contract: Contract?
    private var signatureImage: UIImage?
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let companyNameLabel = UILabel()
    private let agreementTitleLabel = UILabel()
    private let contentLabel = UILabel()
    private let signatureContainer = UIView()
    private let signatureImageView = UIImageView()
    private let signaturePlaceholderLabel = UILabel()
    private let submitButton = UIButton(type: .system)
    private var scrollViewBottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        loadData()
    }
    
    private func setupNavigationBar() {
        gk_navTitle = "合同详情"
        gk_navBackgroundColor = UIColor(red: 25/255, green: 118/255, blue: 210/255, alpha: 1.0) // #1976D2
        gk_navTitleColor = .white
        gk_statusBarStyle = .lightContent
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // Logo - 创建一个简单的logo视图
        let logoContainer = UIView()
        logoContainer.backgroundColor = .white
        contentView.addSubview(logoContainer)
        logoContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Logo文字
        let logoTextLabel = UILabel()
        logoTextLabel.text = contract?.title
        logoTextLabel.font = UIFont.boldSystemFont(ofSize: 24)
        logoTextLabel.textColor = UIColor(red: 0.1, green: 0.47, blue: 0.82, alpha: 1.0)
        logoContainer.addSubview(logoTextLabel)
        logoTextLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let logoSubLabel = UILabel()
        logoSubLabel.text = ""
        logoSubLabel.font = UIFont.systemFont(ofSize: 12)
        logoSubLabel.textColor = Constants.Color.textSecondary
        logoContainer.addSubview(logoSubLabel)
        logoSubLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            logoContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            logoContainer.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            logoContainer.widthAnchor.constraint(equalToConstant: 200),
            logoContainer.heightAnchor.constraint(equalToConstant: 60),
            
            logoTextLabel.topAnchor.constraint(equalTo: logoContainer.topAnchor),
            logoTextLabel.centerXAnchor.constraint(equalTo: logoContainer.centerXAnchor),
            
            logoSubLabel.topAnchor.constraint(equalTo: logoTextLabel.bottomAnchor, constant: 4),
            logoSubLabel.centerXAnchor.constraint(equalTo: logoContainer.centerXAnchor)
        ])
        
        // 公司名称
        companyNameLabel.text = contract?.partyA
        companyNameLabel.font = UIFont.boldSystemFont(ofSize: 20)
        companyNameLabel.textColor = Constants.Color.textPrimary
        companyNameLabel.textAlignment = .center
        contentView.addSubview(companyNameLabel)
        companyNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 协议标题
        agreementTitleLabel.text = contract?.name
        agreementTitleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        agreementTitleLabel.textColor = Constants.Color.stockRise // 红色
        agreementTitleLabel.textAlignment = .center
        contentView.addSubview(agreementTitleLabel)
        agreementTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 合同内容
        contentLabel.font = UIFont.systemFont(ofSize: 15)
        contentLabel.textColor = Constants.Color.textPrimary
        contentLabel.numberOfLines = 0
        contentView.addSubview(contentLabel)
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        
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
        
        // scrollView的底部约束会根据是否有按钮动态调整
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
            
            companyNameLabel.topAnchor.constraint(equalTo: logoContainer.bottomAnchor, constant: 16),
            companyNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            companyNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            agreementTitleLabel.topAnchor.constraint(equalTo: companyNameLabel.bottomAnchor, constant: 12),
            agreementTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            agreementTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            contentLabel.topAnchor.constraint(equalTo: agreementTitleLabel.bottomAnchor, constant: 24),
            contentLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            signatureContainer.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 24),
            signatureContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            signatureContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            signatureContainer.heightAnchor.constraint(equalToConstant: 200),
            
            signatureImageView.topAnchor.constraint(equalTo: signatureContainer.topAnchor, constant: 8),
            signatureImageView.leadingAnchor.constraint(equalTo: signatureContainer.leadingAnchor, constant: 8),
            signatureImageView.trailingAnchor.constraint(equalTo: signatureContainer.trailingAnchor, constant: -8),
            signatureImageView.bottomAnchor.constraint(equalTo: signatureContainer.bottomAnchor, constant: -8),
            
            signaturePlaceholderLabel.centerXAnchor.constraint(equalTo: signatureContainer.centerXAnchor),
            signaturePlaceholderLabel.centerYAnchor.constraint(equalTo: signatureContainer.centerYAnchor),
            
            // 提交按钮：始终居中，左右间距20
            submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            submitButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            submitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            submitButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            submitButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // 设置内容底部约束
        let bottomConstraint = signatureContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        bottomConstraint.priority = .required
        bottomConstraint.isActive = true
    }
    
    private func loadData() {
        guard let contract = contract else { return }
        
        // 设置合同内容
        var content = contract.content
        content = content.replacingOccurrences(of: "甲方:", with: "甲方: \(contract.partyA)")
        content = content.replacingOccurrences(of: "地址:江苏省南京市江东中路228号", with: "地址: \(contract.partyAAddress)")
        content = content.replacingOccurrences(of: "乙方:测试", with: "乙方: \(contract.partyB)")
        content = content.replacingOccurrences(of: "地址:包宝宝", with: "地址: \(contract.partyBAddress)")
        content = content.replacingOccurrences(of: "身份证号:420521198402154410", with: "身份证号: \(contract.partyBIdCard)")
        
        contentLabel.attributedText = htmlToAttributedString(content)
        
        // 如果已签名，显示签名图片，不允许重新签名
        if contract.status == .signed {
            signaturePlaceholderLabel.isHidden = true
            signatureImageView.isHidden = false
            submitButton.isHidden = true // 已签名不需要提交按钮
            
            // 禁用签名区域的点击
            signatureContainer.isUserInteractionEnabled = false
            
            // 调整scrollView底部约束到底部
            scrollViewBottomConstraint.isActive = false
            scrollViewBottomConstraint = scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            scrollViewBottomConstraint.isActive = true
            
            guard let url = URL(string: contract.signImage) else { return }
            URLSession.shared.dataTask(with: url) { data, _, _ in
                guard let data = data, let img = UIImage(data: data) else { return }
                DispatchQueue.main.async { [unowned self] in
                    self.signatureImageView.image = img
                }
            }.resume()
        } else {
            // 未签名状态
            signaturePlaceholderLabel.isHidden = false
            signatureImageView.isHidden = true
            submitButton.isHidden = false // 未签名显示提交按钮
            
            // 启用签名区域的点击
            signatureContainer.isUserInteractionEnabled = true
            
            // 调整scrollView底部约束到按钮上方
            scrollViewBottomConstraint.isActive = false
            scrollViewBottomConstraint = scrollView.bottomAnchor.constraint(equalTo: submitButton.topAnchor, constant: -20)
            scrollViewBottomConstraint.isActive = true
        }
    }
    
    @objc private func signatureTapped() {
        // 检查合同状态，已签名不允许重新签名
        guard let contract = contract, contract.status != .signed else {
            return
        }
        
        let vc = SignatureViewController()
        vc.modalPresentationStyle = .fullScreen
        // 不传递任何签名作为背景，让用户从空白开始签名
        // 这样可以确保清除按钮能清除所有内容
        vc.existingSignature = nil
        
        // 清除未提交的签名数据（如果有的话）
        signatureImage = nil
        signatureImageView.image = nil
        
        // 清除UserDefaults中未提交的签名数据（如果之前测试时保存过）
        UserDefaults.standard.removeObject(forKey: "contract_signature_\(contract.id)")
        
        vc.onSignatureComplete = { [weak self] image in
            guard let self = self, let _ = self.contract else { return }
            self.signatureImage = image
            self.signatureImageView.image = image
            self.signatureImageView.isHidden = false
            self.signaturePlaceholderLabel.isHidden = true
            self.submitButton.isHidden = false // 确保提交按钮显示
            
            // 注意：这里不保存到UserDefaults，只有点击确认提交后才保存
        }
        present(vc, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 确保是竖屏
        restorePortraitIfNeeded()
    }
    
    private func restorePortraitIfNeeded() {
        // 检查当前方向，如果不是竖屏则恢复
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
        // 保存签名图片到UserDefaults（只有确认提交后才保存）
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
    
    private func htmlToAttributedString(_ html: String) -> NSAttributedString? {
        // 清理HTML，移除script和style标签
        var cleanHTML = html
        cleanHTML = cleanHTML.replacingOccurrences(of: "<script[^>]*>.*?</script>", with: "", options: [.regularExpression, .caseInsensitive])
        cleanHTML = cleanHTML.replacingOccurrences(of: "<style[^>]*>.*?</style>", with: "", options: [.regularExpression, .caseInsensitive])
        
        // 添加基础CSS样式
        let cssStyle = """
        <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            font-size: 16px;
            line-height: 1.6;
            color: #1C1C1C;
        }
        p {
            margin: 0 0 12px 0;
        }
        strong {
            font-weight: bold;
        }
        </style>
        """
        
        let htmlWithStyle = cssStyle + cleanHTML
        
        // 使用NSAttributedString的HTML初始化方法
        guard let data = htmlWithStyle.data(using: .utf8) else {
            return nil
        }
        
        do {
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ]
            
            let attributedString = try NSAttributedString(
                data: data,
                options: options,
                documentAttributes: nil
            )
            
            // 创建可变属性字符串，以便进一步自定义样式
            let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
            
            // 设置段落样式
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 4
            paragraphStyle.paragraphSpacing = 8
            
            mutableAttributedString.addAttribute(
                .paragraphStyle,
                value: paragraphStyle,
                range: NSRange(location: 0, length: mutableAttributedString.length)
            )
            
            return mutableAttributedString
        } catch {
            print("HTML解析错误: \(error)")
            return nil
        }
    }
}
