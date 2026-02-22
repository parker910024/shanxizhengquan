//
//  LoginViewController.swift
//  zhengqaun
//
//  Created by admin on 2026/1/6.
//

import UIKit
import SafariServices

class LoginViewController: UIViewController {
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let headerView = UIView()
    private let logoImageView = UIImageView()
    
    /// true = 手机号登录，false = 用户名登录；由外部在 present 前设置，与注册页 isPhoneRegistration 一致
    var isPhoneLogin: Bool = true {
        didSet { updateAccountRowForMode() }
    }
    
    // 登录表单
    private let loginAccountLabel = UILabel()
    private let loginAccountTextField = UITextField()
    private let loginPasswordLabel = UILabel()
    private let loginPasswordTextField = UITextField()
    
    // 协议
    private let agreementCheckbox = UIButton(type: .custom)
    private let agreementLabel = UILabel()
    
    // 登录按钮、马上开户按钮
    private let loginButton = UIButton(type: .system)
    private let openAccountButton = UIButton(type: .system)
    
    // 密码可见性切换
    private let passwordVisibilityButton = UIButton(type: .custom)
    
    // 主题红（参考图主色）
    private let themeRed = UIColor(red: 230/255, green: 0, blue: 18/255, alpha: 1.0)
    
    // 表单容器引用
    private var loginFormContainer: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        // 设置滚动视图
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // 确保scrollView可以滚动
        scrollView.isScrollEnabled = true
        scrollView.alwaysBounceVertical = true
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        
        setupHeader()
        setupLoginForm()
        setupAgreement()
        setupLoginButton()
    }
    
    // MARK: - Header（白底 + 居中 Logo 图片）
    private func setupHeader() {
        contentView.addSubview(headerView)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.backgroundColor = .white
        
        logoImageView.image = UIImage(named: "logoIcon")
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.clipsToBounds = false
        headerView.addSubview(logoImageView)
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 162),
            
            logoImageView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 62),
            logoImageView.widthAnchor.constraint(equalToConstant: 100),
            logoImageView.heightAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    
    // MARK: - Login Form（参考图：手机号码 + 密码，底线分隔，密码右侧眼睛）
    private func setupLoginForm() {
        loginFormContainer = UIView()
        loginFormContainer.backgroundColor = .white
        loginFormContainer.alpha = 1.0
        contentView.addSubview(loginFormContainer)
        loginFormContainer.translatesAutoresizingMaskIntoConstraints = false
        
        loginAccountLabel.font = UIFont.systemFont(ofSize: 15)
        loginAccountLabel.textColor = Constants.Color.textPrimary
        loginFormContainer.addSubview(loginAccountLabel)
        loginAccountLabel.translatesAutoresizingMaskIntoConstraints = false
        
        loginAccountTextField.font = UIFont.systemFont(ofSize: 15)
        loginAccountTextField.textColor = Constants.Color.textPrimary
        loginAccountTextField.borderStyle = .none
        loginAccountTextField.clearButtonMode = .whileEditing
        loginFormContainer.addSubview(loginAccountTextField)
        loginAccountTextField.translatesAutoresizingMaskIntoConstraints = false
        
        let accountLine = UIView()
        accountLine.backgroundColor = Constants.Color.separator
        loginFormContainer.addSubview(accountLine)
        accountLine.translatesAutoresizingMaskIntoConstraints = false
        
        // 密码 + 眼睛按钮
        loginPasswordLabel.text = "密码"
        loginPasswordLabel.font = UIFont.systemFont(ofSize: 15)
        loginPasswordLabel.textColor = Constants.Color.textPrimary
        loginFormContainer.addSubview(loginPasswordLabel)
        loginPasswordLabel.translatesAutoresizingMaskIntoConstraints = false
        
        loginPasswordTextField.placeholder = "请输入登录密码"
        loginPasswordTextField.font = UIFont.systemFont(ofSize: 15)
        loginPasswordTextField.textColor = Constants.Color.textPrimary
        loginPasswordTextField.borderStyle = .none
        loginPasswordTextField.isSecureTextEntry = true
        loginPasswordTextField.clearButtonMode = .never
        loginFormContainer.addSubview(loginPasswordTextField)
        loginPasswordTextField.translatesAutoresizingMaskIntoConstraints = false
        
        passwordVisibilityButton.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        passwordVisibilityButton.setImage(UIImage(systemName: "eye"), for: .selected)
        passwordVisibilityButton.tintColor = Constants.Color.textTertiary
        passwordVisibilityButton.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
        loginFormContainer.addSubview(passwordVisibilityButton)
        passwordVisibilityButton.translatesAutoresizingMaskIntoConstraints = false
        
        let passwordLine = UIView()
        passwordLine.backgroundColor = Constants.Color.separator
        loginFormContainer.addSubview(passwordLine)
        passwordLine.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            loginFormContainer.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 55),
            loginFormContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            loginFormContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            loginAccountLabel.topAnchor.constraint(equalTo: loginFormContainer.topAnchor, constant: 16),
            loginAccountLabel.leadingAnchor.constraint(equalTo: loginFormContainer.leadingAnchor),
            loginAccountLabel.widthAnchor.constraint(equalToConstant: 72),
            
            loginAccountTextField.centerYAnchor.constraint(equalTo: loginAccountLabel.centerYAnchor),
            loginAccountTextField.leadingAnchor.constraint(equalTo: loginAccountLabel.trailingAnchor, constant: 16),
            loginAccountTextField.trailingAnchor.constraint(equalTo: loginFormContainer.trailingAnchor),
            
            accountLine.topAnchor.constraint(equalTo: loginAccountLabel.bottomAnchor, constant: 12),
            accountLine.leadingAnchor.constraint(equalTo: loginFormContainer.leadingAnchor),
            accountLine.trailingAnchor.constraint(equalTo: loginFormContainer.trailingAnchor),
            accountLine.heightAnchor.constraint(equalToConstant: 1),
            
            loginPasswordLabel.topAnchor.constraint(equalTo: accountLine.bottomAnchor, constant: 20),
            loginPasswordLabel.leadingAnchor.constraint(equalTo: loginFormContainer.leadingAnchor),
            loginPasswordLabel.widthAnchor.constraint(equalToConstant: 72),
            
            loginPasswordTextField.centerYAnchor.constraint(equalTo: loginPasswordLabel.centerYAnchor),
            loginPasswordTextField.leadingAnchor.constraint(equalTo: loginPasswordLabel.trailingAnchor, constant: 16),
            loginPasswordTextField.trailingAnchor.constraint(equalTo: passwordVisibilityButton.leadingAnchor, constant: -8),
            
            passwordVisibilityButton.centerYAnchor.constraint(equalTo: loginPasswordLabel.centerYAnchor),
            passwordVisibilityButton.trailingAnchor.constraint(equalTo: loginFormContainer.trailingAnchor),
            passwordVisibilityButton.widthAnchor.constraint(equalToConstant: 44),
            passwordVisibilityButton.heightAnchor.constraint(equalToConstant: 44),
            
            passwordLine.topAnchor.constraint(equalTo: loginPasswordLabel.bottomAnchor, constant: 12),
            passwordLine.leadingAnchor.constraint(equalTo: loginFormContainer.leadingAnchor),
            passwordLine.trailingAnchor.constraint(equalTo: loginFormContainer.trailingAnchor),
            passwordLine.heightAnchor.constraint(equalToConstant: 1),
            passwordLine.bottomAnchor.constraint(equalTo: loginFormContainer.bottomAnchor, constant: -16)
        ])
        updateAccountRowForMode()
    }
    
    private func updateAccountRowForMode() {
        if isPhoneLogin {
            loginAccountLabel.text = "手机号码"
            loginAccountTextField.placeholder = "请输入手机号码"
            loginAccountTextField.keyboardType = .phonePad
        } else {
            loginAccountLabel.text = "用户名"
            loginAccountTextField.placeholder = "请输入用户名"
            loginAccountTextField.keyboardType = .default
        }
    }
    
    @objc private func togglePasswordVisibility() {
        passwordVisibilityButton.isSelected.toggle()
        loginPasswordTextField.isSecureTextEntry = !passwordVisibilityButton.isSelected
    }
    
    // MARK: - Helper Methods
    // MARK: - Agreement
    private var agreementContainer: UIView!
    private var agreementTopConstraint: NSLayoutConstraint!
    
    private func setupAgreement() {
        agreementContainer = UIView()
        contentView.addSubview(agreementContainer)
        agreementContainer.translatesAutoresizingMaskIntoConstraints = false
        
        agreementCheckbox.setImage(UIImage(systemName: "square"), for: .normal)
        agreementCheckbox.setImage(UIImage(systemName: "checkmark.square.fill"), for: .selected)
        agreementCheckbox.tintColor = themeRed
        agreementCheckbox.addTarget(self, action: #selector(checkboxTapped), for: .touchUpInside)
        agreementContainer.addSubview(agreementCheckbox)
        agreementCheckbox.translatesAutoresizingMaskIntoConstraints = false
        
        // 设置协议文本（初始为登录状态）
        updateAgreementText()
        
        agreementLabel.font = UIFont.systemFont(ofSize: 12)
        agreementLabel.textColor = Constants.Color.textSecondary
        agreementLabel.numberOfLines = 0
        agreementLabel.isUserInteractionEnabled = true
        agreementContainer.addSubview(agreementLabel)
        agreementLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(agreementLabelTapped(_:)))
        agreementLabel.addGestureRecognizer(tapGesture)
        
        NSLayoutConstraint.activate([
            agreementContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            agreementContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            agreementCheckbox.leadingAnchor.constraint(equalTo: agreementContainer.leadingAnchor),
            agreementCheckbox.widthAnchor.constraint(equalToConstant: 24),
            agreementCheckbox.heightAnchor.constraint(equalToConstant: 24),
            
            agreementLabel.leadingAnchor.constraint(equalTo: agreementCheckbox.trailingAnchor, constant: 8),
            agreementLabel.trailingAnchor.constraint(equalTo: agreementContainer.trailingAnchor),
            agreementLabel.topAnchor.constraint(equalTo: agreementContainer.topAnchor),
            agreementLabel.bottomAnchor.constraint(equalTo: agreementContainer.bottomAnchor),
            
            // 复选框相对于协议文本垂直居中
            agreementCheckbox.centerYAnchor.constraint(equalTo: agreementLabel.centerYAnchor)
        ])
        
        // 初始约束：绑定到登录表单
        agreementTopConstraint = agreementContainer.topAnchor.constraint(equalTo: loginFormContainer.bottomAnchor, constant: 20)
        agreementTopConstraint.isActive = true
    }
    
    /// 更新协议文本（参考图：阅读并同意《用户协议》《隐私政策》）
    private func updateAgreementText() {
        let agreementText: String
        let link1 = "《用户协议》"
        let link2 = "《隐私政策》"
        
        agreementText = "阅读并同意" + link1 + link2
        
        agreementLabel.text = agreementText
        let attributedString = NSMutableAttributedString(string: agreementText)
        attributedString.addAttribute(.foregroundColor, value: Constants.Color.textPrimary, range: (agreementText as NSString).range(of: agreementText))
        
        let range1 = (agreementText as NSString).range(of: link1)
        if range1.location != NSNotFound {
            attributedString.addAttribute(.foregroundColor, value: Constants.Color.blue, range: range1)
            attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range1)
        }
        let range2 = (agreementText as NSString).range(of: link2)
        if range2.location != NSNotFound {
            attributedString.addAttribute(.foregroundColor, value: Constants.Color.blue, range: range2)
            attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range2)
        }
        agreementLabel.attributedText = attributedString
    }
    
    @objc private func checkboxTapped() {
        agreementCheckbox.isSelected.toggle()
    }
    
    @objc private func agreementLabelTapped(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: agreementLabel)
        let text = agreementLabel.text ?? ""
        let link1 = "《用户协议》"
        let link2 = "《隐私政策》"
        
        guard let attributedText = agreementLabel.attributedText else { return }
        
        let textStorage = NSTextStorage(attributedString: attributedText)
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        let textContainer = NSTextContainer(size: agreementLabel.bounds.size)
        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = agreementLabel.numberOfLines
        textContainer.lineBreakMode = agreementLabel.lineBreakMode
        layoutManager.addTextContainer(textContainer)
        
        let characterIndex = layoutManager.characterIndex(for: location, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        
        let range1 = (text as NSString).range(of: link1)
        let range2 = (text as NSString).range(of: link2)
        if NSLocationInRange(characterIndex, range1) {
            openAgreementInSafari(urlString: "https://www.htsc.com.cn/user-agreement")
        } else if NSLocationInRange(characterIndex, range2) {
            openAgreementInSafari(urlString: "https://www.htsc.com.cn/privacy")
        }
    }
    
    private func openAgreementInSafari(urlString: String) {
        guard let url = URL(string: urlString) else {
            Toast.showError("无法打开协议链接")
            return
        }
        let safariVC = SFSafariViewController(url: url)
        safariVC.preferredControlTintColor = themeRed
        present(safariVC, animated: true)
    }
    
    // MARK: - Login Button + 马上开户（参考图：红色填充登录 + 白底红边马上开户）
    private func setupLoginButton() {
        updateLoginButtonTitle()
        loginButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.backgroundColor = themeRed
        loginButton.layer.cornerRadius = 10
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        contentView.addSubview(loginButton)
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        
        openAccountButton.setTitle("马上开户", for: .normal)
        openAccountButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        openAccountButton.setTitleColor(themeRed, for: .normal)
        openAccountButton.backgroundColor = .white
        openAccountButton.layer.cornerRadius = 10
        openAccountButton.layer.borderWidth = 1
        openAccountButton.layer.borderColor = themeRed.cgColor
        openAccountButton.addTarget(self, action: #selector(openAccountTapped), for: .touchUpInside)
        contentView.addSubview(openAccountButton)
        openAccountButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            loginButton.topAnchor.constraint(equalTo: agreementContainer.bottomAnchor, constant: 28),
            loginButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            loginButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            loginButton.heightAnchor.constraint(equalToConstant: 50),
            
            openAccountButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 16),
            openAccountButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            openAccountButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            openAccountButton.heightAnchor.constraint(equalToConstant: 50),
            openAccountButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -48)
        ])
    }
    
    private func updateLoginButtonTitle() {
        loginButton.setTitle("登录", for: .normal)
    }
    
    @objc private func openAccountTapped() {
        let registerVC = RegisterViewController()
        let nav = UINavigationController(rootViewController: registerVC)
        nav.setNavigationBarHidden(true, animated: false)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    
    @objc private func loginButtonTapped() {
        guard agreementCheckbox.isSelected else {
            Toast.show("请先同意协议")
            return
        }
                // 用户名登录
                let account = (loginAccountTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let password = loginPasswordTextField.text ?? ""
                
                guard !account.isEmpty, !password.isEmpty else {
                    Toast.show("请输入账号和密码")
                    return
                }
                if isPhoneLogin {
                    if !isValidPhone(account) {
                        Toast.show("请输入正确的手机号")
                        return
                    }
                } else {
                    if !isValidUsername(account) {
                        Toast.show("用户名须为9位，且包含字母和数字（字母可大写）")
                        return
                    }
                }
                
                SecureNetworkManager.shared.request(
                    api: Api.login_api,
                    method: .post,
                    params: [
                        "account": account,
                        "password": password
                    ]
                ) { result in
                    switch result {
                    case .success(let res):
                        print("status =", res.statusCode)
                        print("raw =", res.raw)          // 原始响应
                        print("decrypted =", res.decrypted ?? "无法解密") // 解密后的明文（如果能解）
                        let dict = res.decrypted
                        print(dict)
                        if dict?["code"] as? NSNumber != 1 {

                            DispatchQueue.main.async {
                                Toast.showInfo(dict?["msg"] as? String ?? "")
                            }
                            return
                        }
                        let dataDict = (dict?["data"] as? [String: Any] ?? [:]) ["userinfo"] as? [String: Any] ?? [:]
                        
                        // 登录成功
                        UserAuthManager.shared.login(username: dataDict["nickname"] as? String ?? "", phone:  dataDict["username"] as? String ?? "")
                        UserAuthManager.shared.token = dataDict["token"] as? String ?? ""
                        UserAuthManager.shared.userID = String(format: "%@", dataDict["user_id"] as! CVarArg)
                        DispatchQueue.main.async {
                            Toast.showInfo("登录成功")
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.switchToMainApp()
                        }

                    case .failure(let error):
                        print("error =", error.localizedDescription)
                        Toast.showError(error.localizedDescription)
                    }
            }
    }
    
    /// 手机号格式：1 开头，第二位 3–9，共 11 位数字
    private func isValidPhone(_ s: String) -> Bool {
        let pattern = "^1[3-9]\\d{9}$"
        return s.range(of: pattern, options: .regularExpression) != nil
    }
    
    /// 用户名：9 位，强制包含字母（含大写）+ 数字
    private func isValidUsername(_ s: String) -> Bool {
        guard s.count == 9 else { return false }
        let letter = s.range(of: "[A-Za-z]", options: .regularExpression) != nil
        let digit = s.range(of: "\\d", options: .regularExpression) != nil
        let onlyAlnum = s.range(of: "^[A-Za-z0-9]+$", options: .regularExpression) != nil
        return letter && digit && onlyAlnum
    }
    
    /// 登录/注册成功后切换到主界面 TabBar（通过 SceneDelegate 的 window 切换，保证生效）
    private func switchToMainApp() {
        // 1. 通过当前 view 所在 scene 的 delegate 获取 SceneDelegate，用其 window 切换（最可靠）
        if let scene = view.window?.windowScene ?? (UIApplication.shared.connectedScenes.first as? UIWindowScene),
           let sceneDelegate = scene.delegate as? SceneDelegate {
            sceneDelegate.switchToTabBar()
            return
        }
        // 2. 兼容：直接用 connectedScenes 的 window 切换
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        let tabBarController = MainTabBarController()
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
            window.rootViewController = tabBarController
        }, completion: nil)
    }
}

