//
//  RegisterViewController.swift
//  zhengqaun
//
//  立即注册 / 开户页面
//

import UIKit
import SafariServices

class RegisterViewController: UIViewController {
    
    private let themeRed = UIColor(red: 230/255, green: 0, blue: 18/255, alpha: 1.0)
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // 状态栏+红色导航头（同色）
    private let statusBarView = UIView()
    private let navBarView = UIView()
    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    
    /// true = 手机号注册，false = 用户名注册；由外部在 present 前设置，界面不展示切换按钮
    var isPhoneRegistration: Bool = false {
        didSet { updateAccountRowForMode() }
    }
    
    // 白色卡片
    private let cardView = UIView()
    private let sloganImageView = UIImageView()
    
    private let accountIconView = UIImageView()
    private let accountField = UITextField()
    private let accountLine = UIView()
    private let passwordField = UITextField()
    private let passwordLine = UIView()
    private let passwordEyeButton = UIButton(type: .custom)
    private let payPasswordField = UITextField()
    private let payPasswordLine = UIView()
    private let payPasswordEyeButton = UIButton(type: .custom)
    private let orgCodeField = UITextField()
    private let orgCodeLine = UIView()
    
    private let submitButton = UIButton(type: .system)
    private let agreementCheckbox = UIButton(type: .custom)
    private let agreementLabel = UILabel()
    
    // 底部准备图
    private let zhunbeiImageView = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Constants.Color.backgroundMain
        setupNavBar()
        setupScroll()
        setupCard()
        setupBottomImage()
    }
    
    private func setupNavBar() {
        statusBarView.backgroundColor = themeRed
        view.addSubview(statusBarView)
        statusBarView.translatesAutoresizingMaskIntoConstraints = false
        
        navBarView.backgroundColor = themeRed
        view.addSubview(navBarView)
        navBarView.translatesAutoresizingMaskIntoConstraints = false
        
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .white
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        navBarView.addSubview(backButton)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.text = "立即注册"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        navBarView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            statusBarView.topAnchor.constraint(equalTo: view.topAnchor),
            statusBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statusBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            statusBarView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navBarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navBarView.heightAnchor.constraint(equalToConstant: 56),
            backButton.leadingAnchor.constraint(equalTo: navBarView.leadingAnchor, constant: 16),
            backButton.centerYAnchor.constraint(equalTo: navBarView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            titleLabel.centerXAnchor.constraint(equalTo: navBarView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: navBarView.centerYAnchor)
        ])
    }
    
    @objc private func backTapped() {
        dismiss(animated: true)
    }
    
    private func setupScroll() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .clear
        scrollView.showsVerticalScrollIndicator = false
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: navBarView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func setupCard() {
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 12
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 8
        cardView.layer.shadowOpacity = 0.08
        contentView.addSubview(cardView)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        
        // 标语图（slogan 230*62，居中）
        sloganImageView.image = UIImage(named: "slogan")
        sloganImageView.contentMode = .scaleAspectFit
        sloganImageView.clipsToBounds = true
        cardView.addSubview(sloganImageView)
        sloganImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // 第一行：账号（手机号或用户名），icon/placeholder 由 isPhoneRegistration + updateAccountRowForMode 设置
        accountIconView.tintColor = Constants.Color.textTertiary
        accountIconView.contentMode = .scaleAspectFit
        cardView.addSubview(accountIconView)
        accountIconView.translatesAutoresizingMaskIntoConstraints = false
        accountField.font = UIFont.systemFont(ofSize: 15)
        accountField.textColor = Constants.Color.textPrimary
        accountField.borderStyle = .none
        accountField.isSecureTextEntry = false
        accountField.clearButtonMode = .whileEditing
        cardView.addSubview(accountField)
        accountField.translatesAutoresizingMaskIntoConstraints = false
        accountLine.backgroundColor = Constants.Color.separator
        cardView.addSubview(accountLine)
        accountLine.translatesAutoresizingMaskIntoConstraints = false
        updateAccountRowForMode()
        
        // 请输入密码、支付密码、机构码
        addInputRow(container: cardView, field: passwordField, line: passwordLine, icon: "lock", placeholder: "请输入密码", isSecure: true, rightButton: passwordEyeButton)
        addInputRow(container: cardView, field: payPasswordField, line: payPasswordLine, icon: "creditcard", placeholder: "支付密码", isSecure: true, rightButton: payPasswordEyeButton)
        addInputRow(container: cardView, field: orgCodeField, line: orgCodeLine, icon: "building.2", placeholder: "机构码", isSecure: false, rightButton: nil)
        
        passwordEyeButton.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        passwordEyeButton.setImage(UIImage(systemName: "eye"), for: .selected)
        passwordEyeButton.tintColor = Constants.Color.textTertiary
        passwordEyeButton.addTarget(self, action: #selector(togglePassword1), for: .touchUpInside)
        
        payPasswordEyeButton.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        payPasswordEyeButton.setImage(UIImage(systemName: "eye"), for: .selected)
        payPasswordEyeButton.tintColor = Constants.Color.textTertiary
        payPasswordEyeButton.addTarget(self, action: #selector(togglePayPassword), for: .touchUpInside)
        
        // 极速开户按钮
        submitButton.setTitle("极速开户", for: .normal)
        submitButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.backgroundColor = themeRed
        submitButton.layer.cornerRadius = 10
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        cardView.addSubview(submitButton)
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 协议
        agreementCheckbox.setImage(UIImage(systemName: "square"), for: .normal)
        agreementCheckbox.setImage(UIImage(systemName: "checkmark.square.fill"), for: .selected)
        agreementCheckbox.tintColor = themeRed
        agreementCheckbox.addTarget(self, action: #selector(checkboxTapped), for: .touchUpInside)
        cardView.addSubview(agreementCheckbox)
        agreementCheckbox.translatesAutoresizingMaskIntoConstraints = false
        
        agreementLabel.text = "我同意签署《用户协议》《隐私政策》"
        agreementLabel.font = UIFont.systemFont(ofSize: 12)
        agreementLabel.textColor = Constants.Color.textTertiary
        agreementLabel.numberOfLines = 0
        agreementLabel.isUserInteractionEnabled = true
        cardView.addSubview(agreementLabel)
        agreementLabel.translatesAutoresizingMaskIntoConstraints = false
        let tap = UITapGestureRecognizer(target: self, action: #selector(agreementTapped(_:)))
        agreementLabel.addGestureRecognizer(tap)
        
        layoutCardContent()
    }
    
    private func updateAccountRowForMode() {
        if isPhoneRegistration {
            accountIconView.image = UIImage(systemName: "phone")
            accountField.setZqPlaceholder("请输入手机号")
            accountField.keyboardType = .phonePad
        } else {
            accountIconView.image = UIImage(systemName: "person.crop.circle")
            accountField.setZqPlaceholder("请输入用户名")
            accountField.keyboardType = .default
        }
    }
    
    private func addInputRow(container: UIView, field: UITextField, line: UIView, icon: String, placeholder: String, isSecure: Bool, rightButton: UIButton?) {
        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = Constants.Color.textTertiary
        iconView.contentMode = .scaleAspectFit
        container.addSubview(iconView)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        field.setZqPlaceholder(placeholder)
        field.font = UIFont.systemFont(ofSize: 15)
        field.textColor = Constants.Color.textPrimary
        field.borderStyle = .none
        field.isSecureTextEntry = isSecure
        field.clearButtonMode = .whileEditing
        container.addSubview(field)
        field.translatesAutoresizingMaskIntoConstraints = false
        
        line.backgroundColor = Constants.Color.separator
        container.addSubview(line)
        line.translatesAutoresizingMaskIntoConstraints = false
        
        if let btn = rightButton {
            container.addSubview(btn)
            btn.translatesAutoresizingMaskIntoConstraints = false
        }
        
        // 约束在 layoutCardContent 里按顺序统一做
    }
    
    private var cardLayoutDone = false
    
    private func layoutCardContent() {
        guard !cardLayoutDone else { return }
        cardLayoutDone = true
        let allIcons = cardView.subviews.compactMap { $0 as? UIImageView }
        let icons = Array(allIcons.dropFirst()) // 第一个是 slogan，后 4 个为 accountIcon + 三行 icon
        guard icons.count >= 4 else { return }
        
        let cardMargins: CGFloat = 20
        let rowHeight: CGFloat = 44
        let lineH: CGFloat = 1
        let rowSpacing: CGFloat = 20
        let fields = [accountField, passwordField, payPasswordField, orgCodeField]
        let lines = [accountLine, passwordLine, payPasswordLine, orgCodeLine]
        
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            sloganImageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 24),
            sloganImageView.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            sloganImageView.widthAnchor.constraint(equalToConstant: 230),
            sloganImageView.heightAnchor.constraint(equalToConstant: 62)
        ])
        var lastAnchor: NSLayoutYAxisAnchor = sloganImageView.bottomAnchor
        
        for i in 0..<4 {
            let iconView = icons[i]
            let field = fields[i]
            let line = lines[i]
            var constraints: [NSLayoutConstraint] = [
                iconView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: cardMargins),
                iconView.centerYAnchor.constraint(equalTo: field.centerYAnchor),
                iconView.widthAnchor.constraint(equalToConstant: 22),
                iconView.heightAnchor.constraint(equalToConstant: 22),
                field.topAnchor.constraint(equalTo: lastAnchor, constant: i == 0 ? 24 : rowSpacing),
                field.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
                field.heightAnchor.constraint(equalToConstant: rowHeight),
                line.topAnchor.constraint(equalTo: field.bottomAnchor),
                line.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: cardMargins),
                line.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -cardMargins),
                line.heightAnchor.constraint(equalToConstant: lineH)
            ]
            if i == 1 {
                constraints.append(contentsOf: [
                    passwordEyeButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -cardMargins),
                    passwordEyeButton.centerYAnchor.constraint(equalTo: passwordField.centerYAnchor),
                    passwordEyeButton.widthAnchor.constraint(equalToConstant: 44),
                    field.trailingAnchor.constraint(equalTo: passwordEyeButton.leadingAnchor, constant: -8)
                ])
            } else if i == 2 {
                constraints.append(contentsOf: [
                    payPasswordEyeButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -cardMargins),
                    payPasswordEyeButton.centerYAnchor.constraint(equalTo: payPasswordField.centerYAnchor),
                    payPasswordEyeButton.widthAnchor.constraint(equalToConstant: 44),
                    field.trailingAnchor.constraint(equalTo: payPasswordEyeButton.leadingAnchor, constant: -8)
                ])
            } else {
                constraints.append(field.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -cardMargins))
            }
            NSLayoutConstraint.activate(constraints)
            lastAnchor = line.bottomAnchor
        }
        
        NSLayoutConstraint.activate([
            submitButton.topAnchor.constraint(equalTo: lastAnchor, constant: 28),
            submitButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: cardMargins),
            submitButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -cardMargins),
            submitButton.heightAnchor.constraint(equalToConstant: 50),
            
            agreementCheckbox.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: cardMargins),
            agreementCheckbox.centerYAnchor.constraint(equalTo: agreementLabel.centerYAnchor),
            agreementCheckbox.widthAnchor.constraint(equalToConstant: 22),
            agreementCheckbox.heightAnchor.constraint(equalToConstant: 22),
            agreementLabel.leadingAnchor.constraint(equalTo: agreementCheckbox.trailingAnchor, constant: 8),
            agreementLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -cardMargins),
            agreementLabel.topAnchor.constraint(equalTo: submitButton.bottomAnchor, constant: 16),
            agreementLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20)
        ])
    }
    
    @objc private func togglePassword1() {
        passwordEyeButton.isSelected.toggle()
        passwordField.isSecureTextEntry = !passwordEyeButton.isSelected
    }
    
    @objc private func togglePayPassword() {
        payPasswordEyeButton.isSelected.toggle()
        payPasswordField.isSecureTextEntry = !payPasswordEyeButton.isSelected
    }
    
    @objc private func checkboxTapped() {
        agreementCheckbox.isSelected.toggle()
    }
    
    @objc private func agreementTapped(_ g: UITapGestureRecognizer) {
        openAgreement(url: "https://www.htsc.com.cn/user-agreement")
    }
    
    private func openAgreement(url: String) {
        guard let u = URL(string: url) else { return }
        let vc = SFSafariViewController(url: u)
        vc.preferredControlTintColor = themeRed
        present(vc, animated: true)
    }
    
    @objc private func submitTapped() {
        guard agreementCheckbox.isSelected else {
            Toast.show("请先同意用户协议和隐私政策")
            return
        }
        let account = (accountField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let pwd = passwordField.text ?? ""
        let payPwd = payPasswordField.text ?? ""
        let orgCode = orgCodeField.text ?? ""
        guard !account.isEmpty, !pwd.isEmpty, !payPwd.isEmpty, !orgCode.isEmpty else {
            Toast.show("请填写完整信息")
            return
        }
        if isPhoneRegistration {
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
            api: Api.create_account_api,
            method: .post,
            params: [
                "mobile": account,
                "password": pwd,
                "payment_code":payPwd,
                "institution_number":orgCode
            ]
        ) { result in
            switch result {
            case .success(let res):
                print("status =", res.statusCode)
                print("raw =", res.raw)          // 原始响应
                print("decrypted =", res.decrypted ?? "无法解密") // 解密后的明文（如果能解）
                let dict = res.decrypted as? NSDictionary
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
                    Toast.showInfo("注册成功")
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
    
    private func setupBottomImage() {
        zhunbeiImageView.image = UIImage(named: "zhunbei")
        zhunbeiImageView.contentMode = .scaleAspectFit
        zhunbeiImageView.clipsToBounds = true
        contentView.addSubview(zhunbeiImageView)
        zhunbeiImageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            zhunbeiImageView.topAnchor.constraint(equalTo: cardView.bottomAnchor, constant: 32),
            zhunbeiImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            zhunbeiImageView.widthAnchor.constraint(equalToConstant: 267),
            zhunbeiImageView.heightAnchor.constraint(equalToConstant: 78),
            zhunbeiImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])
    }
    
    // MARK: - Helper
    
}
